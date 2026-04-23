---
name: apm-retrofit
description: Retrofit an existing skills/plugins/agents repository into an APM-compliant package. Use when a repo contains SKILL.md files, a plugin.json, AGENTS.md/CLAUDE.md, MCP manifests, hooks, slash commands, or sub-agents but has no apm.yml (or has an incomplete one), and the user wants it installable via `apm install owner/repo`. TRIGGER when the user says "make this APM-compliant", "add an apm.yml", "convert my skills repo to APM", "retrofit for APM", or runs `/apm-retrofit`. SKIP when the repo already has a correctly-shaped apm.yml covering every primitive present, or the repo is not an agent-config repo (e.g. a regular application).
---

# Retrofit a repo for APM compliance

This skill converts an existing agent-config repo into a package that Microsoft APM (`apm install owner/repo`) can resolve, install, and compile to any supported runtime. It is a deliberate extension of `apm init` (which only drops a stub manifest) — this skill introspects what's actually in the repo, classifies every primitive, and emits a manifest that reflects reality.

You are operating on the repo in the current working directory. Never touch repos outside it. Never run `apm install`, `git push`, or any non-local command without explicit user approval.

## Ground rules

- **Never overwrite an existing `apm.yml` silently.** If one is present, read it, diff your proposal against it, and surface the conflict for the user to resolve.
- **Never delete existing files.** This skill adds and (on approval) edits — it does not remove `plugin.json`, `CLAUDE.md`, `AGENTS.md`, or anything else. APM is explicitly brownfield-friendly.
- **Fail loudly on ambiguity.** If the repo has no recognisable primitives, stop and tell the user — don't write a meaningless stub manifest.
- **Don't guess versions.** If no prior version signal exists, propose `0.1.0` and ask the user to confirm.
- **No magic.** Every field you emit must be grounded in something you actually observed in the repo. Cite the source (file path) in your report.

## Workflow

### 1. Inventory

Use `Glob` and `Read` (not Bash find) to scan the repo. Record every match with its path.

| Primitive | Look in | Evidence |
|-----------|---------|----------|
| Claude/Agent Skills | `SKILL.md` (root), `skills/*/SKILL.md`, `.apm/skills/*/SKILL.md`, `*/SKILL.md` | YAML frontmatter with `name:` and `description:` |
| Plugin manifest | `plugin.json`, `.github/plugin/plugin.json`, `.claude-plugin/plugin.json`, `.cursor-plugin/plugin.json` | JSON with `name` and `version` |
| Sub-agents | `agents/*.agent.md`, `.claude/agents/*.md`, `.apm/agents/*.agent.md` | Markdown with agent frontmatter |
| Slash commands / prompts | `commands/*.md`, `.claude/commands/*.md`, `prompts/*.prompt.md`, `.apm/prompts/*.prompt.md` | Command files |
| Hooks | `hooks/*.json`, `hooks.json`, `.claude/settings.json` (with `hooks:` key), `settings.json` | JSON with `hooks` |
| MCP servers | `.mcp.json`, `.github/.mcp.json`, `mcp.json`, or `mcpServers` key inside `plugin.json` | JSON server definitions |
| Instructions | `AGENTS.md`, `CLAUDE.md`, `.github/instructions/*.instructions.md`, `.apm/instructions/*.instructions.md`, `.cursorrules` | Markdown/MDC |
| Chatmodes | `.github/chatmodes/*.chatmode.md`, `.apm/chatmodes/*.chatmode.md` | Markdown with chatmode frontmatter |

If none of the above is found, stop and tell the user: "No APM-compatible primitives found in this repo. APM manages skills, plugins, agents, hooks, MCP servers, instructions, and slash commands — is this the right directory?"

### 2. Choose the layout (critical)

APM's subpath resolver (`apm install owner/repo/subdir`) accepts exactly three layouts. Pick the smallest-diff match and record which primitives — if any — need to be moved to make the repo conform.

| Signal | Layout | Primitives live at | `apm.yml` |
|--------|--------|--------------------|-----------|
| Any `plugin.json` present (root, `.github/plugin/`, `.claude-plugin/`, or `.cursor-plugin/`) | **Plugin** | Root: `skills/<name>/SKILL.md`, `agents/`, `commands/`, `hooks/` | Optional |
| Single root `SKILL.md`, no other primitives | **Claude Skill** | Root: `SKILL.md` | Optional — APM auto-synthesises on install |
| Multiple primitives, no `plugin.json` | **APM package** | `.apm/skills/<name>/SKILL.md`, `.apm/agents/`, `.apm/commands/`, `.apm/hooks/`, `.apm/instructions/`, `.apm/prompts/`, `.apm/chatmodes/` | Required |

**The broken shape**: `apm.yml` at root with skills still at `skills/<name>/SKILL.md` outside `.apm/`. APM rejects this with `Subdirectory is not a valid APM package or Claude Skill: Missing required directory: .apm/`. If the target repo has this shape, files must move or a `plugin.json` must be added.

