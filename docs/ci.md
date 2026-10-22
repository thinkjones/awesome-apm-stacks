# CI

## Required status checks for `main`

Branch protection on `main` requires two checks. Both are bound to the GitHub Actions app (app id `15368`), so only a status written by GitHub Actions can satisfy them.

| Check | Workflow | Job | What it enforces |
| --- | --- | --- | --- |
| `version-check` | `.github/workflows/version-check.yml` | `version-check` | Every changed package directory carries a strictly greater semver in `apm.yml` |
| `test-packages` | `.github/workflows/test-packages.yml` | `test-packages` | Every changed package has valid YAML, a valid APM subpath layout, and dependencies that still resolve upstream — and the repository's own pre-commit gate passes its self-test |

`strict` is enabled: a pull request must be up to date with `main` before it merges.

The live protection object is at `repos/thinkjones/awesome-apm-stacks/branches/main/protection`.

This repository's own `CLAUDE.md` is a symlink to `AGENTS.md` and is gitignored — it is emitted by `apm compile` for consumers, not tracked here. The tracked copies of this reference are `AGENTS.md` and `docs/ci.md`.

### What `test-packages` actually enforces

The package validator is `scripts/test-packages.sh`. It runs three checks per package, and a fourth check over the repository's own tooling:

1. **YAML syntax** — every `apm.yml` parses.
2. **Subpath layout** — the package directory matches one of the three layouts APM's subpath resolver accepts: a `plugin.json` (at the root, `.github/plugin/`, `.claude-plugin/` or `.cursor-plugin/`), a root `SKILL.md`, or a `.apm/` directory. A package that fails this fails for a consumer running `apm install thinkjones/awesome-apm-stacks/<pkg>`.
3. **Dependency resolvability** — the package's declared dependencies still resolve upstream. This is `scripts/check-deps-resolvable.sh`, which resolves the package with `apm lock` in a throwaway directory.
4. **Pre-commit gate self-test** — `scripts/test-pre-commit-hook.sh` exercises the staged-package mapper, the pre-commit entrypoint, the husky wiring in a fresh clone, and the pre-push refusal.

Check 3 deliberately does **not** use `apm install --dry-run`. The dry run prints what it would install and exits 0 without contacting upstream: a package whose only dependency is `github/awesome-copilot/plugins/this-path-does-not-exist-xyz` passes it. `apm lock` resolves for real and deploys nothing, so it is the closest thing to a pure resolvability check.

Check 3 reports two kinds of failure, and they mean different things:

- A dependency that no longer resolves upstream — the subdirectory or the repository is gone — is a **failure**. The package cannot be installed by a consumer.
- A dependency that resolves but is an "Agent Plugin v1.0.0" package, which installs natively only for the `copilot` target, is a **warning**. The dependency is fine; the target coverage is not. These packages still install, they just carry less for consumers who are not on Copilot.

### Draft pull requests

`test-packages` skips draft pull requests. A skipped job satisfies a required status check, but GitHub refuses to merge a draft pull request at all, and `ready_for_review` is in the workflow's trigger list — so promoting a draft to ready re-runs the job with a real result. The skip is a saving on draft branches, not a way around the gate.

### A pull request that changes no package

A pull request that touches no package directory logs `No package directories changed - package validation is skipped` and passes. It is not a no-op: the pre-commit gate self-test still runs, so the check always does something real. Package validation is skipped because there is no package to validate, not because the check was waived.

## Workflows

