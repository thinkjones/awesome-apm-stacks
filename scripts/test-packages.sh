#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# test-packages.sh - Validate every apm.yml package in the repo
#
# Usage:
#   ./scripts/test-packages.sh                          # test all packages, interactive
#   ./scripts/test-packages.sh --ci                     # test all packages, CI mode
#   ./scripts/test-packages.sh code-python code-go      # test specific packages
#   ./scripts/test-packages.sh --ci code-python code-go # test specific packages, CI mode
# ---------------------------------------------------------------------------

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# ── Colour setup (disabled when stdout is not a terminal) ─────────────────
if [[ -t 1 ]]; then
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[0;33m'
  CYAN='\033[0;36m'
  BOLD='\033[1m'
  RESET='\033[0m'
else
  RED=''
  GREEN=''
  YELLOW=''
  CYAN=''
  BOLD=''
  RESET=''
fi

# ── Parse flags ───────────────────────────────────────────────────────────
CI_MODE=false
REQUESTED_PACKAGES=()

for arg in "$@"; do
  case "$arg" in
    --ci) CI_MODE=true ;;
    *)    REQUESTED_PACKAGES+=("$arg") ;;
  esac
done

# ── Counters ──────────────────────────────────────────────────────────────
FAILURES=0
PASSES=0
TOTAL=0
FAILED_PACKAGES=()

# ── Discover packages ─────────────────────────────────────────────────────
PACKAGES=()
if [[ ${#REQUESTED_PACKAGES[@]} -gt 0 ]]; then
  # Use explicitly requested packages — validate each exists
  for pkg in "${REQUESTED_PACKAGES[@]}"; do
    if [[ ! -f "$REPO_ROOT/$pkg/apm.yml" ]]; then
      printf "  ${RED}ERROR: Package '%s' not found (no %s/apm.yml)${RESET}\n" "$pkg" "$pkg" >&2
      exit 1
    fi
    PACKAGES+=("$pkg")
  done
else
  # Find all top-level directories containing apm.yml, excluding examples/
  # and wrappers/ (and non-package dirs like scripts, .git, docs).
  for dir in "$REPO_ROOT"/*/; do
    dirname="$(basename "$dir")"
    case "$dirname" in
      examples|wrappers|scripts|docs|.git) continue ;;
    esac
    if [[ -f "$dir/apm.yml" ]]; then
      PACKAGES+=("$dirname")
    fi
  done
fi

TOTAL=${#PACKAGES[@]}

printf '%s\n' "${BOLD}=========================================${RESET}"
printf '%s\n' "${BOLD}  APM Package Validation Suite${RESET}"
printf '%s\n' "${BOLD}=========================================${RESET}"
printf '\n'
printf "Found ${CYAN}%d${RESET} packages to validate\n\n" "$TOTAL"

# ── Check apm availability ────────────────────────────────────────────────
APM_AVAILABLE=true
if ! command -v apm &>/dev/null; then
  printf "  ${YELLOW}WARNING: apm CLI not found – skipping dry-run checks${RESET}\n\n"
  APM_AVAILABLE=false
fi

# ── Validate each package ─────────────────────────────────────────────────
for pkg in "${PACKAGES[@]}"; do
  pkg_dir="$REPO_ROOT/$pkg"
  pkg_file="$pkg_dir/apm.yml"

  printf '%s\n' "${BOLD}-----------------------------------------${RESET}"
  printf '%s\n' "${BOLD}  ${pkg}${RESET}"
  printf '%s\n' "${BOLD}-----------------------------------------${RESET}"

  pkg_pass=true

  # --- Check 1: YAML syntax validation ---
  yaml_output=""
  if yaml_output=$(python3 -c "import yaml; yaml.safe_load(open('$pkg_file'))" 2>&1); then
    printf "  YAML syntax:          ${GREEN}OK${RESET}\n"
  else
    printf "  YAML syntax:          ${RED}FAIL${RESET}\n"
    printf "    %s\n" "$yaml_output"
    pkg_pass=false
  fi

  # --- Check 2: apm install --dry-run ---
  if $APM_AVAILABLE; then
    apm_output=""
    if apm_output=$(cd "$pkg_dir" && apm install --dry-run 2>&1); then
      printf "  apm install --dry-run: ${GREEN}OK${RESET}\n"
    else
      printf "  apm install --dry-run: ${RED}FAIL${RESET}\n"
      # Show first few lines of error output for context
      while IFS= read -r line; do
        printf "    %s\n" "$line"
      done <<< "$(echo "$apm_output" | head -5)"
      pkg_pass=false
    fi
  else
    printf "  apm install --dry-run: ${YELLOW}SKIPPED${RESET}\n"
  fi

  # --- Result for this package ---
  if $pkg_pass; then
    printf "  Result:               ${GREEN}PASS${RESET}\n"
    PASSES=$((PASSES + 1))
  else
    printf "  Result:               ${RED}FAIL${RESET}\n"
    FAILURES=$((FAILURES + 1))
    FAILED_PACKAGES+=("$pkg")
  fi
  printf "\n"
done

# ── Summary ───────────────────────────────────────────────────────────────
printf '%s\n' "${BOLD}=========================================${RESET}"
printf '%s\n' "${BOLD}  Summary${RESET}"
printf '%s\n' "${BOLD}=========================================${RESET}"
printf "  Total:  %d\n" "$TOTAL"
printf "  Passed: ${GREEN}%d${RESET}\n" "$PASSES"
printf "  Failed: ${RED}%d${RESET}\n" "$FAILURES"

if [[ ${#FAILED_PACKAGES[@]} -gt 0 ]]; then
  printf "\n"
  printf "  ${RED}Failed packages:${RESET}\n"
  for fp in "${FAILED_PACKAGES[@]}"; do
    printf "    ${RED}- %s${RESET}\n" "$fp"
  done
fi

printf '%s\n' "${BOLD}=========================================${RESET}"

# ── Exit code ─────────────────────────────────────────────────────────────
# Exit 1 if any package failed (regardless of --ci flag).
if [[ $FAILURES -gt 0 ]]; then
  exit 1
fi

exit 0
