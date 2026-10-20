#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# pre-commit-validate.sh - Refuse a commit whose staged packages are invalid
#
# Usage:
#   ./scripts/pre-commit-validate.sh
#
# Maps the staged changeset to the affected APM packages and hands exactly
# those package names to the unmodified ./scripts/test-packages.sh. The
# validator's output is inherited rather than captured, so the failing file
# path and the failing rule both reach the contributor untruncated.
#
# When the apm CLI is not on PATH the validator runs without --ci: the YAML
# syntax and the subpath layout checks still refuse the commit, and only the
# "apm install --dry-run" check is skipped. The CI check remains the
# authority on that one.
#
# Exit codes:
#   0  nothing package-shaped was staged, or the validator passed
#   1  the validator ran and a package failed
#   2  the mapper failed
# ---------------------------------------------------------------------------

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

PACKAGES=""
if PACKAGES="$(scripts/staged-packages.sh)"; then
  :
else
  mapper_exit=$?
  exit "$mapper_exit"
fi

# Nothing package-shaped is staged: no validator work at all, no output.
if [ -z "$PACKAGES" ]; then
  exit 0
fi

PACKAGE_ARGS=()
while IFS= read -r package || [ -n "${package:-}" ]; do
  [ -n "$package" ] || continue
  PACKAGE_ARGS+=("$package")
done <<< "$PACKAGES"

if command -v apm >/dev/null 2>&1; then
  FLAG="--ci"
else
  FLAG=""
  printf '%s\n' \
    'apm CLI not found — running the offline checks only (YAML syntax, subpath layout).' \
    'The "apm install --dry-run" check is skipped. Install the apm CLI to enable it:' \
    '  curl -sSL https://aka.ms/apm-unix | sh' >&2
fi

if [ -n "$FLAG" ]; then
  exec ./scripts/test-packages.sh "$FLAG" "${PACKAGE_ARGS[@]}"
fi

exec ./scripts/test-packages.sh "${PACKAGE_ARGS[@]}"
