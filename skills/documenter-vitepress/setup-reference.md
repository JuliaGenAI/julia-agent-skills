# DocumenterVitepress Setup Reference

Complete templates for setting up DocumenterVitepress.jl in different repo layouts.

## make.jl — Package Docs

For a Julia package where docs live in `docs/`:

```julia
using MyPackage
using Documenter, DocumenterVitepress

makedocs(;
    modules = [MyPackage],
    authors = "Your Name",
    repo = "https://github.com/Org/MyPackage.jl",
    sitename = "MyPackage.jl",
    format = DocumenterVitepress.MarkdownVitepress(
        repo = "https://github.com/Org/MyPackage.jl",
        devbranch = "main",
        devurl = "dev",
    ),
    pages = [
        "Home" => "index.md",
    ],
    warnonly = true,
)

deploydocs(;
    repo = "github.com/Org/MyPackage.jl",
    push_preview = true,
)
```

## make.jl — Standalone Site

For an organization landing page or standalone documentation site with a custom domain:

```julia
using Documenter, DocumenterVitepress

makedocs(;
    modules = Module[],
    authors = "Org Contributors",
    repo = "https://github.com/Org/org.github.io",
    sitename = "OrgName",
    format = DocumenterVitepress.MarkdownVitepress(
        repo = "https://github.com/Org/org.github.io",
        devbranch = "master",
        devurl = "dev",
        deploy_url = "orgname.org",
    ),
    pages = [
        "Home" => "index.md",
    ],
    warnonly = true,
)

deploydocs(;
    repo = "github.com/Org/org.github.io",
    devbranch = "master",
    push_preview = true,
)
```

Key differences from package docs: `modules = Module[]`, no `using MyPackage`, and `deploy_url` set to the custom domain.

## src/index.md — VitePress Hero Page

VitePress frontmatter must be wrapped in `` ```@raw html `` blocks. This is how Documenter passes raw content through to VitePress:

```markdown
` ` `@raw html
---
layout: home

hero:
  name: "SiteName"
  text: "Tagline"
  tagline: A longer description
  image:
    src: /logo.svg
    alt: Logo
  actions:
    - theme: brand
      text: Get Started
      link: /getting_started
    - theme: alt
      text: View on GitHub
      link: https://github.com/Org

features:
  - title: Feature One
    details: Description of feature one.
    link: https://example.com
  - title: Feature Two
    details: Description of feature two.
---
` ` `

## Section heading

Regular markdown content goes here, outside the raw block.
```

Note: the triple backticks above have spaces for escaping — in real files they have no spaces.

## .gitignore

```
Manifest.toml
build/
node_modules/
package-lock.json
```

## GitHub Actions CI

```yaml
name: Documenter
on:
  push:
    branches: [master]  # or main
    tags: ['*']
  pull_request:
  workflow_dispatch:

permissions:
  contents: write
  pages: write
  id-token: write
  statuses: write

concurrency:
  group: pages
  cancel-in-progress: false

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: julia-actions/setup-julia@v2
      - uses: julia-actions/cache@v2
        id: julia-cache
      - uses: julia-actions/julia-docdeploy@v1
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          DOCUMENTER_KEY: ${{ secrets.DOCUMENTER_KEY }}
      - if: cancelled() || failure()
        uses: actions/cache/save@v4
        with:
          path: ${{ steps.julia-cache.outputs.cache-paths }}
          key: ${{ steps.julia-cache.outputs.cache-key }}
```

Requires a `DOCUMENTER_KEY` secret, generated via `DocumenterTools.genkeys("Org/repo")`.

## Assets

Place images and static files in `src/` — they get copied to the build output. Reference them with a leading `/` in VitePress frontmatter (e.g., `/logo.svg`). Logo and favicon can be placed in `src/assets/` as `logo.png` and `favicon.ico` for automatic pickup.
