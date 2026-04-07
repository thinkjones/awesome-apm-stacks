# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

awesome-everything is a collection of composable **APM (Agent Package Manager) flavour packages** — YAML manifests that declare dependencies on skills, agents, hooks, and instructions for AI-assisted development. There is no application code; this is a configuration-and-template repository.

## Key Commands

```bash
apm install          # Install dependencies declared in apm.yml
apm compile          # Generate AGENTS.md + CLAUDE.md from dependencies
agentrc              # Generate project-specific .instructions.md from codebase analysis
```

There is no build step, test suite, or linter. Changes are validated by reviewing the YAML manifests.

## Architecture

### Package Layout

Each top-level directory is a standalone flavour package containing a single `apm.yml` manifest:

| Directory | Package Name | Concern |
|-----------|-------------|---------|
| `code-core/` | apm-core | Engineering fundamentals (TDD, BDD, DRY, YAGNI, security hooks) — pulled into every project |
| `code-python/` | apm-python | Python, FastMCP, pytest |
| `code-go/` | apm-go | Go, go-sdk MCP |
| `code-typescript/` | apm-typescript | TS/Node, React, NestJS |
| `ai-agents/` | apm-agents | Agent orchestration, MCP builder, LangSmith |
| `ai-mlops/` | apm-mlops | LLM observability, eval pipelines, Arize |
| `architect-devops/` | apm-devops | Docker, CI/CD, Terraform, incident triage |
| `architect-dataops/` | apm-dataops | PostgreSQL, SQL, data pipelines |
| `cloud-core/` | apm-cloud | Azure/AWS IaC, serverless, cost optimization |
| `plan-core/` | apm-planning | PRD, requirements, epics, QA |
| `plan-docs/` | apm-docs | docx/pdf/pptx/xlsx generation, co-authoring |
| `uiux-design/` | apm-design | UI/UX, React design, theming, accessibility |

### Dependency Sources

Each `apm.yml` declares dependencies from external registries:
- `github/awesome-copilot/` — agents, plugins, instructions, skills
- `anthropics/skills/` — official Anthropic skills (skill-creator, mcp-builder, claude-api)
- `obra/superpowers` — TDD/dev workflow (20+ skills)
- `mattpocock/skills` — PRD, TDD, architecture, git guardrails
- `ComposioHQ/awesome-claude-skills/` — community skills
- Runtime hooks: `nizarselander/tdd-guard`, `dmytro-onypko/parry`

### Examples

`examples/` contains two reference project configurations showing how to compose packages:
- `fullstack-saas/` — Go API + React frontend + ML features (10 packages)
- `python-saas/` — LangGraph news digest SaaS with Python agents (7 packages)

## Working in This Repo

- Each package is independent. Edit one `apm.yml` without affecting others.
- The naming convention maps directory names to package names: `code-core/` -> `apm-core`, `ai-agents/` -> `apm-agents`, etc.
- When adding a new dependency, include a comment explaining its purpose (see existing `apm.yml` files for the pattern).
- When creating a new package, follow the existing structure: one directory with a single `apm.yml` containing name, version, description, and dependencies.
