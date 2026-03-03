# DiffOpt.jl

Differentiate convex and non-convex optimization programs with respect to problem parameters. Enables embedding optimization layers in machine learning pipelines and performing sensitivity analysis.

- **Repository**: https://github.com/jump-dev/DiffOpt.jl
- **Docs**: https://jump.dev/DiffOpt.jl/stable/

## Installation

```julia
import Pkg
Pkg.add("DiffOpt")
```

## When to Use

- You need **derivatives of optimal solutions** with respect to problem data (objectives, constraints, RHS)
- Embedding an optimization layer inside a **neural network** or ML pipeline
- **Sensitivity analysis**: how do solution variables change when problem parameters shift?
- **End-to-end differentiable systems**: combining optimization with automatic differentiation
- Bilevel optimization or game-theoretic applications requiring gradient information

## Supported Problem Types

| Backend | Problem Types |
|---|---|
| QuadraticProgram | LP, convex QP |
| ConicProgram | LP, SOCP, SDP (with bridges: RotatedSOC, PSD square) |
| NonlinearProgram | LP, QP, NLP (via JuMP `Parameter` API) |

## Setup Pattern

### With JuMP (recommended for NLP)

```julia
using JuMP, DiffOpt, Ipopt

model = Model(() -> DiffOpt.diff_optimizer(Ipopt.Optimizer))
set_silent(model)
```

### With MOI directly (for QP/Conic)

```julia
import DiffOpt, HiGHS

model = DiffOpt.diff_optimizer(HiGHS.Optimizer)
```

### Selecting a Backend

```julia
# Explicitly choose the differentiation backend
set_attribute(model, DiffOpt.ModelConstructor, DiffOpt.QuadraticProgram.Model)
# or
set_attribute(model, DiffOpt.ModelConstructor, DiffOpt.ConicProgram.Model)
```

## Core API: Forward Mode

Forward mode computes how solution variables change given perturbations in problem parameters.

**Direction**: parameter perturbation → solution perturbation

### For NLP with JuMP Parameters

```julia
using JuMP, DiffOpt, Ipopt

model = Model(() -> DiffOpt.diff_optimizer(Ipopt.Optimizer))
set_silent(model)

@variable(model, x)
@variable(model, p in Parameter(4.0))
@variable(model, pc in Parameter(2.0))
@constraint(model, pc * x >= 3 * p)
@objective(model, Min, x^4)
optimize!(model)

# Set perturbation direction for parameter p
direction_p = 3.0
MOI.set(model, DiffOpt.ForwardConstraintSet(), ParameterRef(p), Parameter(direction_p))

# Compute forward derivatives
DiffOpt.forward_differentiate!(model)

# Query: how does x change with respect to perturbation in p?
dx_dp = MOI.get(model, DiffOpt.ForwardVariablePrimal(), x)
```

### For Conic Programs (MOI-level)

```julia
import LinearAlgebra: ⋅

# Set perturbation in objective function
MOI.set(model, DiffOpt.ForwardObjectiveFunction(), ones(2) ⋅ x)

DiffOpt.forward_differentiate!(model)
grad_x = MOI.get.(model, DiffOpt.ForwardVariablePrimal(), x)
```

## Core API: Reverse Mode

Reverse mode computes how problem parameters should change given a desired perturbation in solution variables.

**Direction**: solution perturbation → parameter perturbation

### For QP/Conic (MOI-level)

```julia
# Set desired perturbation in solution variables
MOI.set.(model, DiffOpt.ReverseVariablePrimal(), x, ones(2))

DiffOpt.reverse_differentiate!(model)

# Query gradient of objective and constraints
grad_obj = MOI.get(model, DiffOpt.ReverseObjectiveFunction())
grad_con = MOI.get.(model, DiffOpt.ReverseConstraintFunction(), c)
```

### For NLP with Parameters

```julia
# Set desired perturbation in solution
direction_x = 10.0
MOI.set(model, DiffOpt.ReverseVariablePrimal(), x, direction_x)

DiffOpt.reverse_differentiate!(model)

# Query how parameters should change
dp = MOI.get(model, DiffOpt.ReverseConstraintSet(), ParameterRef(p))
```

## Objective Sensitivity (NLP only)

Compute how the optimal objective value changes with respect to parameter perturbations:

```julia
# Forward: set parameter perturbation, then query objective sensitivity
DiffOpt.empty_input_sensitivities!(model)
MOI.set(model, DiffOpt.ForwardConstraintSet(), ParameterRef(p), Parameter(3.0))
DiffOpt.forward_differentiate!(model)
obj_sensitivity = MOI.get(model, DiffOpt.ForwardObjectiveSensitivity())

# Reverse: set objective perturbation, then query parameter sensitivity
DiffOpt.empty_input_sensitivities!(model)
MOI.set(model, DiffOpt.ReverseObjectiveSensitivity(), 0.1)
DiffOpt.reverse_differentiate!(model)
dp = MOI.get(model, DiffOpt.ReverseConstraintSet(), ParameterRef(p))
```

## Important Utilities

### Clearing Sensitivities

Always clear sensitivities between different differentiation calls:

```julia
DiffOpt.empty_input_sensitivities!(model)
```

### Conflict: Cannot mix reverse targets

You **cannot** set both `ReverseObjectiveSensitivity` and `ReverseVariablePrimal` at the same time. The code will throw an error.

## Common Patterns

### Sensitivity Analysis of Regression

```julia
using JuMP, DiffOpt, Ipopt

model = Model(() -> DiffOpt.diff_optimizer(Ipopt.Optimizer))
set_silent(model)

# Ridge regression: min ||Ax - b||² + λ||x||²
@variable(model, x[1:n])
@variable(model, λ in Parameter(1.0))
@objective(model, Min, sum((A * x - b).^2) + λ * sum(x.^2))
optimize!(model)

# How does solution change with regularization parameter?
MOI.set(model, DiffOpt.ForwardConstraintSet(), ParameterRef(λ), Parameter(1.0))
DiffOpt.forward_differentiate!(model)
dx_dλ = [MOI.get(model, DiffOpt.ForwardVariablePrimal(), x[i]) for i in 1:n]
```

## Gotchas

- **No solver included**: DiffOpt wraps an existing solver — you must provide one (HiGHS for LP/QP, Ipopt for NLP, SCS for conic)
- **Backend selection matters**: The correct backend (QuadraticProgram, ConicProgram, NonlinearProgram) must match your problem type
- **Forward vs reverse**: Forward is efficient when you have few input perturbations; reverse is efficient when you have few output perturbations (similar to AD in ML)
- **Clear sensitivities**: Always call `DiffOpt.empty_input_sensitivities!(model)` between successive differentiation calls
- **Cannot mix reverse targets**: Setting both `ReverseObjectiveSensitivity` and `ReverseVariablePrimal` simultaneously is an error
- **ParametricOptInterface integration**: When the inner solver doesn't natively support `ParameterSet`, DiffOpt automatically adds a POI layer (controlled by `allow_parametric_opt_interface` kwarg)
