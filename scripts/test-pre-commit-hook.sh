#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# test-pre-commit-hook.sh - Self-tests for the pre-commit package-validation gate
#
# Usage:
#   bash scripts/test-pre-commit-hook.sh
#
# Sections:
#   mapper      - scripts/staged-packages.sh maps the staged changeset to the
#                 set of affected APM packages
#   entrypoint  - scripts/pre-commit-validate.sh refuses a commit whose staged
#                 packages fail validation
#
# The mapper and entrypoint sections need neither `apm` nor the network: every
# case builds a throwaway git repository in a temporary directory and runs the
# gate inside it. The entrypoint section puts an `apm` stub on PATH, or takes
# the real `apm` off PATH, so the branch under test is the one that runs.
#
# Every check prints PASS <name> or FAIL <name>. The script prints a final
# "N checks, M failed" line and exits 1 if any check failed.
# ---------------------------------------------------------------------------

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

CHECKS=0
FAILURES=0

pass() {
  CHECKS=$((CHECKS + 1))
  printf 'PASS %s\n' "$1"
}

fail() {
  CHECKS=$((CHECKS + 1))
  FAILURES=$((FAILURES + 1))
  printf 'FAIL %s\n' "$1"
}

section() {
  printf '\n--- %s ---\n' "$1"
}

expect_eq() {
  # expect_eq <name> <expected> <actual>
  if [ "$2" = "$3" ]; then
    pass "$1"
  else
    fail "$1 - expected [$2], got [$3]"
  fi
}

expect_contains() {
  # expect_contains <name> <haystack> <needle>
  case "$2" in
    *"$3"*) pass "$1" ;;
    *) fail "$1 - expected to contain [$3], got [$2]" ;;
  esac
}

expect_not_contains() {
  # expect_not_contains <name> <haystack> <needle>
  case "$2" in
    *"$3"*) fail "$1 - expected NOT to contain [$3], got [$2]" ;;
    *) pass "$1" ;;
  esac
}

# ── Fixture helpers ────────────────────────────────────────────────────────

write_manifest() {
  # write_manifest <path> <name>
  cat > "$1" <<EOF
name: $2
version: 1.0.0
description: Fixture package $2
author: Hook Test
EOF
}

make_repo() {
  # make_repo <dir> - build the throwaway fixture repository
  local dir="$1"
  mkdir -p "$dir"
  git init -q -b main "$dir"
  git -C "$dir" config user.email "hook-test@example.com"
  git -C "$dir" config user.name "Hook Test"
  git -C "$dir" config commit.gpgsign false

  mkdir -p "$dir/pkg/.apm" "$dir/pkg/src" "$dir/pkg2/.apm" \
           "$dir/examples/demo" "$dir/site" "$dir/docs" "$dir/scripts"

  write_manifest "$dir/pkg/apm.yml" "pkg"
  : > "$dir/pkg/.apm/.gitkeep"
  printf 'print("fixture")\n' > "$dir/pkg/src/main.py"
  printf 'name: [unclosed\n' > "$dir/pkg/broken.yml"
  printf '{}\n' > "$dir/pkg/valid-plugin.json"
  write_manifest "$dir/pkg2/apm.yml" "pkg2"
  : > "$dir/pkg2/.apm/.gitkeep"
  write_manifest "$dir/examples/demo/apm.yml" "demo"
  printf '<html></html>\n' > "$dir/site/index.astro"
  printf '# notes\n' > "$dir/docs/notes.md"
  printf '#!/usr/bin/env bash\necho tool\n' > "$dir/scripts/tool.sh"
  printf '# fixture\n' > "$dir/README.md"

  git -C "$dir" add -A
  git -C "$dir" commit -qm fixture
}

