# awesome-apm-stacks

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![APM Packages](https://img.shields.io/badge/APM_Packages-20-green.svg)](#packages)
[![Curated Sources](https://img.shields.io/badge/Curated_Sources-10-orange.svg)](#dependency-sources)

## Overview

### What is APM?

[APM (Agent Package Manager)](https://microsoft.github.io/apm/) is Microsoft's open-source dependency manager for AI coding agents — think `npm` for everything that configures an AI agent. You declare what you want in an `apm.yml`, and APM resolves, fetches, and wires it into whatever AI tool you're using.

### Why APM?

AI dev tooling is the Wild West, and APM is the only credible attempt at a cross-agent dependency manager. Composable flavour packages mean you pull in only what each project needs.

### Why "awesome-apm-stacks"?

A demo repo that highlights the composability of APM stacks across different software engineering use cases. Every dependency is sourced from a repo with 1,000+ GitHub stars.

## AI dev tooling is still the Wild West

Every coding agent has its own way to load context. Claude Code reads `CLAUDE.md` and `.claude/`. Copilot reads `AGENTS.md` and `.github/`. Cursor reads `.cursorrules` and `.cursor/`. OpenCode wants `.opencode/`. The format you wrote your team's coding standards in last month may not be the format your team is using next month.

Meanwhile, the artifacts engineers actually want — TDD enforcers, code reviewers, security scanners, MCP integrations, slash-command libraries — live scattered across hundreds of GitHub repos, each in its own bespoke layout, each tied to one runtime. Want the same `code-reviewer` agent in Claude Code *and* Cursor? You're rewriting it twice. Want to switch agents next quarter? Start over.

**APM solves this with author-once, compile-anywhere.** Write or import a primitive once in the format the open spec defines — [Agent Skills](https://agentskills.io) for skills (now adopted by 30+ agent products including Claude Code, Cursor, Copilot, Gemini CLI, Codex, OpenCode, Goose, and more), [AGENTS.md](https://agents.md) for instructions (stewarded by the [Linux Foundation's Agentic AI Foundation](https://lfprojects.org)), [MCP](https://modelcontextprotocol.io) for tool servers — declare it in `apm.yml`, and `apm compile` emits the right shape for whichever agent you're targeting today. Switch runtimes tomorrow without rewriting a line.

The standards are still emerging — there isn't yet one canonical format for everything an AI agent needs. APM doesn't try to invent one; it just packages whatever follows the open specs that *do* exist. **As long as your skill, agent, hook, or instruction is in the standard format, APM will package it and emit it for any runtime that supports that spec.** No lock-in to APM's view of the world, no betting on a single vendor's bet.

## APM (Agent Package Manager)

[APM (Agent Package Manager)](https://microsoft.github.io/apm/) is Microsoft's open-source dependency manager for AI coding agents — think `npm` for everything that configures an AI agent. You declare what you want in an `apm.yml`, and APM resolves, fetches, and wires it into whatever AI tool you're using.

### What APM manages

Today, configuring an AI coding agent is a manual mess: skills go in one folder, agents in another, hooks in a config file, instructions in `CLAUDE.md` or `AGENTS.md` or `.cursorrules`. APM gives all of these a single home and a single install command.

| Primitive | What it is | When it's loaded | Example |
| --- | --- | --- | --- |
| **Instructions** | Rules and conventions that shape every response — coding style, project context, hard constraints. | Once at session start, persists in the agent's system context for the whole conversation. | "Use TDD. Validate inputs at boundaries. Never log secrets." |
| **Skills** | Bundled capabilities following Anthropic's [Agent Skills](https://agentskills.io) standard — progressive disclosure keeps your context window lean. | Skill *names* are visible at session start; the full skill body loads only when the agent decides it's relevant. | A `pdf-generator` skill that loads only when someone asks for a PDF. |
| **Agents** | Specialised sub-agents with their own scoped tools, prompts, and context window. | On-demand — invoked as a tool call by the main agent (or directly by the user). Their context isn't shared with the parent. | A `code-reviewer` agent that runs after edits, or a `tdd-guide` agent for new features. |
| **Hooks** | Shell commands triggered by lifecycle events (pre-tool, post-tool, on-stop) — enforced by the harness, not the agent. | Around every tool call or session event. Never enters the agent's context window — they just run. | Block `git push --force` on `main`, or run the formatter after every edit. |
| **MCP servers** | External tool servers via the [Model Context Protocol](https://modelcontextprotocol.io) — give the agent typed access to APIs, databases, file systems. | Tool definitions registered at session start; tool *responses* arrive per-call, only when the agent invokes one. | A Postgres MCP server that lets the agent run read-only SQL against staging. |
| **Prompts** | Reusable slash commands — parameterised templates you invoke with `/name`. | Only when the user explicitly invokes them — never automatically. | `/review-pr 1234` expands into a structured PR-review prompt. |
| **Plugins** | Bundles that group several of the above into one installable unit. | Per the primitives inside. | A `pr-review-toolkit` plugin shipping a code-reviewer agent + commit hooks + a `/review-pr` prompt. |

### How APM actually works

It's a two-step model:

1. `apm install` — fetches packages and caches them in `apm_modules/` (per-project) or `~/.apm/` (user/global)
2. `apm compile` — turns those staged assets into the single instruction file your AI agent actually reads (`CLAUDE.md`, `AGENTS.md`, `.cursor/`, `.copilot/` — whatever your tool needs)

### APM Scopes

APM has **two native scopes** (user and project), plus two workflow patterns most teams build on top:

| Scope | How | Where it lands | When to use |
| --- | --- | --- | --- |
| **User (global)** | `apm install -g <pkg>` | Cache: `~/.apm/` · Primitives: `~/.claude/`, `~/.copilot/`, `~/.cursor/`, `~/.config/opencode/` | Your personal toolkit — universals you want on *every* project (e.g. `user-core`). |
| **Project** | `apm install` from a project root with an `apm.yml` | Cache: `./apm_modules/` (gitignored) · Primitives: `./.claude/`, `./.github/`, etc. | Stack- and team-specific deps that ship with the repo. Every clone gets the same setup. |
| **Organisational** | Publish an internal APM package (e.g. `acme-corp/standards`) and list it in each project's `apm.yml` | Pulled in *as a project dep* — but maintained centrally and versioned across the org | Company-wide engineering standards, internal review checklists, security policies. |
| **Temporary** | `apm install <pkg>` in a throwaway dir or git worktree without committing | Local only, never reaches the project's `apm.yml` | Trying a package out before committing, or running a one-off task with extra skills. |

Local files always win: anything in your project overrides what's installed, and project-scope deps override user-scope deps with the same name.

### Team Process Support — why this is a big deal

- **Reproducible across teammates** — `git clone && apm install` and every developer gets the exact same agent setup. No more "works on my machine" for AI tooling.
- **Portable across runtimes** — switch from Claude Code to Copilot to Cursor without rewriting a single skill. Same `apm.yml`, re-compile, done.
- **Composable** — small focused packages combine via transitive deps, just like npm. Pull in only what each project needs.
- **Versioned** — pin exact versions, lock files, audit history. Treat agent config like real software.
- **Secure by default** — `apm install` scans for hidden Unicode and compromised packages before your agent ever reads them.

## Why awesome-apm-stacks?

APM is the engine. **awesome-apm-stacks** is the curated, ready-to-use library of packages built on top of it.

- **Battle-tested sources only** — every dependency is sourced from a repo with **1,000+ GitHub stars** (most have 10K+, some over 100K). No homemade scripts, no abandoned forks.
- **Opinionated bundles, not a buffet** — packages are organised by *concern* (TDD, security, devops, UI design) so you install what your project actually needs, not the kitchen sink.
- **Composable by design** — start with `user-core` for universal skills, layer `code-core` for engineering quality gates, then add language stacks (`code-python`, `code-go`) and domain bundles (`security-core`, `architect-cloud`) per project.
- **Transparent and forkable** — every package is a single 30-line `apm.yml` you can read in seconds. Comment out a dep you don't want, fork a package for your team, build your own — it's all just YAML.
- **One source of truth, every AI runtime** — pair APM's compile step with awesome-apm-stacks's curation and you get a coding standard library that follows you across Claude Code, Copilot, Cursor, OpenCode, and whatever ships next.

## Installation

### 1. Install Microsoft APM first

```bash
# macOS / Linux
curl -sSL https://aka.ms/apm-unix | sh

# or via Homebrew
brew install microsoft/apm/apm
```

See the [APM docs](https://microsoft.github.io/apm/) or [GitHub repo](https://github.com/microsoft/apm) for more.

### 2. Install `user-core` — your personal toolkit for every project, coding or not

Install `user-core` once and every project on your machine gets the universals (skill discovery, doublecheck verification, devil's-advocate review, claude-md management, ralph-loop):

```bash
apm install -g thinkjones/awesome-apm-stacks/user-core
```

**Where it lands:** packages cached at `~/.apm/`; primitives deployed to `~/.claude/`, `~/.copilot/`, etc. — picked up by every project on your machine. (See [APM Scopes](#apm-scopes) above for the full picture.)

### 3. Project-scope install — pick the stacks needed per repo

Add the packages this specific project needs to its `apm.yml`:

```yaml
# apm.yml
name: my-project
version: 1.0.0

dependencies:
  apm:
    - thinkjones/awesome-apm-stacks/code-core
    - thinkjones/awesome-apm-stacks/code-python
    - thinkjones/awesome-apm-stacks/ai-agents
```

Then install:

```bash
apm install
```

**Where it lands:** packages cached at `./apm_modules/` (gitignored — like `node_modules/`); primitives staged into `.claude/`, `.github/`, `.cursor/`, `.opencode/` — whichever your project uses. Every teammate who clones the repo and runs `apm install` gets the exact same setup.

> **Going organisational?** Wrap your team's choices in your own internal package (e.g. `acme-corp/standards`) that depends on awesome-apm-stacks packages plus your private skills. Every project's `apm.yml` then just lists `acme-corp/standards` — one line, fully versioned.

> Pin to a specific version: `apm install thinkjones/awesome-apm-stacks/code-core#v1.0.0`

### 4. Compile for your agent

Install only stages raw assets. **Compile** is what turns them into the single instruction file your AI agent actually reads:

```bash
apm compile
```

**What it generates:**

- `AGENTS.md` — for Copilot / VS Code / OpenCode
- `CLAUDE.md` — for Claude Code
- Plus target-specific config in `.github/`, `.claude/`, etc.

APM auto-detects which agent you're using based on the folders in your repo and emits the right format. **Switch tools without rewriting a single skill** — change agents, re-run `apm compile`, done.

This is the payoff of the install→compile split: one `apm.yml` is portable across every AI runtime that exists today, and every one that ships next year.

### 5. After install

Run `agentrc` to generate project-specific `.instructions.md` from your actual codebase. Add your own `coding-principles.instructions.md` for TDD/BDD/DRY/YAGNI enforcement:

```markdown
# .github/instructions/coding-principles.instructions.md
---
applyTo: "**/*.py,**/*.go,**/*.ts"
---
- TDD: Write failing test first. No production code without a test.
- BDD: Use Given/When/Then for acceptance criteria.
- DRY: Extract shared logic. Flag duplication in review.
- YAGNI: Do not build speculative features.
- Single Responsibility: One reason to change per module/function.
- Fail fast: Validate inputs at boundaries. Return errors early.
```

## Packages

The 20 packages below are **one developer's opinion** of how to slice the AI-coding-agent space into composable APM bundles — they're meant to be *illustrative* of what's possible, not definitive. Your idea of a good package layout might look very different, and that's exactly the point: APM lets a thousand opinionated bundles bloom.

| Package | Concern | When to Use |
| --- | --- | --- |
| [`user-core`](user-core/) | Context engineering, skill discovery, hallucination verification, devil's-advocate review, CLAUDE.md management, recurring task automation | Every project |
| [`code-core`](code-core/) | TDD enforcement, code review, PR review toolkit, git/commit workflows, semantic code search (serena), feature-dev, API architecture | Every coding project |
| [`code-python`](code-python/) | Python, FastMCP, pytest, debugging | Per stack |
| [`code-go`](code-go/) | Go, go-sdk MCP, debugging | Per stack |
| [`code-typescript`](code-typescript/) | TS/Node, React, NestJS, TS MCP SDK | Per stack |
| [`code-java`](code-java/) | Java, Spring Boot, Maven/Gradle, Java MCP servers | Per stack |
| [`code-rust`](code-rust/) | Rust, systems programming, cargo, Rust MCP servers | Per stack |
| [`code-csharp`](code-csharp/) | C#/.NET, ASP.NET, C# MCP servers | Per stack |
| [`code-mobile`](code-mobile/) | Flutter, Swift, Kotlin, mobile MCP servers | Per stack |
| [`ai-agents`](ai-agents/) | Agent swarms, orchestration, MCP builder, LangGraph/LangChain observability | When building agents |
| [`architect-dataops`](architect-dataops/) | PostgreSQL, SQL, CSV analysis, data pipelines | When data-heavy |
| [`architect-mlops`](architect-mlops/) | LLM observability, eval pipelines, Arize | When ML involved |
| [`architect-devops`](architect-devops/) | Docker, CI/CD, Terraform, incident triage | Most projects |
| [`architect-cloud`](architect-cloud/) | Azure/AWS IaC, serverless, cost optimization | Cloud deployments |
| [`security-core`](security-core/) | OWASP, secure coding, vulnerability scanning, agent safety | Most projects |
| [`test-core`](test-core/) | E2E, integration testing, Playwright, polyglot test agents | Most projects |
| [`design-frontend`](design-frontend/) | UI/UX, React design, theming, accessibility | Frontend projects |
| [`plan-core`](plan-core/) | PRD, requirements, epics, QA, task breakdown | Most projects |
| [`plan-docs`](plan-docs/) | docx/pdf/pptx/xlsx, co-authoring, brand, comms | When producing docs |
| [`business-core`](business-core/) | Business workflow tooling | When needed |

Each package is opinionated but practical — they co-locate related skills and agents, making them easy to install and share across teams. Open any package's `apm.yml` to comment out individual dependencies you don't need.

> **Got a different take?** Strong opinions on what belongs where? Built a package for a domain not covered here — game dev, embedded, scientific computing, fintech, anything? **Open a pull request** ([see Contributing](#contributing)). I'd genuinely love to see how other people slice this, and the whole point of APM is that there shouldn't be one canonical answer.

### Browse individual packages

Pick and install any package on its own — useful for trying a stack out before adding it to `apm.yml`:

```bash
# Language stacks
apm install thinkjones/awesome-apm-stacks/code-python
apm install thinkjones/awesome-apm-stacks/code-go
apm install thinkjones/awesome-apm-stacks/code-typescript
apm install thinkjones/awesome-apm-stacks/code-java
apm install thinkjones/awesome-apm-stacks/code-rust
apm install thinkjones/awesome-apm-stacks/code-csharp
apm install thinkjones/awesome-apm-stacks/code-mobile

# Architecture & infrastructure
apm install thinkjones/awesome-apm-stacks/architect-devops
apm install thinkjones/awesome-apm-stacks/architect-dataops
apm install thinkjones/awesome-apm-stacks/architect-mlops
apm install thinkjones/awesome-apm-stacks/architect-cloud

# Security & testing
apm install thinkjones/awesome-apm-stacks/security-core
apm install thinkjones/awesome-apm-stacks/test-core

# Planning & design
apm install thinkjones/awesome-apm-stacks/plan-core
apm install thinkjones/awesome-apm-stacks/plan-docs
apm install thinkjones/awesome-apm-stacks/design-frontend

# Agents & business
apm install thinkjones/awesome-apm-stacks/ai-agents
apm install thinkjones/awesome-apm-stacks/business-core
```

### Customizing Packages

Every package is just a YAML file listing dependencies. To tailor one for your team:

1. Fork or copy the package directory
2. Open `apm.yml` and comment out (or remove) dependencies you don't want
3. Add any additional dependencies your team needs
4. Share the customized package across your org

### Build Your Own

Create internal APM packages that compose awesome-apm-stacks packages with your own org-specific standards:

```yaml
# my-team-standards/apm.yml
name: my-team-standards
version: 1.0.0
description: Internal coding standards for Acme Corp

dependencies:
  apm:
    - thinkjones/awesome-apm-stacks/user-core
    - thinkjones/awesome-apm-stacks/code-typescript
    - thinkjones/awesome-apm-stacks/security-core
    # Add your own internal skills:
    # - your-org/internal-skills/api-conventions
    # - your-org/internal-skills/review-checklist
```

Your team gets a single `apm install` that sets up all coding standards, agents, and hooks.

### Full Stack Examples

Two reference projects showing how to compose packages for real-world stacks:

- [`examples/fullstack-saas/`](examples/fullstack-saas/) — Go API + React frontend + ML features (composes 10 packages)
- [`examples/python-saas/`](examples/python-saas/) — LangGraph news digest SaaS with Python agents (composes 7 packages)

Each example is a working `apm.yml` you can use as a starting point for your own project.

## Dependency Sources

All dependencies are drawn from high-quality, well-maintained repositories:

| Source | Stars | Used By |
| --- | --- | --- |
| [obra/superpowers](https://github.com/obra/superpowers) | 140K+ | [`user-core`](user-core/) |
| [anthropics/skills](https://github.com/anthropics/skills) | 112K+ | [`ai-agents`](ai-agents/), [`user-core`](user-core/), [`plan-docs`](plan-docs/), [`test-core`](test-core/), [`design-frontend`](design-frontend/) |
| [ComposioHQ/awesome-claude-skills](https://github.com/ComposioHQ/awesome-claude-skills) | 51K+ | [`architect-dataops`](architect-dataops/), [`business-core`](business-core/), [`code-python`](code-python/) |
| [github/awesome-copilot](https://github.com/github/awesome-copilot) | 28K+ | [`ai-agents`](ai-agents/), [`architect-dataops`](architect-dataops/), [`architect-devops`](architect-devops/), [`architect-mlops`](architect-mlops/), [`architect-cloud`](architect-cloud/), [`code-core`](code-core/), [`code-csharp`](code-csharp/), [`code-go`](code-go/), [`code-java`](code-java/), [`code-mobile`](code-mobile/), [`code-python`](code-python/), [`code-typescript`](code-typescript/), [`user-core`](user-core/), [`plan-core`](plan-core/), [`security-core`](security-core/), [`test-core`](test-core/), [`design-frontend`](design-frontend/) |
| [vercel-labs/agent-skills](https://github.com/vercel-labs/agent-skills) | 24K+ | [`design-frontend`](design-frontend/) |
| [anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official) | 16K+ | [`user-core`](user-core/) |
| [vercel-labs/skills](https://github.com/vercel-labs/skills) | 13K+ | [`user-core`](user-core/) |
| [mattpocock/skills](https://github.com/mattpocock/skills) | 13K+ | [`user-core`](user-core/), [`plan-core`](plan-core/) |
| [nizos/tdd-guard](https://github.com/nizos/tdd-guard) | 1.9K+ | [`user-core`](user-core/) |
| [supabase/agent-skills](https://github.com/supabase/agent-skills) | 1.8K+ | [`architect-dataops`](architect-dataops/), [`architect-cloud`](architect-cloud/), [`code-python`](code-python/) |

## Testing

The test suite validates every APM package manifest in the repository.

### What it validates

1. **YAML syntax** — each `apm.yml` is parsed with `python3`/`pyyaml` to catch syntax errors
2. **Dependency resolution** — `apm install --dry-run` verifies all declared dependencies can be resolved (skipped if `apm` CLI is not installed)

### Run locally

Test all packages:

```bash
./scripts/test-packages.sh
```

Test specific packages:

```bash
./scripts/test-packages.sh code-python code-go
```

CI mode (no colours, same exit-code behaviour — used by GitHub Actions):

```bash
./scripts/test-packages.sh --ci
./scripts/test-packages.sh --ci code-python code-go
```

> **Note:** The script requires `python3` with the `pyyaml` package (`pip install pyyaml`).
> If the `apm` CLI is not installed, dry-run checks are skipped with a warning.

### CI

Tests run automatically via GitHub Actions (`.github/workflows/test-packages.yml`):

- **On push to main** — tests only the packages whose files changed
- **Daily (6 AM UTC)** — runs all package tests if there were commits in the last 24 hours, or on Mondays as a weekly sweep
- **Manual** — trigger from the Actions tab; optionally specify packages

## About this Repo

### Contributing

Pull requests are welcome — especially new packages for under-served domains.

- Follow existing structure: one directory, one `apm.yml`, one `README.md`
- All dependencies must come from repos with 1,000+ GitHub stars
- Run `./scripts/test-packages.sh --ci` before submitting
- **Bump the `version:` in every package you touch** (see [Versioning](#versioning))
- Open an issue first if you want to discuss a new package idea

### Versioning

Each package carries its own semver in `apm.yml`. When you change files inside a package directory, you must bump that package's version in the same PR — CI rejects PRs that modify a package without a version bump.

Pick the bump type yourself:

- **Patch** (`0.1.3 → 0.1.4`) — bug fix, doc tweak, no behaviour change for consumers
- **Minor** (`0.1.3 → 0.2.0`) — additive change (new dep, new primitive, additional option)
- **Major** (`0.1.3 → 1.0.0`) — breaking change (removed dep, renamed primitive, incompatible option)

Helper script:

```bash
./scripts/bump-version.sh ai-agents patch
./scripts/bump-version.sh code-python minor
./scripts/bump-version.sh architect-cloud major
```

On merge to `main`, the release workflow detects each package whose version increased and publishes a tag + GitHub Release automatically. No bot commits touch `main`, so `git pull` always fast-forwards.

### A note on `docs/internal/`

`docs/internal/` is a [git submodule](https://git-scm.com/book/en/v2/Git-Tools-Submodules) pointing at a private repo that holds archived design briefs. Cloning this repo leaves the path empty — that's expected and nothing you need for contributing or using the packages. Ignore it and carry on.

### Author

**Gene Conroy-Jones** — PhD in Civil Engineering (Cardiff University). Startup CTO across 7 startups at seed through Series B, including 2 acquisitions (Salesforce, Stanley Black & Decker) and raising $35M in Series B funding. Now focused on AI transformation of engineering organisations.

Blog: [foursignals.dev](https://foursignals.dev)

Open to full-time roles, fractional CTO engagements, and advisory positions — [get in touch](https://foursignals.dev).

### License

MIT — see [LICENSE](LICENSE) for details.