#### Pick the path

- **Repo already has `plugin.json`** → Plugin layout. No primitives need to move. Add `apm.yml` alongside; primitives stay at root.
- **Repo has a single root `SKILL.md` and nothing else** → Claude Skill. Optionally add `apm.yml` for explicit metadata. No moves.
- **Repo has primitives at `skills/`, `agents/`, `commands/`, `hooks/` and NO `plugin.json`** → APM package. Propose moving each primitive directory into `.apm/` (see below) OR propose adding a minimal `plugin.json` if the user prefers to keep the flat layout.
- **Repo already uses `.apm/` paths** → APM package. No moves.

#### Propose moves as a git-mv block

When moves are required, propose them explicitly and wait for confirmation. Render as a single block the user can apply verbatim. Skip any source that doesn't exist:

```bash
git mv skills .apm/skills
git mv agents .apm/agents
git mv commands .apm/commands
git mv hooks .apm/hooks
git mv instructions .apm/instructions     # if at root
git mv prompts .apm/prompts                # if at root
```

Do **not** move `.claude/`, `.github/`, `.cursor/`, `.codex/`, or `.opencode/` — those are target-shape directories APM emits into at compile time, not sources. Do **not** move `AGENTS.md` or `CLAUDE.md` — those stay at repo root as instructions.

`SKILL.md` frontmatter `name:` is what APM keys the deployed skill off — not the directory path — so moves don't rename anything consumers see.

### 3. Classify `type:`

Use the APM manifest schema v0.1 rules (see `https://microsoft.github.io/apm/reference/primitive-types/`):

| What you found | Proposed `type:` |
|----------------|------------------|
| Only `SKILL.md` files | `skill` |
| Only instructions files (`*.instructions.md`, `AGENTS.md`, `CLAUDE.md`) | `instructions` |
| Only prompts/commands | `prompts` |
| A mix of two or more of the above | `hybrid` |

If a `plugin.json` is present, you may omit `type:` and let APM infer it — but if you are confident, emit `hybrid` explicitly.

### 4. Detect `target:`

Look for these directories or files as evidence of the runtime(s) the repo was authored for:

| Signal present | Emit |
|----------------|------|
| `.claude/` or `CLAUDE.md` | `claude` |
| `.github/` (with agent primitives) or `AGENTS.md` | `copilot` (or `agents` for provider-neutral) |
| `.cursor/` or `.cursorrules` | `cursor` |
| `.codex/` | `codex` |
| `.opencode/` | `opencode` |
| Two or more of the above | `all` |
| None | Omit the field — APM auto-detects |

Prefer `all` over guessing when in doubt; APM will emit what each runtime needs at compile time.

### 5. Derive the manifest fields

- `name` — kebab-case, lowercase, alphanumeric + hyphens. Source, in order: existing `apm.yml` → existing `plugin.json.name` → existing `package.json.name` → repo directory name. If the source string contains uppercase or underscores, convert to kebab-case.
- `version` — semver. Source, in order: existing `apm.yml.version` → existing `plugin.json.version` → existing `package.json.version` → latest git tag that parses as semver → `0.1.0`.
- `description` — one sentence, ≤160 chars. Source, in order: existing manifest → README first paragraph → SKILL.md description field → synthesised from `name`.
- `author` — `git config user.name` if not already set.
- `license` — read from `LICENSE`/`LICENSE.txt`/`package.json.license` if unambiguous; omit otherwise.

### 6. Enumerate dependencies

If the repo already depends on other APM packages or MCP servers (e.g. a `plugin.json` lists `mcpServers`, or a `package.json` declares agent-related deps), translate them to APM's `dependencies:` shape:

```yaml
dependencies:
  apm:
    - owner/repo/virtual-path            # other APM packages
    - owner/repo/path/to/file.skill.md   # individual primitives
  mcp:
    - name: postgres
      command: npx
      args: [-y, "@modelcontextprotocol/server-postgres"]
```