| Workflow | Trigger | Scope |
| --- | --- | --- |
| `.github/workflows/test-packages.yml` | `pull_request` against `main` (`opened`, `synchronize`, `reopened`, `ready_for_review`) | Validates the packages the pull request changed, plus the pre-commit gate self-test. Draft pull requests are skipped; a draft promoted to ready is validated. |
| `.github/workflows/test-packages-daily.yml` | `schedule` `0 6 * * *`, `workflow_dispatch`, `push` to `main` | Validates every package on the schedule and on a manual run; validates only the packages a push to `main` touched. Unconditional — no commit-recency and no day-of-week throttle. Also runs the upstream-drift and wrapper-freshness jobs. |
| `.github/workflows/version-check.yml` | `pull_request` against `main` | Version-bump enforcement. |
| `.github/workflows/update-wrappers.yml` | `schedule` `0 6 * * 1` (Mondays), `workflow_dispatch` | Regenerates `wrappers/`. **Currently disabled** by GitHub's inactivity auto-disable (workflow id `257415437`), so the weekly cron does not fire. The daily sweep notices the resulting drift instead — see "Drift detection" below. Re-enabling it is a maintainer decision, because it makes the registry change on a schedule. |
| `.github/workflows/release.yml` | `push` to `main` | Publishes a tag and GitHub Release for every version bump. |
| `.github/workflows/deploy-site.yml` | Site deployment | Deploys the `site/` Astro project. |

## Drift detection

What consumers install from this registry is resolved from each package's `apm.yml` at install time, so drift in the published packages shows up as a dependency that no longer resolves. The daily sweep catches that three ways:

- **Package validation** over every package. A path that no longer exists upstream fails the resolve.
- **Wrapper freshness.** `wrappers/<host>/<owner>/<repo>/apm.yml` is generated from the upstream repository by `scripts/generate-wrappers.py`. When upstream moves a skill, the generated manifest goes stale and every package that depends on the wrapper stops resolving. The daily sweep regenerates the wrappers and fails if the result differs from the committed copy. This is what the disabled `update-wrappers.yml` cron would have caught.
- **Locked dependency drift.** The root `apm.lock.yaml` pins the repository's own development dependencies. `apm outdated` reports the locked dependencies whose upstream refs have moved since the lock was written. When it reports any, run `apm lock --update` and commit the refreshed `apm.lock.yaml`.

## Changing the required checks

Read the current value first:

```bash
gh api repos/thinkjones/awesome-apm-stacks/branches/main/protection
```

Then write the whole protection object back with the checks changed. **The granular endpoint `PUT .../protection/required_status_checks` returns `404 Not Found` for the token this repository uses**, so use the parent endpoint:

```bash
cat > /tmp/protection.json <<'JSON'
{
  "required_status_checks": {
    "strict": true,
    "contexts": ["version-check", "test-packages"]
  },
  "enforce_admins": false,
  "required_pull_request_reviews": {
    "dismiss_stale_reviews": false,
    "require_code_owner_reviews": false,
    "required_approving_review_count": 0
  },
  "restrictions": null,
  "required_linear_history": true,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "block_creations": false,
  "required_conversation_resolution": false,
  "lock_branch": false,
  "allow_fork_syncing": false
}
JSON

gh api --method PUT \
  repos/thinkjones/awesome-apm-stacks/branches/main/protection \
  --input /tmp/protection.json
```

Two things about this payload that are easy to get wrong:

- **The body must be complete.** The parent endpoint replaces the whole protection object. Every setting that is not in the body is reset to its default, which would silently drop `required_linear_history` and open up force pushes and deletions. Read the current object first and carry every setting across.
- **Send `contexts` or `checks`, not both.** The API rejects a `required_status_checks` object that carries both with `422 Invalid request` ("More than one subschema in 'oneOf' matched"). Sending `contexts` alone is enough: GitHub binds each context to the app that provides it, and the response carries the resulting `checks` array with `app_id` `15368` for both.

Verify:

```bash
gh api repos/thinkjones/awesome-apm-stacks/branches/main/protection \
  --jq '.required_status_checks'
```

### Reverting

Read the current value, then write the previous `contexts` list back with the same command:

```bash
gh api --method PUT \
  repos/thinkjones/awesome-apm-stacks/branches/main/protection \
  --input /tmp/protection.json
```

The output of the read is the only record of the previous `checks` array once it has been replaced — keep it.
