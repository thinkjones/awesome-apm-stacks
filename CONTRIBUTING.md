# Contributing

Thanks for helping grow the library. This page covers the local setup, the pre-commit gate, and what CI will check before your pull request can merge.

## Getting set up

```bash
git clone https://github.com/thinkjones/awesome-apm-stacks.git
cd awesome-apm-stacks
npm install
```

`npm install` is not optional decoration — it is what installs the pre-commit gate. The repository's hooks are managed by [husky](https://typicode.github.io/husky/), and husky is wired in through the `prepare` script in `package.json`:

```json
"scripts": { "prepare": "husky" }
```

`prepare` runs on `npm install` and on `npm ci`, which is why a fresh clone has its hooks after one command with no extra setup step.

Two consequences worth knowing:

- **A clone that has never run `npm install` has no hooks at all.** `core.hooksPath` is unset and `.git/hooks/pre-commit` does not exist, so commits proceed ungated. This is the documented behaviour, not a defect — `scripts/test-pre-commit-hook.sh` asserts it as its first wiring case.
- **`npm install --ignore-scripts` also skips the hook installation**, because `prepare` is a lifecycle script. If you install with that flag, run `npx husky` once to install the hooks.

The pre-commit gate is also exercised by CI on every pull request, so a broken gate is caught there even if your local clone never installed it.

## What the pre-commit gate does

The gate refuses a commit that would break one of the APM packages you staged. It is scoped to package-shaped changes: if you stage an edit to `site/`, a Markdown file, or anything else that is not a package, the gate does nothing and the commit proceeds.

Concretely, `.husky/pre-commit` runs `scripts/pre-commit-validate.sh`, which:

1. maps the staged changeset to the affected packages (`scripts/staged-packages.sh`);
2. validates exactly those packages with `scripts/test-packages.sh` — the same validator CI runs.

If the `apm` CLI is not on your `PATH`, the YAML syntax and subpath layout checks still run and still refuse the commit; only the dependency-resolution check is skipped, and the message says so.

To run the gate by hand:

```bash
./scripts/pre-commit-validate.sh
```

To run the whole validator over every package:

```bash
./scripts/test-packages.sh          # all packages
./scripts/test-packages.sh --ci     # no colours, same exit codes (used by GitHub Actions)
```

## What the gate checks

For each package:

- **YAML syntax** — `apm.yml` parses.
- **Subpath layout** — the package directory is one APM will actually resolve for a consumer: a `plugin.json` (at the root, `.github/plugin/`, `.claude-plugin/` or `.cursor-plugin/`), a root `SKILL.md`, or a `.apm/` directory.
- **Dependency resolution** — the package's declared dependencies still exist upstream. This runs `apm lock` in a throwaway directory, which resolves for real without deploying anything.

## The pre-push gate

`.husky/pre-push` refuses any push that would update `refs/heads/main`, and it makes that decision from the remote ref in the push's ref list, so a push of `main` from a detached HEAD is refused too. `main` is protected on GitHub as well; the hook exists so you find out why, locally, instead of from a remote rejection.

## Self-test

The gate has its own test suite:

```bash
./scripts/test-pre-commit-hook.sh
```

It exercises the staged-package mapper, the pre-commit entrypoint, the husky wiring in a fresh clone, and the pre-push refusal. It needs `node`, `npm` and the npm registry. It runs on every pull request in the `test-packages` workflow.

## Adding a package

A package is a directory at the top level of the repository containing:

- `apm.yml` — the manifest, with a `name`, a `version`, a `description` and its `dependencies`
- `README.md` — what the package is for
- `.apm/` — the marker directory that makes the directory a resolvable APM package

Create it next to the existing ones and copy their shape. Dependencies point at upstream repositories and are resolved at consumer install time, so a dependency that no longer exists upstream makes the package uninstallable — the validator will tell you.

## Changing a package

Bump that package's `version:` in `apm.yml` in the same pull request. CI rejects a pull request that changes files inside a package directory without a strictly greater version.

```bash
./scripts/bump-version.sh ai-agents patch
./scripts/bump-version.sh code-python minor
./scripts/bump-version.sh architect-cloud major
```

Pick the bump type yourself:

- **Patch** (`0.1.3 → 0.1.4`) — bug fix, doc tweak, no behaviour change for consumers
- **Minor** (`0.1.3 → 0.2.0`) — additive change (new dep, new primitive, additional option)
- **Major** (`0.1.3 → 1.0.0`) — breaking change (removed dep, renamed primitive, incompatible option)

## What CI will check

Two status checks are required on pull requests against `main`:

- **`version-check`** — every changed package carries a strictly greater `version:`.
- **`test-packages`** — every changed package has a valid manifest, a valid subpath layout, and dependencies that still resolve upstream, and the pre-commit gate passes its self-test.

`strict` is enabled, so your branch must be up to date with `main` before it merges. Draft pull requests skip the `test-packages` job; promoting a draft to ready re-runs it.

The daily sweep validates every package and reports upstream drift. It is not a required check, so a red daily run does not block your pull request.

## When the daily sweep reports drift

Two jobs in the daily sweep watch for upstream moving out from under the repository:

- **Wrapper freshness** — `wrappers/<host>/<owner>/<repo>/apm.yml` is generated from its upstream repository. If the daily run says the generated wrappers have drifted from the committed ones, run `python scripts/generate-wrappers.py` and commit the result.
- **Locked dependency drift** — the root `apm.lock.yaml` pins this repository's own development dependencies. If the daily run says the locked dependencies have drifted from upstream, run `apm lock --update` and commit the refreshed `apm.lock.yaml`.

[`docs/ci.md`](docs/ci.md) is the full CI reference.
