#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# staged-packages.sh - Map the staged changeset to the APM packages it affects
#
# Usage:
#   ./scripts/staged-packages.sh        # print affected package names, one per line
#
# Operates on the git repository containing the current working directory. The
# set of packages is derived from the git index and the staged path list only,
# never from the working tree. stdout carries the package names and nothing
# else; stderr carries diagnostics.
#
# Exit codes:
#   0  success, with or without output
#   2  the current working directory is not inside a git repository, or the
#      repository could not be read
# ---------------------------------------------------------------------------

REPO_ROOT=""
if ! REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"; then
  printf 'staged-packages.sh: not inside a git repository\n' >&2
  exit 2
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

# The staged path list. --no-renames is load-bearing: with rename detection
# on, git reports only the destination of a rename, so a manifest renamed away
# would never reach the package test below. core.quotePath=false keeps paths
# with non-ASCII bytes readable instead of C-quoted.
if ! git -C "$REPO_ROOT" -c core.quotePath=false diff --cached --name-only --no-renames \
      > "$TMP_DIR/staged"; then
  printf 'staged-packages.sh: could not read the staged changes\n' >&2
  exit 2
fi

# The package manifests currently in the index. The pathspec matches at every
# depth, so only the entries with exactly one slash - the top-level packages -
# are kept.
if ! git -C "$REPO_ROOT" -c core.quotePath=false ls-files --cached -- '*/apm.yml' \
      > "$TMP_DIR/manifests"; then
  printf 'staged-packages.sh: could not read the index\n' >&2
  exit 2
fi
awk -F/ 'NF == 2' "$TMP_DIR/manifests" > "$TMP_DIR/packages"

# The top-level directory of every staged path. A path without a slash is a
# top-level file and is never package-shaped.
while IFS= read -r path || [ -n "${path:-}" ]; do
  case "$path" in
    */*) printf '%s\n' "${path%%/*}" ;;
  esac
done < "$TMP_DIR/staged" | LC_ALL=C sort -u > "$TMP_DIR/segments"

# A segment names a package when its manifest is in the index, or when the
# manifest itself is staged - the second condition is what makes a staged
# deletion, or a rename away from the manifest, package-affecting.
while IFS= read -r segment || [ -n "${segment:-}" ]; do
  [ -n "$segment" ] || continue
  case "$segment" in
    examples|wrappers|scripts|docs|.git) continue ;;
  esac
  if grep -Fxq -- "$segment/apm.yml" "$TMP_DIR/packages" \
     || grep -Fxq -- "$segment/apm.yml" "$TMP_DIR/staged"; then
    printf '%s\n' "$segment"
  fi
done < "$TMP_DIR/segments"

exit 0
