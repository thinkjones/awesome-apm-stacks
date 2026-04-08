#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CI_MODE=false
FAILURES=0
PASSES=0
FAILED_PACKAGES=()

if [[ "${1:-}" == "--ci" ]]; then
  CI_MODE=true
fi

echo "========================================="
echo "  APM Package Validation Suite"
echo "========================================="
echo ""

# Find all top-level dirs with apm.yml, excluding examples/
PACKAGES=()
for dir in "$REPO_ROOT"/*/; do
  dirname="$(basename "$dir")"
  if [[ "$dirname" == "examples" || "$dirname" == "scripts" || "$dirname" == ".git" ]]; then
    continue
  fi
  if [[ -f "$dir/apm.yml" ]]; then
    PACKAGES+=("$dirname")
  fi
done

echo "Found ${#PACKAGES[@]} packages to validate"
echo ""

for pkg in "${PACKAGES[@]}"; do
  pkg_dir="$REPO_ROOT/$pkg"
  echo "-----------------------------------------"
  echo "Testing: $pkg"
  echo "-----------------------------------------"

  # Test 1: YAML syntax validation
  yaml_ok=true
  yaml_err=""
  if ! yaml_err=$(python3 -c "
import yaml, sys
try:
    with open('$pkg_dir/apm.yml', 'r') as f:
        yaml.safe_load(f)
    print('YAML syntax: OK')
except yaml.YAMLError as e:
    print(f'YAML syntax: FAIL - {e}', file=sys.stderr)
    sys.exit(1)
" 2>&1); then
    yaml_ok=false
  fi
  echo "  $yaml_err"

  # Test 2: apm install --dry-run
  apm_ok=true
  apm_err=""
  if ! apm_err=$(cd "$pkg_dir" && apm install --dry-run 2>&1); then
    apm_ok=false
  fi

  if $apm_ok; then
    echo "  apm install --dry-run: OK"
  else
    echo "  apm install --dry-run: FAIL"
    echo "    $apm_err" | head -5
  fi

  # Test 3: Check required fields
  fields_ok=true
  fields_err=""
  if ! fields_err=$(python3 -c "
import yaml, sys
with open('$pkg_dir/apm.yml', 'r') as f:
    data = yaml.safe_load(f)
missing = []
for field in ['name', 'version', 'description']:
    if field not in data:
        missing.append(field)
if missing:
    print(f'Required fields missing: {missing}', file=sys.stderr)
    sys.exit(1)
print('Required fields: OK')
" 2>&1); then
    fields_ok=false
  fi
  echo "  $fields_err"

  # Determine pass/fail for this package
  if $yaml_ok && $apm_ok && $fields_ok; then
    echo "  Result: PASS"
    PASSES=$((PASSES + 1))
  else
    echo "  Result: FAIL"
    FAILURES=$((FAILURES + 1))
    FAILED_PACKAGES+=("$pkg")
  fi
  echo ""
done

echo "========================================="
echo "  Summary"
echo "========================================="
echo "  Total:  ${#PACKAGES[@]}"
echo "  Passed: $PASSES"
echo "  Failed: $FAILURES"

if [[ $FAILURES -gt 0 ]]; then
  echo ""
  echo "  Failed packages:"
  for fp in "${FAILED_PACKAGES[@]}"; do
    echo "    - $fp"
  done
fi

echo "========================================="

if $CI_MODE && [[ $FAILURES -gt 0 ]]; then
  exit 1
fi
