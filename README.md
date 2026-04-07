# APM Flavour Packages

Composable `apm.yml` packages separated by concern. Pull in what you need per project.

## Packages

| Package | Concern | Always? |
|---|---|---|
| `apm-core` | TDD/BDD/DRY/YAGNI, architecture agents, security hooks | ✅ Yes |
| `apm-python` | Python, FastMCP, pytest, debugging | Per stack |
| `apm-go` | Go, go-sdk MCP, debugging | Per stack |
| `apm-typescript` | TS/Node, React, NestJS, TS MCP SDK | Per stack |
| `apm-agents` | Agent swarms, orchestration, MCP builder, LangSmith | When building agents |
| `apm-dataops` | PostgreSQL, SQL, CSV analysis, data pipelines | When data-heavy |
| `apm-mlops` | LLM observability, eval pipelines, Arize | When ML involved |
| `apm-devops` | Docker, CI/CD, Terraform, incident triage | Most projects |
| `apm-cloud` | Azure/AWS IaC, serverless, cost, cloud patterns | Cloud deployments |
| `apm-design` | UI/UX, React design, theming, accessibility | Frontend projects |
| `apm-planning` | PRD, requirements, epics, QA, task breakdown | Most projects |
| `apm-docs` | docx/pdf/pptx/xlsx, co-authoring, brand, comms | When producing docs |

## Usage

Each package is a standalone Git repo. In your project:

```yaml
# apm.yml
name: my-project
version: 1.0.0

dependencies:
  apm:
    - your-org/apm-core
    - your-org/apm-python
    - your-org/apm-agents
```

Then:

```bash
apm install
apm compile    # generates AGENTS.md + CLAUDE.md
```

## Setup

1. Create a GitHub repo per package (e.g. `your-org/apm-core`)
2. Drop the `apm.yml` into the root
3. Tag releases: `git tag v1.0.0 && git push --tags`
4. Pin versions in consuming projects: `your-org/apm-core#v1.0.0`

## Global installs

Skills you want everywhere (not per-project):

```bash
apm install -g obra/superpowers
apm install -g mattpocock/skills
apm install -g anthropics/skills/skills/skill-creator
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
