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

**GitHub Copilot in VS Code** (global, always enabled):

Clone this repo and symlink skills into your personal skills directory:

```sh
git clone https://github.com/JuliaGenAI/julia-agent-skills.git ~/dev/julia-agent-skills
mkdir -p ~/.copilot/skills
ln -s ~/dev/julia-agent-skills/skills/documenter-vitepress ~/.copilot/skills/documenter-vitepress
```

Copilot automatically discovers skills in `~/.copilot/skills/` and loads them when your prompt matches. To update, `git pull` in the cloned repo.

To add skills to a single repository instead, place them under `.github/skills/` in that repo.

## Available Skills

| Skill | Description |
|-------|-------------|
| [documenter-vitepress](skills/documenter-vitepress/) | Set up and develop Julia documentation sites with DocumenterVitepress.jl |
| [tachikoma](skills/tachikoma/) | Build rich, interactive terminal UI applications in Julia with Tachikoma.jl |

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

[MIT](LICENSE)
