# APM Wrapper Plan: Auto-Discover Skills from Non-Conformant Repos

## Problem

Repos like `mattpocock/skills` contain 17+ skills as top-level folders (each with a `SKILL.md`), but no root `apm.yml` or `.apm/` directory. APM requires you to reference each subfolder individually:

```yaml
# This is what you'd have to do today — one line per skill
- mattpocock/skills/tdd
- mattpocock/skills/qa
- mattpocock/skills/grill-me
- mattpocock/skills/prd-to-plan
# ...13 more lines
```

We want to write `mattpocock/skills` once and get everything.

## Solution

A `wrappers/` directory in our APM packages monorepo. Each wrapper contains:

1. A **manifest** (`wrapper.yml`) declaring the upstream repo and a glob pattern
2. A **generated** `apm.yml` listing every discovered skill as a subdirectory dependency
3. A **GitHub Action** that regenerates the `apm.yml` on a schedule (or on push)

## Repo Structure

```
apm-packages/
├── apm-core/apm.yml
├── apm-python/apm.yml
├── ...
├── wrappers/
│   ├── mattpocock-skills/
│   │   ├── wrapper.yml          # YOU write this (source config)
│   │   └── apm.yml              # GENERATED (don't hand-edit)
│   ├── obra-superpowers/
│   │   ├── wrapper.yml
│   │   └── apm.yml
│   └── composio-awesome-claude-skills/
│       ├── wrapper.yml
│       └── apm.yml
├── scripts/
│   └── generate-wrappers.py     # The generator script
└── .github/
    └── workflows/
        └── update-wrappers.yml  # Scheduled rebuild
```

## wrapper.yml Schema

```yaml
# wrappers/mattpocock-skills/wrapper.yml
upstream: mattpocock/skills
ref: main                        # branch or tag to track
pattern: "*/SKILL.md"            # glob — find all folders containing SKILL.md
exclude:                         # optional — skip specific skills
  - migrate-to-shoehorn
  - scaffold-exercises
package:
  name: wrapper-mattpocock-skills
  version: auto                  # derived from upstream commit SHA
  description: >
    All skills from mattpocock/skills, auto-discovered and wrapped
    for APM consumption as a single dependency.
```

## Generator Script (`scripts/generate-wrappers.py`)

For each `wrapper.yml`:

1. **Clone/fetch** the upstream repo (shallow, sparse if possible)
2. **Glob** for the pattern (e.g. `*/SKILL.md`) to discover skill folders
3. **Apply excludes**
4. **Emit** `apm.yml` with one dependency line per discovered folder:

```yaml
# GENERATED — do not edit. Source: wrappers/mattpocock-skills/wrapper.yml
name: wrapper-mattpocock-skills
version: 1.0.0-abc1234
description: Auto-discovered skills from mattpocock/skills (17 skills)

dependencies:
  apm:
    - mattpocock/skills/tdd
    - mattpocock/skills/qa
    - mattpocock/skills/write-a-prd
    - mattpocock/skills/prd-to-plan
    - mattpocock/skills/prd-to-issues
    - mattpocock/skills/grill-me
    - mattpocock/skills/design-an-interface
    - mattpocock/skills/request-refactor-plan
    - mattpocock/skills/improve-codebase-architecture
    - mattpocock/skills/git-guardrails-claude-code
    - mattpocock/skills/setup-pre-commit
    - mattpocock/skills/write-a-skill
    - mattpocock/skills/edit-article
    - mattpocock/skills/triage-issues
    - mattpocock/skills/investigate-issue
    - mattpocock/skills/review-pr
    - mattpocock/skills/change-request
```

5. **Commit** the generated `apm.yml` if it changed

## GitHub Action

```yaml
# .github/workflows/update-wrappers.yml
name: Update APM Wrappers
on:
  schedule:
    - cron: "0 6 * * 1"          # Weekly Monday 6am UTC
  workflow_dispatch:               # Manual trigger

jobs:
  update:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: "3.12"

      - name: Generate wrappers
        run: python scripts/generate-wrappers.py wrappers/

      - name: Commit if changed
        run: |
          git diff --quiet || {
            git config user.name "apm-wrapper-bot"
            git config user.email "bot@your-org.com"
            git add wrappers/*/apm.yml
            git commit -m "chore: regenerate APM wrappers [skip ci]"
            git push
          }
```

## Consumption

Your flavour packages reference wrappers the same way as any other dependency:

```yaml
# apm-core/apm.yml
dependencies:
  apm:
    - your-org/apm-packages/wrappers/mattpocock-skills
    - your-org/apm-packages/wrappers/obra-superpowers
    - github/awesome-copilot/plugins/context-engineering
```

APM resolves transitively — the wrapper's generated `apm.yml` expands into all 17 individual skill references. The consumer sees one line.

## First Three Wrappers

| Wrapper | Upstream | ~Skills | Why |
|---|---|---|---|
| `mattpocock-skills` | `mattpocock/skills` | 17 | PRD, TDD, architecture, git, refactoring |
| `obra-superpowers` | `obra/superpowers` | 20+ | TDD red-green-refactor, debugging, collaboration |
| `composio-skills` | `ComposioHQ/awesome-claude-skills` | 30+ | LangSmith, Playwright, prompt-eng, postgres |

## Implementation Steps

1. **Write `generate-wrappers.py`** — ~80 lines of Python (clone, glob, emit YAML)
2. **Create `wrapper.yml`** for mattpocock/skills as proof of concept
3. **Run locally**, verify the generated `apm.yml` installs cleanly with `apm install`
4. **Add GitHub Action** for scheduled regeneration
5. **Wire into flavour packages** — replace verbose per-skill references with single wrapper lines
6. **Add obra + composio wrappers** once the pattern is proven