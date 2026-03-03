# Contributing to Julia Agent Skills

Skill authors should be able to contribute by reading just this file.

## Quick Start

1. Fork this repository
2. Create `skills/<your-skill-name>/SKILL.md` (see format below)
3. Add a row for your skill to the Available Skills table in `README.md`
4. Open a pull request — CI validates automatically

That's it. No build step, no dependencies to install.

## Skill Format

Each skill lives in its own directory under `skills/`:

```
skills/
  my-skill/
    SKILL.md              # Required
    references/           # Optional: supporting docs, long reference material
    scripts/              # Optional: helper scripts
    assets/               # Optional: templates, data files
```

The only required file is `SKILL.md`. Everything else is optional and can be structured however makes sense for your skill.

## SKILL.md Format

`SKILL.md` is a Markdown file with a YAML frontmatter block at the top:

```markdown
---
name: my-skill
description: Use when setting up X or working with Y. Triggers on Z.
---

# My Skill

Guidance, examples, and reference material for the AI agent go here.
```

The frontmatter fields `name` and `description` are required. No other frontmatter fields are recognized — CI will reject unknown fields.

The body is plain Markdown. Write it for an AI agent that will read it and act on it, not for human readers browsing GitHub.

## Naming Rules

The directory name and the `name` frontmatter field must match exactly, and must follow these rules:

- Lowercase letters (`a-z`), numbers (`0-9`), and hyphens (`-`) only
- No consecutive hyphens (`--`)
- Cannot start or end with a hyphen
- Maximum 64 characters

Examples of valid names: `documenter-vitepress`, `pkg-benchmark`, `makie-plots`

Examples of invalid names: `MySkill` (uppercase), `-my-skill` (leading hyphen), `my--skill` (consecutive hyphens)

## Writing a Good Description

The description field is how the AI agent decides whether to load your skill for a given task. Write it to answer: "when should this skill activate?"

Rules:
- Maximum 1024 characters
- Describe **when** the skill should activate, not just what it does
- Include trigger keywords: package names, file patterns, common phrases the user might type

Good example:
```
Use when setting up or developing a Julia documentation site with DocumenterVitepress.jl.
Triggers when working with Documenter.jl + VitePress, creating make.jl for docs, setting up
Julia package documentation, or building organization landing pages. Also use when the user
mentions DocumenterVitepress, VitePress for Julia docs, or wants to preview docs locally
with hot reload.
```

Weak example (avoid):
```
Helps with documentation.
```

## Writing Good Skill Instructions

**Keep SKILL.md under 500 lines.** If you have lengthy reference material (full file templates, exhaustive API tables, long configuration examples), put it in `references/` and link to it from SKILL.md. Agents load SKILL.md into context; `references/` is consulted on demand.

**Be Julia-specific.** Generic advice wastes context. Assume the agent knows how to write code — tell it the Julia-specific things it won't know: which package to use, what the common pitfalls are, what commands to run, what the idiomatic approach looks like.

**Include working examples with copy-pasteable code.** Prefer concrete examples over prose descriptions. If the agent can copy a snippet and run it, do that.

**Call out gotchas explicitly.** If there's a common mistake or a non-obvious behavior, say so directly. The `documenter-vitepress` skill does this well: it explicitly flags that `dev_docs` blocks forever and what path argument it expects.

**Structure internals however you like.** Use headers, lists, code blocks, whatever makes the instructions clear. The agent reads it all.

## Updating the Catalog

Add a row to the Available Skills table in `README.md`:

```markdown
| [my-skill](skills/my-skill/) | One-line description of what it helps with |
```

Keep the description short — one sentence is enough. The full description is in SKILL.md.

## CI Validation

Pull requests are automatically validated. CI checks:

- `SKILL.md` exists in the skill directory
- Frontmatter is valid YAML and contains both `name` and `description`
- `name` follows the naming conventions above
- No unknown frontmatter fields are present
- The directory name matches the `name` field

Fix any CI failures before requesting review. The error messages describe exactly what went wrong.
