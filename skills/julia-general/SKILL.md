---
name: julia-general
description: >
  Use when working with any Julia code, package, or project. This is the foundational Julia
  development skill — it covers documentation lookup, package management rules, running Julia
  correctly, coding conventions, and project layout. Triggers on any Julia development task
  including writing Julia code, managing dependencies, creating packages, debugging, or
  modifying Project.toml/Manifest.toml files. Use this skill even if a more specialized Julia
  skill also applies — it provides the base layer of correct practices.
---

# Julia General Development

Foundational practices for all Julia development work. Follow these rules regardless of what
specific library or domain you're working in.

## Looking Up Documentation

When you need to check how a function, type, or module works, query the built-in docs rather
than guessing. Julia ships comprehensive docstrings for the standard library and most packages
expose them too.

**From the command line:**

```bash
julia -e 'using REPL; using MyPackage; println(Base.doc(MyPackage.myfunc))'
```

**From a Julia session or MCP eval tool:**

```julia
using REPL
using MyPackage
println(Base.doc(MyPackage.myfunc))   # print docstring for a function
println(Base.doc(MyPackage.MyType))   # print docstring for a type
```

**Discovering what's available:**

```julia
names(MyPackage)                      # exported names
methods(myfunc)                       # all methods of a function
methodswith(MyType)                   # methods that accept a type
```

Use whichever Julia evaluation method is available — `julia -e`, a REPL, or an MCP Julia
eval tool. The pattern is the same: `using REPL; using ThePackage; Base.doc(ThePackage.thething)`.

## Package Management Rules

**Always use Pkg.jl APIs** for dependency operations. Never manually edit `Project.toml` for
adding, removing, or versioning dependencies.

```julia
using Pkg
Pkg.add("PackageName")                          # add a dependency
Pkg.rm("PackageName")                           # remove a dependency
Pkg.develop(path="./LocalPkg")                  # dev a local package
Pkg.compat("PackageName", "1.2")                # set compat bounds
Pkg.update("PackageName")                       # update a package
Pkg.pin("PackageName")                          # pin to current version
Pkg.free("PackageName")                         # unpin or exit dev mode
Pkg.status()                                    # show installed packages
```

**Exceptions — you MAY manually edit Project.toml** for these sections only:
- `[extensions]` — defining package extensions
- `[sources]` — custom package sources
- `[workspace]` — workspace configuration
- `[targets]` — test targets (legacy, prefer test/Project.toml)

For a fully annotated example of every Project.toml section, see `references/project-toml-reference.toml`.

**Prefer test/Project.toml over [extras]:**

Instead of listing test dependencies in the main `Project.toml` under `[extras]` + `[targets]`,
create a separate `test/Project.toml` and add a workspace entry:

```toml
# In the root Project.toml, add:
[workspace]
projects = ["test"]
```

Then manage test deps in `test/`:

```julia
Pkg.activate("test")
Pkg.add(["Test", "Aqua"])
Pkg.develop(path=pwd())   # add the parent package
```

**Speed up Pkg operations** by disabling automatic precompilation:

```julia
ENV["JULIA_PKG_PRECOMPILE_AUTO"] = "0"
```

Set this early in your Julia session (before Pkg operations) to avoid waiting for
precompilation after every `add`/`rm`/`update`. You can precompile explicitly later
with `Pkg.precompile()` when ready.

## Running Julia

This is **only** for if you are running Julia through the CLI.  If using some kind of MCP server, it will likely handle this for you, or you can use Pkg API operations.

Always activate the local environment:

```bash
julia --project=.                # activate Project.toml in current dir
julia --project=docs             # activate docs subproject
julia --project=test             # activate test subproject
```

Use available threads:

```bash
julia -tauto --project=.         # use all available CPU threads
```

Key environment variables:

| Variable | Purpose | Example |
|----------|---------|---------|
| `JULIA_PROJECT` | Default project to activate | `@.` (find nearest Project.toml) |
| `JULIA_NUM_THREADS` | Thread count | `auto` |
| `JULIA_PKG_PRECOMPILE_AUTO` | Auto-precompile on Pkg ops | `0` to disable |
| `JULIA_DEBUG` | Enable @debug logging for a module | `MyPackage` or `all` |

## Coding Conventions

**Naming:**
- `snake_case` for functions and variables
- `CamelCase` for types and modules
- `!` suffix for functions that mutate their first argument (e.g., `push!`, `sort!`)
- `Abstract` prefix for abstract types (e.g., `AbstractArray`)

**Imports:**
- `using PackageName` — brings exported names into scope (most common)
- `import PackageName: specific_func` — import only specific names
- `using PackageName: PackageName` — load without importing exports (access via `PackageName.func`)

**Style:**
- Prefer `using` for packages you consume broadly
- Prefer `import` when you're extending (adding methods to) another package's functions
- Use `const` for global bindings that don't change value

## Project Layout

Standard Julia package structure:

```
MyPackage.jl/
├── Project.toml              # package metadata + dependencies
├── src/
│   └── MyPackage.jl          # main module file
├── test/
│   ├── Project.toml          # test-specific dependencies
│   └── runtests.jl           # test entry point
├── docs/
│   ├── Project.toml          # docs-specific dependencies
│   ├── make.jl               # Documenter build script
│   └── src/                  # documentation source files
├── ext/                      # package extensions (optional)
├── README.md
└── LICENSE
```

**Module structure** (src/MyPackage.jl):

```julia
module MyPackage

export public_function, PublicType

include("types.jl")
include("core.jl")
include("utils.jl")

end # module
```
