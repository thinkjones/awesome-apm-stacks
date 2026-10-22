#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# check-deps-resolvable.sh - Prove a package's declared dependencies still
# resolve upstream.
#
# Usage:
#   ./scripts/check-deps-resolvable.sh code-python
#   ./scripts/check-deps-resolvable.sh --ci code-python code-go
#
# Why this exists instead of `apm install --dry-run`:
#
#   `apm install --dry-run` prints what *would* be installed and exits 0
#   without contacting upstream. A package whose only dependency is
#   `github/awesome-copilot/plugins/this-path-does-not-exist-xyz` passes it.
#   Verified against apm 0.34.0, the version CI installs.
#
#   `apm lock` resolves for real and deploys nothing, so it is the closest
#   thing to a pure resolvability check. It writes apm.lock.yaml into the
#   current directory, so each package is resolved in a throwaway directory
#   holding a copy of its manifest.
#
# Two kinds of failure come back from `apm lock`, and they mean different
# things:
#
#   * The dependency no longer resolves upstream (the subdirectory or the
#     repository is gone). The package cannot be installed by a consumer.
#     This is a FAIL.
#
#   * The dependency resolves, but the package is an "Agent Plugin v1.0.0"
#     that installs natively only for the `copilot` target, so no selected
#     target receives it. The dependency is fine; the target coverage is not.
#     This is a WARNING - the package still installs, it just carries less
#     for consumers who are not on Copilot.
#
# Exit codes:
#   0  every dependency resolved (a target-coverage warning may have printed)
#   1  a dependency no longer resolves upstream
#   2  the resolver could not run at all
# ---------------------------------------------------------------------------

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

# The oldest APM CLI whose `apm lock` fails when a dependency does not exist
# upstream. Before this version the resolver silently dropped the dependency
# and wrote a lockfile without it, so the check would pass a package that no
# consumer can install. The check refuses to run on an older CLI rather than
# reporting a green it cannot back up.
MIN_APM_VERSION="0.29.1"

PACKAGES=()

for arg in "$@"; do
  case "$arg" in
    --ci) ;; # accepted for symmetry with the other scripts; this one has no colours
    *)    PACKAGES+=("$arg") ;;
  esac
done

