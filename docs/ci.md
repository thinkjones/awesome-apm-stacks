# CI

## Required status checks for `main`

Branch protection on `main` requires both checks below. The protection object lives at `repos/thinkjones/awesome-apm-stacks/branches/main/protection/required_status_checks` and is applied by a maintainer — the exact command is in the pull request that introduced `test-packages`.

| Check | Workflow | Job | What it enforces |
| --- | --- | --- | --- |
| `version-check` | `.github/workflows/version-check.yml` | `version-check` | Every changed package directory carries a strictly greater semver in `apm.yml` |
| `test-packages` | `.github/workflows/test-packages.yml` | `test-packages` | Every changed package has valid YAML, a valid APM subpath layout, and resolvable dependencies |

`strict` is enabled: a pull request must be up to date with `main` before it merges.

## Workflows

| Workflow | Trigger | Scope |
| --- | --- | --- |
| `.github/workflows/test-packages.yml` | `pull_request` against `main` (`opened`, `synchronize`, `reopened`, `ready_for_review`) | Validates only the packages the pull request changed. Draft pull requests are skipped; a draft promoted to ready is validated. |
| `.github/workflows/test-packages-daily.yml` | `schedule` `0 6 * * *`, `workflow_dispatch`, `push` to `main` | Validates every package in the repository. Unconditional — no commit-recency and no day-of-week throttle. |
| `.github/workflows/version-check.yml` | `pull_request` against `main` | Version-bump enforcement. |
| `.github/workflows/update-wrappers.yml` | `schedule` `0 6 * * 1` (Mondays), `workflow_dispatch` | Regenerates `wrappers/`. Independent of package validation. |
| `.github/workflows/release.yml` | Tag push | Publishes a tag and GitHub Release for every version bump. |
| `.github/workflows/deploy-site.yml` | Site deployment | Deploys the `site/` Astro project. |

## Changing the required checks

Read the current value first, then update it with the granular endpoint so the rest of the protection object is left alone:

```bash
gh api repos/thinkjones/awesome-apm-stacks/branches/main/protection/required_status_checks
```

```bash
gh api --method PUT \
  repos/thinkjones/awesome-apm-stacks/branches/main/protection/required_status_checks \
  -F strict=true \
  -f 'contexts[]=version-check' \
  -f 'contexts[]=test-packages'
```

Do not use `PUT .../branches/main/protection` — it replaces the whole protection object and silently drops `required_linear_history`, `allow_force_pushes`, `allow_deletions`, `enforce_admins`, and `required_approving_review_count`.

Verify:

```bash
gh api repos/thinkjones/awesome-apm-stacks/branches/main/protection/required_status_checks
```

### Known effect of the command above — it clears the app binding

The live protection object carries `checks: [{"context":"version-check","app_id":15368}]` — `version-check` is bound to the GitHub Actions app (app id `15368`). The granular endpoint replaces the whole `required_status_checks` object — `strict`, `contexts`, and `checks` together — so the `PUT` above, which sends no `checks` array, clears that binding. After it runs, both required contexts are unbound: any integration able to write a status named `version-check` or `test-packages` could satisfy them.

Every other protection setting — `required_linear_history`, `allow_force_pushes`, `allow_deletions`, `enforce_admins`, `required_approving_review_count`, `required_conversation_resolution`, `lock_branch`, `allow_fork_syncing`, `block_creations` — lives on the parent `/protection` object and is untouched by this endpoint.

### Keeping the app binding

Send the same endpoint with a `checks` array as well — `checks[][context]=version-check` and `checks[][app_id]=15368` for the existing context, and the same pair for `test-packages`:

```bash
gh api --method PUT \
  repos/thinkjones/awesome-apm-stacks/branches/main/protection/required_status_checks \
  -F strict=true \
  -f 'contexts[]=version-check' \
  -f 'contexts[]=test-packages' \
  -F 'checks[][context]=version-check' \
  -F 'checks[][app_id]=15368' \
  -F 'checks[][context]=test-packages' \
  -F 'checks[][app_id]=15368'
```

Use `-F` rather than `-f` for `app_id`: the field is an integer in the API, and `-f` would send it as the string `"15368"`. The same object can also be sent with `gh api --method PUT ... --input <file>`, with a JSON body carrying both `contexts` and `checks`.

**This variant is not exercised by this change.** The branch-protection change is a documented maintainer step — it is not executed by any workflow, script, or agent in this repository — so confirm in the verification step that the response body still carries the `checks` array before relying on it.

### Reverting

Read the current value, then `PUT` back the observed original, and re-attach the original `checks` array if it was bound:

```bash
gh api --method PUT \
  repos/thinkjones/awesome-apm-stacks/branches/main/protection/required_status_checks \
  -F strict=<observed value from the read above> \
  -f 'contexts[]=version-check'
```

The output of the read in step 1 is the only record of the original `checks` array once it has been replaced — keep it.