If you cannot find any dependencies, omit the `dependencies:` section entirely (it's optional). Do **not** emit `dependencies: {apm: []}` — some APM versions reject the empty-list shape. Do **not** invent dependencies.

### 7. Propose, diff, confirm, write

Before writing or moving anything:

1. **Proposed moves** — if Step 2 identified any, render them as a `git mv` block and explain why (e.g. "`skills/` at root with no `plugin.json` would be rejected by APM; moving to `.apm/skills/` aligns the repo with the APM package layout").
2. **Proposed `apm.yml`** — render in a fenced code block.
3. **Diff against existing `apm.yml`** if present — unified diff, highlight changed fields, flag fields the user might want to hand-edit (e.g. a tailored description).
4. **Primitive map** — list every primitive and the path it will live at *after* moves, plus the install-time name consumers will see. Example:
   ```
   Found 3 primitives (current: skills/ at root, no plugin.json → APM-package-incompatible):
     - skills/pdf-generator/SKILL.md  →  move to .apm/skills/pdf-generator/SKILL.md  →  deploys as skill `pdf-generator`
     - agents/code-reviewer.agent.md  →  move to .apm/agents/code-reviewer.agent.md  →  deploys as agent `code-reviewer`
     - .github/instructions/style.md  →  unchanged                                   →  deploys as instruction `style`

   Proposed moves:
     git mv skills .apm/skills
     git mv agents .apm/agents
   ```
5. Ask the user to confirm ("Apply moves and write this `apm.yml`?"). Only then: execute moves via `Bash` (`git mv`), then `Write` the manifest. Run moves before writing the manifest so validation in Step 8 sees the final shape.

### 8. Validate

After moves and manifest are in place, do three checks — in this order, and report results:

1. **YAML syntax** — parse the file with `python3 -c "import yaml; yaml.safe_load(open('apm.yml'))"`. If it fails, the skill has produced invalid YAML; stop and fix before anything else.

2. **Subpath layout** — the repo root (and every subdirectory that has its own `apm.yml`, e.g. a monorepo stack) must match one of APM's three consumer-install layouts, otherwise a downstream `apm install owner/repo[/subdir]` will fail with `Subdirectory is not a valid APM package or Claude Skill: Missing required directory: .apm/`. Crucially, a local `apm install --dry-run` run from *inside* the package will NOT catch this — it only validates the package's own dependency graph, not how a consumer sees it. Check each package dir for at least one of:

   - a `.apm/` directory (APM package layout) — for pure wrappers with no primitives of their own, an empty `.apm/.gitkeep` is sufficient and is the correct fix;
   - a `plugin.json` at root, `.github/plugin/`, `.claude-plugin/`, or `.cursor-plugin/` (plugin layout);
   - a root `SKILL.md` (Claude-skill layout).

   If none of the three is present, propose creating `.apm/.gitkeep` (or an appropriate primitive directory) and re-run validation. Do not mark the retrofit complete until this check passes.

3. **`apm install --dry-run`** — only if the `apm` CLI is available (`command -v apm`). Run from the repo root. On success, report "APM accepts this manifest." On failure, paste the error and propose a fix. If the error is `Missing required directory: .apm/` despite Check 2 passing at the root, the failure is in a transitively-depended-on subpath — surface the path and repeat Check 2 there.

Do **not** run `apm install` without `--dry-run`. Do **not** run `apm compile` — the user decides when to compile.

### 9. Follow-ups (optional, only if asked)

Suggest but do not execute:

- Adding an `apm.yml` entry to `.gitignore`-adjacent files if the repo ships release bundles.
- Adding a GitHub Actions workflow that runs `apm install --dry-run` on PRs (offer to draft it — do not write it unless asked).
- Adding a `version:` bump rule to the repo's contributing guide.

## Edge cases

- **Monorepo with multiple skills.** Emit a single `apm.yml` at the repo root. APM resolves each skill via virtual path (`apm install owner/repo/skill-name`) at install time — you do **not** need one manifest per skill, and writing several will confuse consumers. Under the APM-package layout each skill lives at `.apm/skills/<name>/SKILL.md`; APM deploys every one of them as a top-level entry keyed by frontmatter `name:`. Call this out in your report so the user understands the install URL shape.
- **Fork of an existing APM package.** If a valid upstream `apm.yml` exists, preserve it verbatim unless the user explicitly asks you to rewrite it. Bump the `version:` only if the user asks.
- **Repo with a single-file skill (root `SKILL.md` only).** Emit `type: skill` and a minimal manifest. Don't invent a `skills/` directory.
- **Repo with only `CLAUDE.md` / `AGENTS.md`.** Emit `type: instructions`. The instructions files are primitives in their own right.
- **Name collisions.** If the derived `name` clashes with a well-known APM package (check by asking the user, not by heuristics), suggest a prefixed alternative (e.g. `acme-<name>`).

## Output format

Your final message to the user must include, in order:

1. **Inventory** — bullet list of every primitive found, with paths.
2. **Layout decision** — one line: "Layout: `APM package` | `plugin` | `Claude skill`", plus the reason (e.g. "no `plugin.json` found → APM package").
3. **Proposed moves** — `git mv` block, or "No moves needed" if the current shape already matches.
4. **Classification** — one line: `type: X`, `target: Y`.
5. **Proposed manifest** — fenced YAML block.
6. **Diff against existing** — if relevant.
7. **Validation results** — YAML parse + dry-run status.
8. **Next step** — one sentence on what the user should do next (commit the moves and manifest, push, tag a release, install globally).

Keep the tone factual. No emojis, no marketing copy, no "this will transform your workflow" language. This is a tool for maintainers, not a pitch deck.
