# APM Flavour Packages

Composable `apm.yml` packages separated by concern. Pull in what you need per project.

All dependencies must come from repos with 1,000+ GitHub stars.

## Packages

| Package | Concern | Always? |
|---|---|---|
| `global-core` | TDD, context engineering, prompt craft, research, debugging, runtime hooks | Yes |
| `code-core` | Architecture agents, API design quality gates | Yes |
| `code-python` | Python, FastMCP, pytest, debugging | Per stack |
| `code-go` | Go, go-sdk MCP, debugging | Per stack |
| `code-typescript` | TS/Node, React, NestJS, TS MCP SDK | Per stack |
| `code-java` | Java, Spring Boot, Maven/Gradle, Java MCP servers | Per stack |
| `code-rust` | Rust, systems programming, cargo, Rust MCP servers | Per stack |
| `code-csharp` | C#/.NET, ASP.NET, C# MCP servers | Per stack |
| `code-mobile` | Flutter/Dart, Swift, Kotlin, mobile MCP servers | Per stack |
| `agi-agents` | Agent swarms, orchestration, MCP builder, LangSmith | When building agents |
| `architect-dataops` | PostgreSQL, SQL, CSV analysis, data pipelines | When data-heavy |
| `architect-mlops` | LLM observability, eval pipelines, Arize | When ML involved |
| `architect-devops` | Docker, CI/CD, Terraform, incident triage | Most projects |
| `cloud-core` | Azure/AWS IaC, serverless, cost, cloud patterns | Cloud deployments |
| `security-core` | OWASP, secure coding, vulnerability scanning, agent safety | Most projects |
| `test-core` | E2E, integration testing, Playwright, polyglot test agents | Most projects |
| `uiux-design` | UI/UX, React design, theming, accessibility | Frontend projects |
| `plan-core` | PRD, requirements, epics, QA, task breakdown | Most projects |
| `plan-docs` | docx/pdf/pptx/xlsx, co-authoring, brand, comms | When producing docs |
| `business-core` | Business workflow tooling | When needed |

## Dependency Sources

| Repo | Stars | Used By |
|------|-------|---------|
| [obra/superpowers](https://github.com/obra/superpowers) | 140,069 | global-core |
| [anthropics/skills](https://github.com/anthropics/skills) | 112,647 | agi-agents, global-core, plan-docs, test-core, uiux-design |
| [ComposioHQ/awesome-claude-skills](https://github.com/ComposioHQ/awesome-claude-skills) | 51,995 | architect-dataops, business-core, code-python |
| [github/awesome-copilot](https://github.com/github/awesome-copilot) | 28,886 | agi-agents, architect-dataops, architect-devops, architect-mlops, cloud-core, code-core, code-csharp, code-go, code-java, code-mobile, code-python, code-typescript, global-core, plan-core, security-core, test-core, uiux-design |
| [vercel-labs/agent-skills](https://github.com/vercel-labs/agent-skills) | 24,689 | uiux-design |
| [anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official) | 16,304 | global-core |
| [vercel-labs/skills](https://github.com/vercel-labs/skills) | 13,312 | global-core |
| [mattpocock/skills](https://github.com/mattpocock/skills) | 13,003 | global-core, plan-core |
| [nizos/tdd-guard](https://github.com/nizos/tdd-guard) | 1,970 | global-core |
| [supabase/agent-skills](https://github.com/supabase/agent-skills) | 1,849 | architect-dataops, cloud-core, code-python |

## Usage

### Global install

Install `global-core` once -- it provides universal skills (TDD, context engineering,
prompt craft, research, debugging, hooks) that apply to every project:

```bash
apm install -g thinkjones/awesome-everything/global-core
```

### Per-project install

Add only the packages you need:

```yaml
# apm.yml
name: my-project
version: 1.0.0

dependencies:
  apm:
    - thinkjones/awesome-everything/code-core
    - thinkjones/awesome-everything/code-python
    - thinkjones/awesome-everything/agi-agents
```

Then:

```bash
apm install
apm compile    # generates AGENTS.md + CLAUDE.md
```

### Install individual packages directly

```bash
# Stack-specific
apm install thinkjones/awesome-everything/code-python
apm install thinkjones/awesome-everything/code-go
apm install thinkjones/awesome-everything/code-typescript
apm install thinkjones/awesome-everything/code-java
apm install thinkjones/awesome-everything/code-rust
apm install thinkjones/awesome-everything/code-csharp
apm install thinkjones/awesome-everything/code-mobile

# Architecture & infrastructure
apm install thinkjones/awesome-everything/architect-devops
apm install thinkjones/awesome-everything/architect-dataops
apm install thinkjones/awesome-everything/architect-mlops
apm install thinkjones/awesome-everything/cloud-core

# Security & testing
apm install thinkjones/awesome-everything/security-core
apm install thinkjones/awesome-everything/test-core

# Planning & design
apm install thinkjones/awesome-everything/plan-core
apm install thinkjones/awesome-everything/plan-docs
apm install thinkjones/awesome-everything/uiux-design

# Agents
apm install thinkjones/awesome-everything/agi-agents

# Business
apm install thinkjones/awesome-everything/business-core
```

### Pin to a version

```bash
apm install thinkjones/awesome-everything/global-core#v1.0.0
```

## Testing

```bash
./scripts/test-packages.sh --ci
```

## After install

Run `agentrc` to generate project-specific `.instructions.md` from your
actual codebase. Add your own `coding-principles.instructions.md` for
TDD/BDD/DRY/YAGNI enforcement:

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
