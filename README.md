# APM Flavour Packages

Composable `apm.yml` packages separated by concern. Pull in what you need per project.

## Packages

| Package | Concern | Always? |
|---|---|---|
| `global-core` | TDD, context engineering, prompt craft, research, debugging, runtime hooks | ✅ Yes |
| `code-core` | Architecture agents, API design quality gates | ✅ Yes |
| `code-python` | Python, FastMCP, pytest, debugging | Per stack |
| `code-go` | Go, go-sdk MCP, debugging | Per stack |
| `code-typescript` | TS/Node, React, NestJS, TS MCP SDK | Per stack |
| `agi-agents` | Agent swarms, orchestration, MCP builder, LangSmith | When building agents |
| `architect-dataops` | PostgreSQL, SQL, CSV analysis, data pipelines | When data-heavy |
| `architect-mlops` | LLM observability, eval pipelines, Arize | When ML involved |
| `architect-devops` | Docker, CI/CD, Terraform, incident triage | Most projects |
| `cloud-core` | Azure/AWS IaC, serverless, cost, cloud patterns | Cloud deployments |
| `uiux-design` | UI/UX, React design, theming, accessibility | Frontend projects |
| `plan-core` | PRD, requirements, epics, QA, task breakdown | Most projects |
| `plan-docs` | docx/pdf/pptx/xlsx, co-authoring, brand, comms | When producing docs |

## Usage

### Global install

Install `global-core` once — it provides universal skills (TDD, context engineering,
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

# Architecture & infrastructure
apm install thinkjones/awesome-everything/architect-devops
apm install thinkjones/awesome-everything/architect-dataops
apm install thinkjones/awesome-everything/architect-mlops
apm install thinkjones/awesome-everything/cloud-core

# Planning & design
apm install thinkjones/awesome-everything/plan-core
apm install thinkjones/awesome-everything/plan-docs
apm install thinkjones/awesome-everything/uiux-design

# Agents
apm install thinkjones/awesome-everything/agi-agents
```

### Pin to a version

```bash
apm install thinkjones/awesome-everything/global-core#v1.0.0
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
