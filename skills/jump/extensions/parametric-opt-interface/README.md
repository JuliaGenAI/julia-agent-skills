# ParametricOptInterface.jl

Efficient parametric optimization for JuMP — update parameters and re-solve without rebuilding the model.

- **Repository**: https://github.com/jump-dev/ParametricOptInterface.jl
- **Docs**: https://jump.dev/ParametricOptInterface.jl/stable/

## Installation

```julia
import Pkg
Pkg.add("ParametricOptInterface")
```

## When to Use

- You need to solve the **same model structure** many times with different data (e.g., rolling horizon, scenario analysis)
- Parameters appear in **objective coefficients**, **constraint RHS**, or as **constraint coefficients**
- You want to avoid the overhead of rebuilding the model from scratch each time
- You need the **dual of a parameter** (sensitivity of objective w.r.t. parameter)
- Parameters multiply **quadratic terms** in the objective (cubic expressions like `p * x^2` where `p` is a parameter)

## Setup Pattern

```julia
using JuMP, HiGHS
import ParametricOptInterface as POI

# Wrap any solver with POI.Optimizer
model = Model(() -> POI.Optimizer(HiGHS.Optimizer))
```

## Core API

### Declaring Parameters

Parameters are declared as JuMP variables with the `Parameter` set:

```julia
@variable(model, p in Parameter(initial_value))
```

Parameters can appear in constraints and objectives alongside decision variables:

```julia
@variable(model, x)
@variable(model, p in Parameter(1.0))
@constraint(model, p * x + p >= 3)  # p as coefficient AND additive term
@objective(model, Min, 2x + p)
```

### Updating and Re-solving

```julia
optimize!(model)
value(x)  # query solution

# Update the parameter value and re-solve (no model rebuild)
set_parameter_value(p, 2.0)
optimize!(model)
value(x)  # new solution with updated parameter
```

### Querying Parameter Duals

When a parameter appears **additively** (not as a coefficient), you can query its dual:

```julia
@variable(model, p in Parameter(1.0))
@constraint(model, x + p >= 3)  # p is additive
@objective(model, Min, 2x)
optimize!(model)
dual(VariableInSetRef(p))  # sensitivity of objective w.r.t. p
```

> **Note**: Dual queries require the parameter to appear only additively. If the parameter is multiplicative (e.g., `p * x`), the dual is not available. Also, not all solvers support parameter duals (e.g., Ipopt does not).

### Parameters Multiplying Quadratic Terms

POI supports cubic polynomial expressions of the form `c * p * x * y` in objectives, where `c` is a number, `p` is a parameter, and `x`, `y` are variables. After parameter substitution, the objective becomes quadratic.

```julia
@variable(model, 0 <= x <= 10)
@variable(model, p in Parameter(2.0))
@objective(model, Min, p * x^2 - 3x)  # cubic term: p * x^2
optimize!(model)
value(x)  # x = 3 / (2p) = 0.75

set_parameter_value(p, 3.0)
optimize!(model)
value(x)  # x = 3 / (2p) = 0.5
```

> **Constraint**: Maximum polynomial degree is 3. At least one factor in each cubic term must be a parameter. Pure cubic variable terms (e.g., `x * y * z`) are not supported.

## Variable Bounds Interpretation

When a constraint like `x >= p` involves a parameter, POI can interpret it as either an affine constraint or a variable bound. Control this with `ConstraintsInterpretation`:

```julia
# Default: treat as affine constraint (adds a row to the constraint matrix)
set_attribute(model, POI.ConstraintsInterpretation(), POI.ONLY_CONSTRAINTS)

# Treat as variable bound when possible (more efficient for some solvers)
set_attribute(model, POI.ConstraintsInterpretation(), POI.BOUNDS_AND_CONSTRAINTS)
```

## Common Patterns

### Parametric Sensitivity Study

```julia
using JuMP, HiGHS
import ParametricOptInterface as POI

model = Model(() -> POI.Optimizer(HiGHS.Optimizer))
set_silent(model)
@variable(model, x >= 0)
@variable(model, demand in Parameter(100.0))
@constraint(model, x >= demand)
@objective(model, Min, 2x)

results = Dict{Float64, Float64}()
for d in 50:10:200
    set_parameter_value(demand, d)
    optimize!(model)
    results[d] = objective_value(model)
end
```

### Multiple Parameters

```julia
@variable(model, cost in Parameter(1.0))
@variable(model, capacity in Parameter(100.0))
@variable(model, demand[i=1:N] in Parameter.(demands))

# Update a vector of parameters
for i in 1:N
    set_parameter_value(demand[i], new_demands[i])
end
optimize!(model)
```

## Gotchas

- **Solver compatibility**: Works with any MOI-compatible solver, but dual queries may not be supported by all solvers
- **Multiplicative parameters**: When `p * x` appears in constraints, dual queries for `p` are not available
- **Maximum degree 3**: Cubic terms in objectives require at least one parameter factor
- **Re-solve efficiency**: The primary benefit is avoiding model reconstruction; the solver may still need significant time depending on warm-start support
