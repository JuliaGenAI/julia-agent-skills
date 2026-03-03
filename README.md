# Julia Agent Skills

Community-maintained [Agent Skills](https://agentskills.io) for Julia development. Installable into Claude Code, Codex CLI, Cursor, Gemini CLI, Windsurf, and any tool supporting the Agent Skills standard.

## Install

**Claude Code** (plugin marketplace):

```
/plugin marketplace add JuliaGenAI/julia-agent-skills
/plugin install documenter-vitepress@julia-agent-skills
```

**Cross-tool** (npx skills):

```sh
npx skills add JuliaGenAI/julia-agent-skills
```

To install a specific skill:

```sh
npx skills add JuliaGenAI/julia-agent-skills --skill documenter-vitepress
```

**Using skild:**

```sh
skild install JuliaGenAI/julia-agent-skills
```

## Available Skills

| Skill | Description |
|-------|-------------|
| [documenter-vitepress](skills/documenter-vitepress/) | Set up and develop Julia documentation sites with DocumenterVitepress.jl |

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

[MIT](LICENSE)
