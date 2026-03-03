---
name: documenter-vitepress
description: Use when setting up or developing a Julia documentation site with DocumenterVitepress.jl. Triggers when working with Documenter.jl + VitePress, creating make.jl for docs, setting up Julia package documentation, or building organization landing pages. Also use when the user mentions DocumenterVitepress, VitePress for Julia docs, or wants to preview docs locally with hot reload.
---

# DocumenterVitepress.jl

DocumenterVitepress.jl builds Julia documentation sites using Documenter.jl's content pipeline with VitePress (a Vue-powered static site generator) as the frontend. It produces modern static sites with search, dark mode, and responsive layout. Since VitePress runs on Vue, you can add custom Vue components to your docs for interactive content.

## Setup

Setup is minimal — DocumenterVitepress manages all VitePress/npm machinery (package.json, node_modules, .vitepress config, theme files) automatically. You only need to:

1. **Add Julia deps** to your Project.toml (or `docs/Project.toml` for package repos):
   ```
   pkg> add Documenter DocumenterVitepress
   ```

2. **Write `make.jl`** using `DocumenterVitepress.MarkdownVitepress` as the format and `deploydocs` for deployment.

3. **Write your `src/` content** — markdown files, with VitePress frontmatter wrapped in `` ```@raw html `` blocks.

4. **Add `.gitignore` entries**: `Manifest.toml`, `build/`, `node_modules/`, `package-lock.json`

5. **Add CI workflow** — standard `julia-actions/julia-docdeploy@v1` GitHub Action (requires `DOCUMENTER_KEY` secret via `DocumenterTools.genkeys()`).

See `setup-reference.md` in this skill directory for complete templates (make.jl variants, index.md hero pattern, CI workflow YAML).

### Custom package.json

Do NOT add a `package.json` unless you need custom JavaScript dependencies. DocumenterVitepress provides its own default and manages npm install/build automatically.

If you DO provide your own `package.json` (for custom VitePress plugins, etc.), you take on npm management yourself — you must run `npm install` manually before `dev_docs()` or any local builds. This is because `dev_docs()` only auto-installs npm deps when it had to supply a default `package.json`.

## Local Development Workflow

The fast iteration loop has two stages: (1) run `makedocs` to convert source markdown, (2) run VitePress dev server to preview.

### Step 1: Set `build_vitepress = false` in make.jl

```julia
format = DocumenterVitepress.MarkdownVitepress(
    # ... other options ...
    build_vitepress = false,
),
```

This makes `makedocs` only emit markdown to `build/.documenter/` without invoking npm/VitePress — much faster for iteration.

### Step 2: Run makedocs

```julia
include("make.jl")
```

Or from shell: `julia --project=. -e 'include("make.jl")'` (use `--project=docs` for package repos).

### Step 3: Start the dev server (background process)

**`dev_docs` blocks forever** — it runs the VitePress dev server as a long-running process. You must run it in a non-blocking way:

**From shell (recommended):** Run as a background process via the Bash tool with `run_in_background: true`:
```bash
julia --project=. -e 'using DocumenterVitepress; DocumenterVitepress.dev_docs("build")'
```

**From Julia REPL/MCP:** Use `Threads.@spawn` so it doesn't block:
```julia
using DocumenterVitepress
Threads.@spawn DocumenterVitepress.dev_docs("build")
```

For **package repos**, the path is `"docs/build"` instead of `"build"`.

The server starts at `http://localhost:5173/` with hot reload.

**Gotcha:** `dev_docs` expects the **build directory** path, not `build/.documenter`. It appends `/.documenter` internally. Passing `build/.documenter` produces `build/.documenter/.documenter` and a 404.

### Step 4: Edit-rebuild-preview cycle

1. Edit files in `src/`
2. Re-run `include("make.jl")`
3. Kill the dev server process and restart it
4. Browser refreshes automatically

### Teardown

Remove `build_vitepress = false` (or set it to `true`) before committing, so CI builds the full site.

## Two Repo Layouts

**Package docs** (most common): docs in `docs/` inside a Julia package repo. Use `--project=docs`, path `"docs/build"`.

**Standalone site** (org landing pages): docs at repo root. Use `--project=.`, path `"build"`, and `modules = Module[]` in makedocs.

See `setup-reference.md` for complete make.jl templates for both layouts.

## What DocumenterVitepress Manages Automatically

These are auto-generated if not present — you don't need to create them:
- `package.json` (npm dependencies including vitepress)
- `.vitepress/config.mts` (sidebar, navbar, search)
- `.vitepress/theme/` (index.ts, style.css, docstrings.css)
- `.vitepress/mathjax-plugin.ts`
- `components/VersionPicker.vue`

Only provide custom versions to override defaults (e.g., custom colors, extra VitePress plugins).

### Customizing the theme or adding Vue components

If you want to add custom Vue components or modify the theme, you must provide the **full set** of theme files — DocumenterVitepress only auto-generates files that are missing, so once you provide any custom theme file, you need to populate all required files:

- `src/.vitepress/theme/index.ts` — theme entry point that registers Vue components
- `src/.vitepress/theme/style.css` — custom CSS
- `src/.vitepress/theme/docstrings.css` — docstring block styling

Start by copying the defaults from DocumenterVitepress's template (or run `DocumenterVitepress.generate_template()`), then modify. Your `index.ts` must import and register any custom Vue components you add.

The same "you own it" principle from `package.json` applies: once you provide custom `.vitepress/` files, you're responsible for keeping them compatible with DocumenterVitepress updates.
