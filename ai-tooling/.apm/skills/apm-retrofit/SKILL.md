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

### 2. Classify `type:`

Use the APM manifest schema v0.1 rules (see `https://microsoft.github.io/apm/reference/primitive-types/`):

| What you found | Proposed `type:` |
|----------------|------------------|
| Only `SKILL.md` files | `skill` |
| Only instructions files (`*.instructions.md`, `AGENTS.md`, `CLAUDE.md`) | `instructions` |
| Only prompts/commands | `prompts` |
| A mix of two or more of the above | `hybrid` |

If a `plugin.json` is present, you may omit `type:` and let APM infer it — but if you are confident, emit `hybrid` explicitly.

### 3. Detect `target:`

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

### 4. Derive the manifest fields

- `name` — kebab-case, lowercase, alphanumeric + hyphens. Source, in order: existing `apm.yml` → existing `plugin.json.name` → existing `package.json.name` → repo directory name. If the source string contains uppercase or underscores, convert to kebab-case.
- `version` — semver. Source, in order: existing `apm.yml.version` → existing `plugin.json.version` → existing `package.json.version` → latest git tag that parses as semver → `0.1.0`.
- `description` — one sentence, ≤160 chars. Source, in order: existing manifest → README first paragraph → SKILL.md description field → synthesised from `name`.
- `author` — `git config user.name` if not already set.
- `license` — read from `LICENSE`/`LICENSE.txt`/`package.json.license` if unambiguous; omit otherwise.

### 5. Enumerate dependencies

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

If you cannot find any dependencies, emit `dependencies: {apm: []}` or omit the section entirely — both are valid. Do **not** invent dependencies.

### 6. Propose, diff, confirm, write

Before writing anything:

1. Render the proposed `apm.yml` to the user in a fenced code block.
2. If an `apm.yml` already exists, show a unified diff between the existing file and your proposal. Highlight fields that changed and fields the user might want to keep (e.g. a hand-written description).
3. List every primitive you found and how APM will see it after install. Example:
   ```
   Found 3 primitives:
     - skills/pdf-generator/SKILL.md       → installs as skill `pdf-generator`
     - agents/code-reviewer.agent.md       → installs as agent `code-reviewer`
     - .github/instructions/style.md       → installs as instruction `style`
   ```
4. Ask the user to confirm ("Write this `apm.yml`?") and only then use `Write` to create or replace the file.

### 7. Validate

After writing, do two checks — in this order, and report results:

1. **YAML syntax** — parse the file with `python3 -c "import yaml; yaml.safe_load(open('apm.yml'))"`. If it fails, the skill has produced invalid YAML; stop and fix before anything else.
2. **`apm install --dry-run`** — only if the `apm` CLI is available (`command -v apm`). Run from the repo root. On success, report "APM accepts this manifest." On failure, paste the error and propose a fix.

Do **not** run `apm install` without `--dry-run`. Do **not** run `apm compile` — the user decides when to compile.

### 8. Follow-ups (optional, only if asked)

Suggest but do not execute:

- Adding an `apm.yml` entry to `.gitignore`-adjacent files if the repo ships release bundles.
- Adding a GitHub Actions workflow that runs `apm install --dry-run` on PRs (offer to draft it — do not write it unless asked).
- Adding a `version:` bump rule to the repo's contributing guide.

## Edge cases

- **Monorepo with multiple skills.** Emit a single `apm.yml` at the repo root. APM resolves each skill via virtual path (`apm install owner/repo/skill-name`) at install time — you do **not** need one manifest per skill, and writing several will confuse consumers. Call this out in your report so the user understands the install URL shape.
- **Fork of an existing APM package.** If a valid upstream `apm.yml` exists, preserve it verbatim unless the user explicitly asks you to rewrite it. Bump the `version:` only if the user asks.
- **Repo with a single-file skill (root `SKILL.md` only).** Emit `type: skill` and a minimal manifest. Don't invent a `skills/` directory.
- **Repo with only `CLAUDE.md` / `AGENTS.md`.** Emit `type: instructions`. The instructions files are primitives in their own right.
- **Name collisions.** If the derived `name` clashes with a well-known APM package (check by asking the user, not by heuristics), suggest a prefixed alternative (e.g. `acme-<name>`).

## Output format

Your final message to the user must include, in order:

1. **Inventory** — bullet list of every primitive found, with paths.
2. **Classification** — one line: `type: X`, `target: Y`.
3. **Proposed manifest** — fenced YAML block.
4. **Diff against existing** — if relevant.
5. **Validation results** — YAML parse + dry-run status.
6. **Next step** — one sentence on what the user should do next (commit, push, publish, compile).

Keep the tone factual. No emojis, no marketing copy, no "this will transform your workflow" language. This is a tool for maintainers, not a pitch deck.
