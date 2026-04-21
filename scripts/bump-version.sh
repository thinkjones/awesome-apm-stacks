#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# bump-version.sh — bump the `version:` field in a package's apm.yml
#
# Usage:
#   ./scripts/bump-version.sh <package> <patch|minor|major>
#
# Examples:
#   ./scripts/bump-version.sh ai-agents patch      # 0.1.3 -> 0.1.4
#   ./scripts/bump-version.sh code-python minor    # 0.1.3 -> 0.2.0
#   ./scripts/bump-version.sh architect-cloud major # 0.1.3 -> 1.0.0
#
# The script is portable between GNU and BSD userlands (macOS + Linux).
# ---------------------------------------------------------------------------

if [ "$#" -ne 2 ]; then
  echo "usage: $0 <package> <patch|minor|major>" >&2
  exit 64
fi

pkg="$1"
kind="$2"

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
manifest="${repo_root}/${pkg}/apm.yml"

if [ ! -f "$manifest" ]; then
  echo "error: manifest not found at ${manifest}" >&2
  exit 1
fi

current="$(awk '/^version:/ {print $2; exit}' "$manifest")"

if [ -z "$current" ]; then
  echo "error: no 'version:' field found in ${manifest}" >&2
  exit 1
fi

if ! printf '%s' "$current" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$'; then
  echo "error: current version '${current}' is not semver X.Y.Z" >&2
  exit 1
fi

IFS='.' read -r major minor patch <<<"$current"

case "$kind" in
  patch) new="${major}.${minor}.$((patch + 1))" ;;
  minor) new="${major}.$((minor + 1)).0" ;;
  major) new="$((major + 1)).0.0" ;;
  *)
    echo "error: bump type must be patch|minor|major (got '${kind}')" >&2
    exit 64
    ;;
esac

tmp="$(mktemp "${manifest}.XXXXXX")"
trap 'rm -f "$tmp"' EXIT

awk -v new="$new" '
  !done && /^version:/ { print "version: " new; done=1; next }
  { print }
' "$manifest" >"$tmp"

mv "$tmp" "$manifest"
trap - EXIT

echo "${pkg}: ${current} -> ${new}"