install_scripts_into() {
  # install_scripts_into <dir> - copy the gate scripts into the fixture repo.
  # The validator resolves its own repository root from its own path, so the
  # fixture needs its own copy for the fixture packages to be found. Each
  # script is copied only when it exists: a missing script must not abort the
  # whole harness before any assertion runs.
  local dir="$1"
  mkdir -p "$dir/scripts"
  for f in test-packages.sh staged-packages.sh pre-commit-validate.sh; do
    [ -f "$REPO_ROOT/scripts/$f" ] && cp "$REPO_ROOT/scripts/$f" "$dir/scripts/"
  done
  chmod +x "$dir"/scripts/*.sh 2>/dev/null || true
}

touch_content() {
  # touch_content <path> - append a comment so `git add` actually stages a
  # change. `git add` on an unmodified file stages nothing, which would make
  # the case fail for a reason that has nothing to do with the mapper.
  printf '# touched\n' >> "$1"
}

fixture_repo() {
  # fixture_repo <name> - print the path of a fresh fixture repository
  local dir="$TMP_ROOT/$1"
  make_repo "$dir"
  install_scripts_into "$dir"
  printf '%s\n' "$dir"
}

expect_mapper() {
  # expect_mapper <name> <dir> <expected stdout> <expected exit>
  local name="$1" dir="$2" expected_out="$3" expected_exit="$4"
  local out="" exit_code=0 err_file="$TMP_ROOT/mapper-stderr.txt"

  if out="$(cd "$dir" && scripts/staged-packages.sh 2>"$err_file")"; then
    exit_code=0
  else
    exit_code=$?
  fi

  if [ "$out" = "$expected_out" ] && [ "$exit_code" = "$expected_exit" ]; then
    pass "$name"
  else
    fail "$name - expected stdout=[$expected_out] exit=[$expected_exit], got stdout=[$out] exit=[$exit_code]"
  fi
}

HOOK_OUT=""
HOOK_ERR=""
HOOK_EXIT=0

run_hook() {
  # run_hook <mode> <dir> - run the entrypoint inside the fixture repository.
  # mode is plain, with-apm or without-apm. The results land in HOOK_OUT,
  # HOOK_ERR and HOOK_EXIT.
  local mode="$1" dir="$2"
  local out_file="$TMP_ROOT/hook-out.txt" err_file="$TMP_ROOT/hook-err.txt"
  HOOK_OUT=""
  HOOK_ERR=""
  HOOK_EXIT=0

  case "$mode" in
    plain)
      if (cd "$dir" && scripts/pre-commit-validate.sh >"$out_file" 2>"$err_file"); then
        HOOK_EXIT=0
      else
        HOOK_EXIT=$?
      fi
      ;;
    with-apm)
      if with_apm 0 sh -c 'cd "$1" && scripts/pre-commit-validate.sh' sh "$dir" \
          >"$out_file" 2>"$err_file"; then
        HOOK_EXIT=0
      else
        HOOK_EXIT=$?
      fi
      ;;
    without-apm)
      if without_apm sh -c 'cd "$1" && scripts/pre-commit-validate.sh' sh "$dir" \
          >"$out_file" 2>"$err_file"; then
        HOOK_EXIT=0
      else
        HOOK_EXIT=$?
      fi
      ;;
    *)
      fail "run_hook: unknown mode $mode"
      return 0
      ;;
  esac

  HOOK_OUT="$(cat "$out_file")"
  HOOK_ERR="$(cat "$err_file")"
}

# ── PATH helpers ───────────────────────────────────────────────────────────
#
# `apm` is installed on the maintainer's machine, so a case that needs the
# "apm is absent" branch has to take the real binary out of PATH - outranking
# it with a stub is not enough.

path_without_apm() {
  # Print a PATH in which the real `apm` cannot be found. The directory that
  # holds it is replaced by a mirror of itself without `apm`, so every other
  # tool stays reachable.
  local apm_path="" apm_dir="" entry out=""
  apm_path="$(command -v apm || true)"
  if [ -n "$apm_path" ]; then
    apm_dir="$(cd "$(dirname "$apm_path")" && pwd)"
  fi

  local mirror="$TMP_ROOT/path-without-apm"
  mkdir -p "$mirror"
  if [ -n "$apm_dir" ]; then
    for entry in "$apm_dir"/*; do
      [ -e "$entry" ] || continue
      case "$(basename "$entry")" in
        apm) continue ;;
      esac
      ln -sf "$entry" "$mirror/$(basename "$entry")" 2>/dev/null || true
    done
  fi

  local old_ifs="$IFS"
  IFS=':'
  for entry in $PATH; do
    [ -n "$entry" ] || continue
    if [ -n "$apm_dir" ] && [ "$(cd "$entry" 2>/dev/null && pwd)" = "$apm_dir" ]; then
      out="$out:$mirror"
    else
      out="$out:$entry"
    fi
  done
  IFS="$old_ifs"
  printf '%s\n' "${out#:}"
}

with_apm() {
  # with_apm <exit_code> <command...> - run a command with an `apm` stub that
  # exits with the given code, and with the real apm removed from PATH
  local exit_code="$1"
  shift
  local stub_dir="$TMP_ROOT/apm-stub"
  mkdir -p "$stub_dir"
  printf '#!/usr/bin/env sh\nexit %s\n' "$exit_code" > "$stub_dir/apm"
  chmod +x "$stub_dir/apm"
  PATH="$stub_dir:$(path_without_apm)" "$@"
}

without_apm() {
  # without_apm <command...> - run a command with the real apm removed from
  # PATH and no stub at all
  PATH="$(path_without_apm)" "$@"
}

# ── Section: mapper ────────────────────────────────────────────────────────

section "mapper"

repo="$(fixture_repo mapper-none)"
expect_mapper "mapper 1  nothing staged" "$repo" "" 0

repo="$(fixture_repo mapper-readme)"
touch_content "$repo/README.md"
git -C "$repo" add README.md
expect_mapper "mapper 2  README.md staged" "$repo" "" 0

repo="$(fixture_repo mapper-site)"
touch_content "$repo/site/index.astro"
git -C "$repo" add site/index.astro
expect_mapper "mapper 3  site/index.astro staged" "$repo" "" 0

repo="$(fixture_repo mapper-docs)"
touch_content "$repo/docs/notes.md"
git -C "$repo" add docs/notes.md
expect_mapper "mapper 4  docs/notes.md staged" "$repo" "" 0

repo="$(fixture_repo mapper-scripts)"
touch_content "$repo/scripts/tool.sh"
git -C "$repo" add scripts/tool.sh
expect_mapper "mapper 5  scripts/tool.sh staged" "$repo" "" 0

repo="$(fixture_repo mapper-examples)"
touch_content "$repo/examples/demo/apm.yml"
git -C "$repo" add examples/demo/apm.yml
expect_mapper "mapper 6  examples/demo/apm.yml staged" "$repo" "" 0

repo="$(fixture_repo mapper-pkg-manifest)"
touch_content "$repo/pkg/apm.yml"
git -C "$repo" add pkg/apm.yml
expect_mapper "mapper 7  pkg/apm.yml staged" "$repo" "pkg" 0

repo="$(fixture_repo mapper-pkg-source)"
touch_content "$repo/pkg/src/main.py"
git -C "$repo" add pkg/src/main.py
expect_mapper "mapper 8  pkg/src/main.py staged" "$repo" "pkg" 0

repo="$(fixture_repo mapper-pkg-apm-dir)"
touch_content "$repo/pkg/.apm/.gitkeep"
git -C "$repo" add pkg/.apm/.gitkeep
expect_mapper "mapper 9  pkg/.apm/.gitkeep staged" "$repo" "pkg" 0

repo="$(fixture_repo mapper-two-packages)"
touch_content "$repo/pkg/apm.yml"
touch_content "$repo/pkg2/apm.yml"
git -C "$repo" add pkg/apm.yml pkg2/apm.yml
expect_mapper "mapper 10 pkg/apm.yml and pkg2/apm.yml staged" "$repo" "pkg
pkg2" 0

repo="$(fixture_repo mapper-package-and-docs)"
touch_content "$repo/pkg/apm.yml"
touch_content "$repo/docs/notes.md"
git -C "$repo" add pkg/apm.yml docs/notes.md
expect_mapper "mapper 11 pkg/apm.yml and docs/notes.md staged" "$repo" "pkg" 0

repo="$(fixture_repo mapper-deleted-manifest)"
git -C "$repo" rm -q pkg/apm.yml
expect_mapper "mapper 12 pkg/apm.yml deleted" "$repo" "pkg" 0

repo="$(fixture_repo mapper-renamed-manifest)"
git -C "$repo" mv pkg/apm.yml pkg/apm.yml.bak
expect_mapper "mapper 13 pkg/apm.yml renamed to pkg/apm.yml.bak" "$repo" "pkg" 0

repo="$(fixture_repo mapper-added-package)"
mkdir -p "$repo/newpkg"
write_manifest "$repo/newpkg/apm.yml" "newpkg"
git -C "$repo" add newpkg/apm.yml
expect_mapper "mapper 14 newpkg/apm.yml added" "$repo" "newpkg" 0

repo="$(fixture_repo mapper-unstaged-manifest)"
mkdir -p "$repo/newpkg"
write_manifest "$repo/newpkg/apm.yml" "newpkg"
printf 'other\n' > "$repo/newpkg/other.txt"
git -C "$repo" add newpkg/other.txt
expect_mapper "mapper 15 newpkg/other.txt added, newpkg/apm.yml unstaged" "$repo" "" 0

repo="$(fixture_repo mapper-unicode-path)"
mkdir -p "$repo/pkg/ünïcode dir"
printf 'unicode\n' > "$repo/pkg/ünïcode dir/naïve name.md"
git -C "$repo" add "pkg/ünïcode dir/naïve name.md"
expect_mapper "mapper 16 unicode path staged" "$repo" "pkg" 0

repo="$(fixture_repo mapper-outside-repo)"
outside="$TMP_ROOT/outside-a-git-repo"
mkdir -p "$outside"
out=""
exit_code=0
if out="$(cd "$outside" && "$repo/scripts/staged-packages.sh" 2>"$TMP_ROOT/mapper-stderr.txt")"; then
  exit_code=0
else
  exit_code=$?
fi
if [ "$out" = "" ] && [ "$exit_code" = "2" ]; then
  pass "mapper 17 run outside a git repository"
else
  fail "mapper 17 run outside a git repository - expected stdout=[] exit=[2], got stdout=[$out] exit=[$exit_code]"
fi

# ── Section: entrypoint ────────────────────────────────────────────────────

section "entrypoint"

repo="$(fixture_repo hook-none)"
run_hook plain "$repo"
expect_eq "hook 1  nothing staged exits 0" 0 "$HOOK_EXIT"
expect_eq "hook 1  nothing staged prints nothing on stdout" "" "$HOOK_OUT"
expect_eq "hook 1  nothing staged prints nothing on stderr" "" "$HOOK_ERR"

repo="$(fixture_repo hook-readme)"
touch_content "$repo/README.md"
git -C "$repo" add README.md
run_hook plain "$repo"
expect_eq "hook 2  only README.md staged exits 0" 0 "$HOOK_EXIT"
expect_eq "hook 2  only README.md staged prints nothing on stdout" "" "$HOOK_OUT"
expect_eq "hook 2  only README.md staged prints nothing on stderr" "" "$HOOK_ERR"

repo="$(fixture_repo hook-site)"
touch_content "$repo/site/index.astro"
git -C "$repo" add site/index.astro
run_hook plain "$repo"
expect_eq "hook 3  only site/index.astro staged exits 0" 0 "$HOOK_EXIT"
expect_eq "hook 3  only site/index.astro staged prints nothing on stdout" "" "$HOOK_OUT"
expect_eq "hook 3  only site/index.astro staged prints nothing on stderr" "" "$HOOK_ERR"

repo="$(fixture_repo hook-valid)"
touch_content "$repo/pkg/apm.yml"
git -C "$repo" add pkg/apm.yml
run_hook with-apm "$repo"
expect_eq "hook 4  valid package exits 0" 0 "$HOOK_EXIT"
expect_contains "hook 4  stdout names the package" "$HOOK_OUT" "pkg"
expect_contains "hook 4  stdout shows the result" "$HOOK_OUT" "Result:"
expect_contains "hook 4  stdout shows the verdict" "$HOOK_OUT" "PASS"
expect_contains "hook 4  stdout shows the package count" "$HOOK_OUT" "Total:"
expect_contains "hook 4  stdout shows the passed count" "$HOOK_OUT" "Passed:"

repo="$(fixture_repo hook-broken-yaml)"
cp "$repo/pkg/broken.yml" "$repo/pkg/apm.yml"
git -C "$repo" add pkg/apm.yml
run_hook with-apm "$repo"
expect_eq "hook 5  broken manifest exits 1" 1 "$HOOK_EXIT"
expect_contains "hook 5  stdout names the offending path" "$HOOK_OUT" "pkg/apm.yml"
expect_contains "hook 5  stdout names the failing rule" "$HOOK_OUT" "YAML syntax"
expect_contains "hook 5  stdout shows the verdict" "$HOOK_OUT" "FAIL"

repo="$(fixture_repo hook-broken-layout)"
git -C "$repo" rm -q pkg/.apm/.gitkeep
run_hook with-apm "$repo"
expect_eq "hook 6  missing .apm/ exits 1" 1 "$HOOK_EXIT"
expect_contains "hook 6  stdout names the failing rule" "$HOOK_OUT" "Subpath layout"
expect_contains "hook 6  stdout shows the verdict" "$HOOK_OUT" "FAIL"

repo="$(fixture_repo hook-no-apm-valid)"
touch_content "$repo/pkg/apm.yml"
git -C "$repo" add pkg/apm.yml
run_hook without-apm "$repo"
expect_eq "hook 7  valid package without apm exits 0" 0 "$HOOK_EXIT"
expect_contains "hook 7  stderr explains the missing CLI" "$HOOK_ERR" "apm CLI not found"
expect_contains "hook 7  stderr gives the install command" "$HOOK_ERR" "curl -sSL https://aka.ms/apm-unix | sh"
expect_not_contains "hook 7  stdout does not claim --ci needs apm" "$HOOK_OUT" "apm CLI not found — required in --ci mode"

repo="$(fixture_repo hook-no-apm-broken)"
cp "$repo/pkg/broken.yml" "$repo/pkg/apm.yml"
git -C "$repo" add pkg/apm.yml
run_hook without-apm "$repo"
expect_eq "hook 8  broken manifest without apm exits 1" 1 "$HOOK_EXIT"
expect_contains "hook 8  stdout names the offending path" "$HOOK_OUT" "pkg/apm.yml"
expect_contains "hook 8  stdout names the failing rule" "$HOOK_OUT" "YAML syntax"
expect_not_contains "hook 8  stdout does not blame the missing CLI" "$HOOK_OUT" "required in --ci mode"

repo="$(fixture_repo hook-renamed-manifest)"
git -C "$repo" mv pkg/apm.yml pkg/apm.yml.bak
run_hook with-apm "$repo"
expect_eq "hook 9  renamed manifest exits 1" 1 "$HOOK_EXIT"
expect_contains "hook 9  stderr names the missing package" "$HOOK_ERR" "Package 'pkg' not found"
expect_eq "hook 9  stdout is empty" "" "$HOOK_OUT"

repo="$(fixture_repo hook-plugin-layout)"
touch_content "$repo/pkg/valid-plugin.json"
printf '{}\n' > "$repo/pkg/plugin.json"
git -C "$repo" rm -q pkg/.apm/.gitkeep
git -C "$repo" add pkg/valid-plugin.json pkg/plugin.json
run_hook with-apm "$repo"
expect_eq "hook 10 plugin layout exits 0" 0 "$HOOK_EXIT"

# ── Summary ────────────────────────────────────────────────────────────────

printf '\n%s checks, %s failed\n' "$CHECKS" "$FAILURES"
if [ "$FAILURES" -gt 0 ]; then
  exit 1
fi
exit 0
