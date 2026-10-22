#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# check-lockfile-in-sync.sh - Verify the root lockfile covers every dependency
# the root manifest declares.
#
# Usage:
#   ./scripts/check-lockfile-in-sync.sh
#
# `apm audit --ci` would be the obvious tool, but in this repository it fails
# on an unrelated conflict: the ralph-loop plugin installs hooks for both
# Claude and Cursor, and apm refuses to install both routes. The lockfile
# consistency it also checks is reproduced here, directly.
#
# This is the invariant that matters for the lockfile: a dependency declared
# in apm.yml must have an entry in apm.lock.yaml. A dependency that was added
# to the manifest and never locked is how the lock silently stops describing
# what the project depends on.
#
# This is deliberately NOT the same check as "upstream has moved since the
# lock was written". A lockfile is supposed to pin versions, and the
# repositories this project draws from publish new commits constantly, so
# failing on that would make the daily sweep red every day without anything
# being wrong. Upstream movement is reported by the daily sweep; a manifest
# and a lockfile that disagree is a failure.
#
# Exit codes:
#   0  every declared dependency has a lockfile entry
#   1  a declared dependency has no lockfile entry
#   2  the manifest or the lockfile could not be read
# ---------------------------------------------------------------------------

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

python3 - <<'PY'
import sys
try:
    import yaml
except ImportError:
    print("ERROR: pyyaml is not installed (pip install pyyaml).", file=sys.stderr)
    sys.exit(2)

try:
    manifest = yaml.safe_load(open("apm.yml"))
    lock = yaml.safe_load(open("apm.lock.yaml"))
except Exception as exc:
    print(f"ERROR: could not read apm.yml or apm.lock.yaml: {exc}", file=sys.stderr)
    sys.exit(2)

declared = (manifest.get("dependencies") or {}).get("apm") or []
declared += (manifest.get("dependencies") or {}).get("mcp") or []

locked = set()
for entry in lock.get("dependencies") or []:
    url = entry.get("repo_url")
    if url:
        locked.add(url)


def lock_key(dependency):
    """The lockfile's repo_url for a declared dependency.

    A local path dependency (./user-core) is locked as _local/user-core.
    A remote dependency is locked by its repository, so the path inside the
    repository is dropped: github/awesome-copilot/plugins/x is locked as
    github/awesome-copilot.
    """
    if dependency.startswith("./"):
        return "_local/" + dependency[2:].rstrip("/")
    parts = dependency.split("/")
    return "/".join(parts[:2]) if len(parts) >= 2 else dependency


missing = [d for d in declared if lock_key(d) not in locked]

if missing:
    print("apm.lock.yaml does not cover every dependency declared in apm.yml:")
    for dependency in missing:
        print(f"  {dependency} -> expected a lockfile entry for {lock_key(dependency)}")
    print("")
    print("Fix: run 'apm lock --update' and commit the refreshed apm.lock.yaml.")
    sys.exit(1)

print(f"apm.lock.yaml covers all {len(declared)} declared dependenc(ies).")
sys.exit(0)
PY
