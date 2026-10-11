# wrappers

Generated APM packages that track an upstream skills monorepo. A wrapper lets a stack depend on "every skill in that repo, minus a few" without hand-maintaining the list.

## Layout

Each wrapper lives at `wrappers/github.com/<owner>/<repo>/` and holds two files:

| File | Edited by | Purpose |
| --- | --- | --- |
| `wrapper.yml` | You | Names the upstream repo, the branch, the glob pattern that finds skills, and any skills to exclude. |
| `apm.yml` | The generator | One dependency line per discovered skill. Do not edit by hand. |

## Current wrappers

| Wrapper | Upstream | Consumed by |
| --- | --- | --- |
| [`github.com/mattpocock/skills`](github.com/mattpocock/skills/) | [mattpocock/skills](https://github.com/mattpocock/skills) | [`code-core`](../code-core/) |

## Use a wrapper

Reference it by path, like any other package in this repo:

```yaml
dependencies:
  apm:
    - thinkjones/awesome-apm-stacks/wrappers/github.com/mattpocock/skills
```

## Regenerate

```bash
pip install pyyaml
python scripts/generate-wrappers.py
```

The script shallow-clones each upstream repo, globs for the `pattern` in `wrapper.yml`, drops the `exclude` entries, and rewrites `apm.yml`. With `version: auto`, the generated version carries the upstream commit SHA.

`.github/workflows/update-wrappers.yml` runs the same script every Monday at 06:00 UTC and commits the result to `main` when an upstream repo has changed.

## Add a wrapper

1. Create `wrappers/github.com/<owner>/<repo>/wrapper.yml`. Copy [`github.com/mattpocock/skills/wrapper.yml`](github.com/mattpocock/skills/wrapper.yml) as a starting point.
2. Set `upstream`, `ref`, `pattern` and `exclude`.
3. Run `python scripts/generate-wrappers.py` and commit both files.
4. Add the wrapper path to the stack that should consume it, and bump that stack's version.
