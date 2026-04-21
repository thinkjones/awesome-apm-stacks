# ai-tooling

Meta-tooling for APM package authors — retrofit existing skills/plugins/agents repos into APM-compliant packages, scaffold manifests, and audit compliance.

## Install

```bash
apm install thinkjones/awesome-apm-stacks/ai-tooling
```

## Why this package exists

Microsoft APM ships `apm init`, but it is deliberately minimal — it drops a stub `apm.yml` with auto-detected `name`/`author`/`version` and nothing else. It does not scan your repo for existing primitives (SKILL.md, plugin.json, AGENTS.md, MCP servers, hooks, commands, agents) or infer the right `target:` / `type:` for you.

If you maintain a skills repo, a Copilot plugin, a Claude plugin, or any other agent-facing bundle and want to make it installable via `apm install owner/repo`, you currently have to hand-write the manifest and wire up the primitives yourself. This package fills that gap.

## Skills

| Skill | What it does |
|-------|--------------|
| [`apm-retrofit`](skills/apm-retrofit/SKILL.md) | Walks the current repo, classifies every primitive it finds (SKILL.md, plugin.json, `.github/`, `.claude/`, `.cursor/`, MCP manifests, hooks, commands, agents, instructions), auto-detects `target:` and `type:`, and emits a correctly-shaped `apm.yml` at the repo root. Handles monorepos with multiple skills. |

## Usage

Once installed, invoke the skill from inside the repo you want to convert:

```
/apm-retrofit
```

The skill inspects the working directory, reports what it found, proposes an `apm.yml`, and — with your approval — writes it. It never deletes existing files and never overwrites an existing `apm.yml` silently; conflicts are surfaced as a diff for you to resolve.

## References

- [APM manifest schema v0.1](https://microsoft.github.io/apm/reference/manifest-schema/)
- [APM primitive types](https://microsoft.github.io/apm/reference/primitive-types/)
- [APM skills guide](https://microsoft.github.io/apm/guides/skills/)
- [APM plugins guide](https://microsoft.github.io/apm/guides/plugins/)
- [Agent Skills standard](https://agentskills.io)
