#!/usr/bin/env python3
"""Generate apm.yml manifests from wrapper.yml definitions.

For each wrappers/*/wrapper.yml, shallow-clones the upstream repo,
discovers skill folders via a glob pattern, applies excludes, and
emits a generated apm.yml with one dependency line per discovered folder.
"""

import glob
import os
import subprocess
import sys
import tempfile
from pathlib import Path

import yaml

REPO_ROOT = Path(__file__).resolve().parent.parent
WRAPPERS_DIR = REPO_ROOT / "wrappers"
GENERATED_HEADER = (
    "# ──────────────────────────────────────────────────────\n"
    "# GENERATED — do not edit by hand.\n"
    "# Re-generate with:  python scripts/generate-wrappers.py\n"
    "# ──────────────────────────────────────────────────────\n"
)


def shallow_clone(upstream: str, branch: str, dest: str) -> str:
    """Shallow-clone *upstream* into *dest* and return the HEAD SHA."""
    url = f"https://github.com/{upstream}.git"
    cmd = ["git", "clone", "--depth=1"]
    if branch:
        cmd.append(f"--branch={branch}")
    cmd.extend([url, dest])
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        raise RuntimeError(f"git clone failed for {upstream}: {result.stderr.strip()}")
    result = subprocess.run(
        ["git", "-C", dest, "rev-parse", "--short=7", "HEAD"],
        check=True,
        capture_output=True,
        text=True,
    )
    return result.stdout.strip()


def discover_folders(clone_dir: str, pattern: str, excludes: list[str]) -> list[str]:
    """Glob for *pattern* inside *clone_dir* and return sorted folder names.

    Extracts the parent directory of each match, then takes just the
    last component as the folder name. E.g. pattern ``skills/*/SKILL.md``
    matching ``skills/tdd/SKILL.md`` yields folder name ``tdd``.
    """
    matches = glob.glob(os.path.join(clone_dir, pattern))
    folders = []
    for match in matches:
        parent = os.path.dirname(match)
        folder = os.path.basename(parent)
        if folder not in excludes and not folder.startswith("."):
            folders.append(folder)
    return sorted(set(folders))


def build_apm_yml(wrapper: dict, name: str, folders: list[str], sha: str) -> str:
    """Return the generated apm.yml content as a string."""
    version = f"1.0.0-{sha}"
    upstream = wrapper["upstream"]
    prefix = wrapper.get("prefix", upstream)
    count = len(folders)

    tpl = wrapper.get("description_template", "Auto-wrapped {count} skills from {upstream} ({version}).")
    description = tpl.format(count=count, upstream=upstream, version=version)

    lines = [GENERATED_HEADER]
    lines.append(f"name: {name}")
    lines.append(f"version: {version}")
    lines.append(f"description: >")
    lines.append(f"  {description.strip()}")
    lines.append("")
    lines.append("dependencies:")
    lines.append("  apm:")

    for folder in folders:
        lines.append(f"    - {prefix}/{folder}")

    lines.append("")
    return "\n".join(lines)


def process_wrapper(wrapper_path: Path) -> None:
    """Process a single wrapper.yml and write the generated apm.yml."""
    with open(wrapper_path) as f:
        wrapper = yaml.safe_load(f)

    upstream = wrapper["upstream"]
    branch = wrapper.get("branch") or wrapper.get("ref") or ""
    pattern = wrapper["pattern"]
    excludes = wrapper.get("excludes") or wrapper.get("exclude") or []

    # Support nested package.name or top-level name
    pkg = wrapper.get("package", {})
    name = wrapper.get("name") or pkg.get("name")
    if not name:
        raise KeyError(f"wrapper.yml must define 'name' or 'package.name'")

    print(f"Processing {name} ({upstream})...")

    with tempfile.TemporaryDirectory() as tmp:
        sha = shallow_clone(upstream, branch, tmp)
        folders = discover_folders(tmp, pattern, excludes)

    if not folders:
        print(f"  ⚠ No folders matched pattern '{pattern}' — skipping.")
        return

    content = build_apm_yml(wrapper, name, folders, sha)
    out_path = wrapper_path.parent / "apm.yml"
    out_path.write_text(content)
    print(f"  ✓ Wrote {out_path.relative_to(REPO_ROOT)} ({len(folders)} skills)")


def main() -> None:
    if not WRAPPERS_DIR.is_dir():
        sys.exit(f"Error: {WRAPPERS_DIR} not found.")

    wrapper_files = sorted(
        p for p in WRAPPERS_DIR.glob("**/wrapper.yml")
        if "scripts" not in p.relative_to(WRAPPERS_DIR).parts
    )
    if not wrapper_files:
        sys.exit("Error: no wrapper.yml files found in wrappers/.")

    for wrapper_path in wrapper_files:
        process_wrapper(wrapper_path)

    print("Done.")


if __name__ == "__main__":
    main()
