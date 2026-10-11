# workflows

Task-shaped APM bundles. A stack groups primitives by *concern* (testing, security, a language). A workflow groups the skills and MCP servers needed to carry out one *job* end to end.

| Workflow | What it sets up |
| --- | --- |
| [`website-ui-ux-with-stitch`](website-ui-ux-with-stitch/) | Website UI/UX design with Google Stitch — design skills, React component generation, brand voice, and the Stitch and Magic MCP servers. |

## website-ui-ux-with-stitch

```bash
apm install thinkjones/awesome-apm-stacks/workflows/website-ui-ux-with-stitch
apm compile
```

### Skills

| Dependency | Source repo |
| --- | --- |
| ui-ux-pro-max-skill | [nextlevelbuilder/ui-ux-pro-max-skill](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill) |
| stitch-design | [google-labs-code/stitch-skills](https://github.com/google-labs-code/stitch-skills) |
| react-components | [google-labs-code/stitch-skills](https://github.com/google-labs-code/stitch-skills) |
| brand-voice | [anthropics/knowledge-work-plugins](https://github.com/anthropics/knowledge-work-plugins) |

### MCP servers

Both run locally over stdio through `npx`, so Node.js must be installed.

| Name in `apm.yml` | Package |
| --- | --- |
| `filesystem` | `@_davideast/stitch-mcp` |
| `magic` | `@21st-dev/magic` |

Check each package's documentation for any credentials it requires.
