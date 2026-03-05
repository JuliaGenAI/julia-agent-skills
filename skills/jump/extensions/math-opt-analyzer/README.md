# MathOptAnalyzer.jl

Analysis and debugging tools for JuMP models. Detects numerical issues, verifies solution feasibility, and diagnoses infeasibility.

- **Repository**: https://github.com/jump-dev/MathOptAnalyzer.jl
- **Docs**: https://jump.dev/MathOptAnalyzer.jl/stable/

## Installation

```julia
import Pkg
Pkg.add("MathOptAnalyzer")
```

## When to Use

- Your model returns unexpected results and you suspect **numerical issues** (large/small coefficients, poor scaling)
- You want to **verify solution feasibility** including primal, dual, and complementary slackness
- Your model is **infeasible** and you need to find the **minimal infeasible subset** (IIS)
- You want to audit a model before sending it to a solver
- You're working with a model file (MPS/LP) from an external source

## Three Analysis Modes

### 1. Numerical Analysis

Checks for numerical issues in the model structure (before or after solving):

```julia
using JuMP, MathOptAnalyzer, HiGHS

model = Model(HiGHS.Optimizer)
@variable(model, x >= 0)
@variable(model, y >= 0)
@constraint(model, 2x + 3y == 5)
@objective(model, Min, x + y)
optimize!(model)

# Analyze numerical properties
data = MathOptAnalyzer.analyze(MathOptAnalyzer.Numerical.Analyzer(), model)
MathOptAnalyzer.summarize(data)
```

Detects:
- Large and small coefficients
- Empty constraints
- Non-convex quadratic functions
- Poor coefficient scaling

### 2. Feasibility Analysis

Given an optimized model (or candidate solution), verifies feasibility and optimality:

```julia
data = MathOptAnalyzer.analyze(MathOptAnalyzer.Feasibility.Analyzer(), model)
MathOptAnalyzer.summarize(data)
```

Checks:
- Primal feasibility
- Dual feasibility (if available)
- Complementary slackness conditions (if applicable)

### 3. Infeasibility Analysis

Diagnoses why a model is infeasible:

```julia
data = MathOptAnalyzer.analyze(
    MathOptAnalyzer.Infeasibility.Analyzer(),
    model,
    optimizer = HiGHS.Optimizer,  # needed for IIS computation
)
MathOptAnalyzer.summarize(data)
```

Three-step process:
1. **Bounds consistency**: checks variable bounds, integer/binary consistency
2. **Constraint propagation**: propagates bounds through individual constraints to find isolated infeasibilities
3. **IIS computation**: finds a minimal Irreducible Infeasible Subsystem (only if steps 1-2 find no issues)

## Common Options

```julia
# Suppress detailed output
data = MathOptAnalyzer.analyze(analyzer, model; verbose = false)

# Limit the number of reported issues per type
data = MathOptAnalyzer.analyze(analyzer, model; max_issues = 10)
```

## Writing Reports to File

```julia
open("my_report.txt", "w") do io
    MathOptAnalyzer.summarize(io, data)
end
```

## Programmatic Inspection

After analysis, drill into specific issues:

```julia
# List types of issues found
issue_types = MathOptAnalyzer.list_of_issue_types(data)

# Get info about a specific issue type
MathOptAnalyzer.summarize(issue_types[1])

# Get all issues of that type
issues = MathOptAnalyzer.list_of_issues(data, issue_types[1])

# Inspect individual issues
MathOptAnalyzer.summarize(issues[1])
```

## Analyzing Non-JuMP Models

Read from MPS or LP files:

```julia
model = read_from_file("model.mps")
data = MathOptAnalyzer.analyze(MathOptAnalyzer.Numerical.Analyzer(), model)
MathOptAnalyzer.summarize(data)
```

## Typical Debugging Workflow

```julia
using JuMP, MathOptAnalyzer, HiGHS

model = Model(HiGHS.Optimizer)
# ... build model ...
optimize!(model)

if termination_status(model) == OPTIMAL
    # Verify the solution is truly feasible
    data = MathOptAnalyzer.analyze(MathOptAnalyzer.Feasibility.Analyzer(), model)
    MathOptAnalyzer.summarize(data)
elseif termination_status(model) == INFEASIBLE
    # Find the cause of infeasibility
    data = MathOptAnalyzer.analyze(
        MathOptAnalyzer.Infeasibility.Analyzer(),
        model,
        optimizer = HiGHS.Optimizer,
    )
    MathOptAnalyzer.summarize(data)
else
    # Check for numerical issues
    data = MathOptAnalyzer.analyze(MathOptAnalyzer.Numerical.Analyzer(), model)
    MathOptAnalyzer.summarize(data)
end
```

## Gotchas

- **Experimental package**: API may change between versions
- **IIS requires an optimizer**: Pass `optimizer = SolverName.Optimizer` to `Infeasibility.Analyzer` — it runs additional solves internally
- **Not a solver**: MathOptAnalyzer analyzes models, it does not solve them
- **Post-solve analysis**: Feasibility analysis requires the model to have been solved first (or a candidate solution to be set)