if [ ${#PACKAGES[@]} -eq 0 ]; then
  printf 'ERROR: check-deps-resolvable.sh needs at least one package name.\n' >&2
  exit 2
fi

if ! command -v apm >/dev/null 2>&1; then
  printf 'ERROR: apm CLI not found - cannot resolve dependencies.\n' >&2
  printf 'Install with: curl -sSL https://aka.ms/apm-unix | sh\n' >&2
  exit 2
fi

# version_lt A B - true when A is older than B
version_lt() {
  awk -v a="$1" -v b="$2" 'BEGIN {
    split(a, x, "."); split(b, y, ".");
    for (i = 1; i <= 3; i++) {
      if ((x[i] + 0) < (y[i] + 0)) exit 0
      if ((x[i] + 0) > (y[i] + 0)) exit 1
    }
    exit 1
  }'
}

apm_version="$(apm --version 2>&1 | grep -oE 'CLI version [0-9]+\.[0-9]+\.[0-9]+' | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')"

if [ -z "$apm_version" ]; then
  printf 'ERROR: could not determine the apm CLI version.\n' >&2
  exit 2
fi

if version_lt "$apm_version" "$MIN_APM_VERSION"; then
  printf 'ERROR: apm CLI %s is too old to resolve dependencies reliably.\n' "$apm_version" >&2
  printf 'Version %s is the first that fails when a dependency no longer exists upstream.\n' "$MIN_APM_VERSION" >&2
  printf 'On an older CLI the resolver drops the dependency silently, so this check would pass a package no consumer can install.\n' >&2
  printf 'Update with: apm update\n' >&2
  exit 2
fi

# `apm lock` writes apm.lock.yaml into the current directory, so every
# package is resolved in its own throwaway directory. The apm cache lives
# under the user's cache directory, so the upstream clones are shared across
# the packages in a run.
WORKROOT="$(mktemp -d)"
cleanup() { rm -rf "$WORKROOT"; }
trap cleanup EXIT

RESOLVE_FAILURES=0
TARGET_WARNINGS=0

for pkg in "${PACKAGES[@]}"; do
  manifest="$REPO_ROOT/$pkg/apm.yml"
  if [ ! -f "$manifest" ]; then
    printf "  ERROR: package '%s' has no apm.yml\n" "$pkg" >&2
    RESOLVE_FAILURES=$((RESOLVE_FAILURES + 1))
    continue
  fi

  workdir="$WORKROOT/$pkg"
  mkdir -p "$workdir/.apm"

  # A dependency on this repository resolves from the published default
  # branch, so a pull request that fixes one of those packages would be
  # checked against the unfixed version on main. Repoint those dependencies
  # at the working tree, so the check resolves what the pull request
  # actually contains.
  {
    while IFS= read -r line; do
      case "$line" in
        *thinkjones/awesome-apm-stacks/*)
          prefix="${line%%thinkjones/awesome-apm-stacks/*}"
          rest="${line#*thinkjones/awesome-apm-stacks/}"
          if [ -f "$REPO_ROOT/$rest/apm.yml" ]; then
            printf '%s%s\n' "$prefix" "$REPO_ROOT/$rest"
            continue
          fi
          ;;
      esac
      printf '%s\n' "$line"
    done < "$manifest"
  } > "$workdir/apm.yml"

  output="$(cd "$workdir" && apm lock 2>&1)" && lock_status=0 || lock_status=$?

  # A dependency that no longer resolves upstream. The messages come from
  # apm's download and resolution failures.
  if printf '%s\n' "$output" | grep -qE "Failed to (download|resolve transitive)|Repository not found|File not found:|Subdirectory '"; then
    printf "  Dependency resolve:    FAIL\n"
    printf '%s\n' "$output" | grep -E "Failed to (download|resolve transitive)|Repository not found|File not found:|Subdirectory '" | while IFS= read -r line; do
      printf '    %s\n' "$line"
    done
    RESOLVE_FAILURES=$((RESOLVE_FAILURES + 1))
    continue
  fi

  # The dependency resolved but no selected target can receive it. `apm lock`
  # exits non-zero for this too, so the message is what separates it from a
  # genuine failure.
  if [ "$lock_status" -ne 0 ] && printf '%s\n' "$output" | grep -q 'Agent Plugins v1.0.0'; then
    printf "  Dependency resolve:    OK (with target-coverage warnings)\n"
    printf '%s\n' "$output" | grep 'Agent Plugins v1.0.0' | while IFS= read -r line; do
      printf '    %s\n' "$line"
    done
    TARGET_WARNINGS=$((TARGET_WARNINGS + 1))
    continue
  fi

  # The resolver failed without saying why. That is not a pass: the
  # dependencies were never proven to resolve.
  if [ "$lock_status" -ne 0 ]; then
    printf "  Dependency resolve:    FAIL\n"
    printf '    apm lock exited %s without a recognised diagnostic.\n' "$lock_status"
    printf '%s\n' "$output" | tail -5 | while IFS= read -r line; do
      printf '    %s\n' "$line"
    done
    RESOLVE_FAILURES=$((RESOLVE_FAILURES + 1))
    continue
  fi

  printf "  Dependency resolve:    OK\n"
done

if [ "$TARGET_WARNINGS" -gt 0 ]; then
  printf '  Note: %s package(s) resolved, but carry dependencies that only deploy for the copilot target.\n' "$TARGET_WARNINGS"
fi

if [ "$RESOLVE_FAILURES" -gt 0 ]; then
  exit 1
fi

exit 0
