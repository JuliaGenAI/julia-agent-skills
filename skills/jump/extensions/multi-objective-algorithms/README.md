# MultiObjectiveAlgorithms.jl (MOA)

A collection of algorithms for solving multi-objective optimization problems with JuMP.

- **Repository**: https://github.com/jump-dev/MultiObjectiveAlgorithms.jl
- **Docs**: Integrated in [JuMP documentation](https://jump.dev/JuMP.jl/stable/tutorials/linear/multi_objective_knapsack/)

## Installation

```julia
import Pkg
Pkg.add("MultiObjectiveAlgorithms")
```

## When to Use

- Your problem has **multiple competing objectives** (e.g., minimize cost AND maximize quality)
- You want to compute the **Pareto front** (set of non-dominated solutions)
- You need to explore **trade-offs** between objectives
- You want to solve a multi-objective problem using a **single-objective solver** (HiGHS, Gurobi, CPLEX, etc.)

## Setup Pattern

```julia
using JuMP
import HiGHS
import MultiObjectiveAlgorithms as MOA

model = Model(() -> MOA.Optimizer(HiGHS.Optimizer))
set_attribute(model, MOA.Algorithm(), MOA.EpsilonConstraint())
```

Replace `HiGHS.Optimizer` with any solver capable of solving a single-objective instance of your problem.

## Defining Multi-Objective Problems

Pass a **vector of scalar objectives** to `@objective`:

```julia
@variable(model, x[1:N], Bin)
@constraint(model, sum(weight[i] * x[i] for i in 1:N) <= capacity)

# Define two objectives as expressions
@expression(model, profit_expr, sum(profit[i] * x[i] for i in 1:N))
@expression(model, desire_expr, sum(desire[i] * x[i] for i in 1:N))

# Set vector-valued objective
@objective(model, Max, [profit_expr, desire_expr])
```

## Available Algorithms

| Algorithm | Restrictions | Description |
|---|---|---|
| `MOA.Lexicographic()` | Any (default) | Optimizes objectives in priority order |
| `MOA.Hierarchical()` | Any | Similar to Lexicographic with more control |
| `MOA.EpsilonConstraint()` | Exactly 2 objectives | Epsilon-constraint method for bi-objective |
| `MOA.Dichotomy()` | Exactly 2 objectives | Weighted-sum dichotomy for bi-objective |
| `MOA.Chalmet()` | Exactly 2 objectives | Chalmet's method for bi-objective |
| `MOA.Sandwiching()` | Any | Sandwiching algorithm |
| `MOA.RandomWeighting()` | Any | Random weight scalarization |
| `MOA.DominguezRios()` | Discrete variables only | For integer/binary problems |
| `MOA.KirlikSayin()` | Discrete variables only | For integer/binary problems |
| `MOA.TambyVanderpooten()` | Discrete variables only | For integer/binary problems |

```julia
# Set algorithm
set_attribute(model, MOA.Algorithm(), MOA.EpsilonConstraint())
```

## Optimizer Attributes

```julia
# Limit the number of Pareto solutions returned
set_attribute(model, MOA.SolutionLimit(), 10)

# Set time limit
set_attribute(model, MOI.TimeLimitSec(), 60.0)

# Control epsilon-constraint step size
set_attribute(model, MOA.EpsilonConstraintStep(), 0.5)

# Set objective priorities (for Lexicographic/Hierarchical)
set_attribute(model, MOA.ObjectivePriority(1), 2)  # higher = more important
set_attribute(model, MOA.ObjectivePriority(2), 1)

# Set objective weights (for RandomWeighting)
set_attribute(model, MOA.ObjectiveWeight(1), 0.7)
set_attribute(model, MOA.ObjectiveWeight(2), 0.3)

# Tolerances
set_attribute(model, MOA.ObjectiveAbsoluteTolerance(1), 1e-6)
set_attribute(model, MOA.ObjectiveRelativeTolerance(1), 1e-4)

# Enumerate all permutations in Lexicographic
set_attribute(model, MOA.LexicographicAllPermutations(), true)

# Silence inner solver output (keep MOA output)
set_attribute(model, MOA.SilentInner(), true)

# Disable ideal point computation (saves N solves)
set_attribute(model, MOA.ComputeIdealPoint(), false)
```

## Working with Multiple Solutions

Solutions are **lexicographically ordered** by objective vectors (first result is best).

```julia
optimize!(model)
assert_is_solved_and_feasible(model)

# How many Pareto-optimal solutions were found?
n_solutions = result_count(model)

# Access each solution
for i in 1:n_solutions
    println("Solution $i:")
    println("  Objective: ", objective_value(model; result = i))
    println("  x = ", value.(x; result = i))
end

# Access individual objective values
value(profit_expr; result = 3)
value(desire_expr; result = 3)

# Check feasibility of each solution
primal_status(model; result = 5)  # FEASIBLE_POINT

# Query ideal point (best achievable per objective independently)
ideal = objective_bound(model)
```

## Query Subproblem Count

```julia
# How many single-objective subproblems were solved?
n_sub = get_attribute(model, MOA.SubproblemCount())
```

## Complete Example: Bi-Objective Knapsack

```julia
using JuMP
import HiGHS
import MultiObjectiveAlgorithms as MOA

profit = [77, 94, 71, 63, 96, 82, 85, 75, 72, 91]
desire = [65, 90, 90, 77, 95, 84, 70, 94, 66, 92]
weight = [80, 87, 68, 72, 66, 77, 99, 85, 70, 93]
capacity = 500
N = length(profit)

model = Model(() -> MOA.Optimizer(HiGHS.Optimizer))
set_silent(model)
set_attribute(model, MOA.Algorithm(), MOA.EpsilonConstraint())

@variable(model, x[1:N], Bin)
@constraint(model, sum(weight[i] * x[i] for i in 1:N) <= capacity)
@objective(model, Max, [
    sum(profit[i] * x[i] for i in 1:N),
    sum(desire[i] * x[i] for i in 1:N),
])

optimize!(model)
assert_is_solved_and_feasible(model)

println("Found $(result_count(model)) Pareto-optimal solutions")
for i in 1:result_count(model)
    obj = objective_value(model; result = i)
    println("  Solution $i: profit=$(obj[1]), desire=$(obj[2])")
end
```

## Gotchas

- **Algorithm choice matters**: Some algorithms only work with 2 objectives; others work with any number but may be slower
- **Discrete-only algorithms**: `DominguezRios`, `KirlikSayin`, `TambyVanderpooten` require integer/binary variables
- **Solution ordering**: Results are lexicographically ordered by objective vector — first result is "best" in lexicographic sense
- **`result` keyword**: Always pass `result = i` when querying specific Pareto solutions (`value`, `objective_value`, `primal_status`)
- **Ideal point cost**: Computing the ideal point requires N additional solves (one per objective). Disable with `MOA.ComputeIdealPoint() = false` if not needed
- **No dual solutions**: `dual_status` is typically `NO_SOLUTION` for multi-objective results
