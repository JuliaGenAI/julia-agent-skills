# Dualization.jl

Automatically compute the dual of conic optimization problems. Can solve the dual formulation instead of the primal for improved performance.

- **Repository**: https://github.com/jump-dev/Dualization.jl
- **Docs**: https://jump.dev/Dualization.jl/stable/

## Installation

```julia
import Pkg
Pkg.add("Dualization")
```

## When to Use

- Your conic problem has **many constraints but few variables** (dual may be smaller/faster)
- Your solver expects a specific form (**standard vs geometric**) and your model is in the other form
- You want to **inspect the dual model** for analysis or debugging
- You want to verify **strong duality** by solving both primal and dual
- Your solver solves one form faster than the other

## Conic Form Background

Solvers use different internal representations:

| Form | Structure | Solvers |
|---|---|---|
| **Geometric** (affine-in-cone) | `Ax + b ∈ K` | SCS, ECOS, CDCS, SeDuMi |
| **Standard** (variables-in-cone) | `Ax + s = b, s ∈ K` | SDPT3, SDPNAL, CSDP, SDPA |
| **Both** | Supports either form | Mosek v10 |

Dualizing converts between these forms: the dual of a geometric-form problem is in standard form, and vice versa. This means solving the dual with a geometric-form solver is equivalent to solving the primal with a standard-form solver.

## Two Main Features

### 1. `dualize(model)` — Compute the Dual Model

Produce a new JuMP model that is the dual of the original:

```julia
using JuMP, Dualization

model = Model()
@variable(model, x)
@variable(model, y >= 0)
@constraint(model, soccon, [x + 2, y, 0.5] in SecondOrderCone())
@constraint(model, eqcon, x == 1)
@objective(model, Min, y + 0.5)

dual_model = dualize(model)
print(dual_model)  # shows the dual formulation
```

#### Named Dual Variables

```julia
dual_model = dualize(model; dual_names = DualNames("dual_var_", "dual_con_"))
print(dual_model)
# Variables: dual_var_eqcon, dual_var_soccon_1, etc.
# Constraints: dual_con_x, dual_con_y, etc.
```

#### Attach a Solver

```julia
import SCS
dual_model = dualize(model, SCS.Optimizer)
optimize!(dual_model)
```

### 2. `dual_optimizer(solver)` — Solve via Dual Transparently

Wrap a solver to automatically solve the dual internally, while the user interacts with the primal:

```julia
using JuMP, Dualization, SCS

# Create model with dual_optimizer — user writes the primal
model = Model(dual_optimizer(SCS.Optimizer))
@variable(model, x >= 0)
@constraint(model, 2x + 1 >= 3)
@objective(model, Min, x)
optimize!(model)
value(x)  # returns primal solution (dual_optimizer maps back)
```

#### With Solver Attributes

```julia
model = Model(dual_optimizer(
    optimizer_with_attributes(SCS.Optimizer, "max_iters" => 10_000)
))
```

Or set attributes after creation:

```julia
model = Model(dual_optimizer(SCS.Optimizer))
set_attribute(model, "max_iters", 10_000)
```

## Supported Problem Types

### Constraints

| Function | Set |
|---|---|
| `VariableIndex` / `ScalarAffineFunction` | `GreaterThan`, `LessThan`, `EqualTo` |
| `VectorOfVariables` / `VectorAffineFunction` | `Nonnegatives`, `Nonpositives`, `Zeros` |
| `VectorOfVariables` / `VectorAffineFunction` | `SecondOrderCone`, `RotatedSecondOrderCone` |
| `VectorOfVariables` / `VectorAffineFunction` | `PositiveSemidefiniteConeTriangle` |
| `VectorOfVariables` / `VectorAffineFunction` | `ExponentialCone`, `DualExponentialCone` |
| `VectorOfVariables` / `VectorAffineFunction` | `PowerCone`, `DualPowerCone` |

### Objectives

| Function |
|---|
| `VariableIndex` |
| `ScalarAffineFunction` |
| `ScalarQuadraticFunction` |

> **Note**: Only conic problems can be dualized. MILPs, NLPs, and non-conic problems are not supported.

## Adding Custom Cone Support

To dualize models with custom cones, define the dual set and support functions:

```julia
using Dualization, JuMP

struct MyCone <: MOI.AbstractVectorSet
    dimension::Int
end

struct MyDualCone <: MOI.AbstractVectorSet
    dimension::Int
end

# Required: define the dual set
MOI.dual_set(s::MyCone) = MyDualCone(MOI.dimension(s))

# Required: declare supported constraint types
Dualization.supported_constraint(::Type{MOI.VectorOfVariables}, ::Type{MyCone}) = true
Dualization.supported_constraint(::Type{<:MOI.VectorAffineFunction}, ::Type{MyCone}) = true

# Optional: custom scalar product (if different from standard dot product)
# MOI.Utilities.set_dot(x, y, ::MyCone) = 2 * LinearAlgebra.dot(x, y)
```

## Gotchas

- **Conic only**: Dualization works only with conic problems. Non-conic constraints (general nonlinear, integer) are not supported
- **Optimizer lost**: `dualize(model)` returns a new model without the original optimizer. Pass a solver: `dualize(model, SCS.Optimizer)`
- **Primal interface with `dual_optimizer`**: When using `dual_optimizer`, you write the primal model and query primal solutions — the dual is handled internally
- **Not always faster**: Solving the dual is beneficial when the primal has many constraints and few variables. For the reverse shape, the primal is typically faster
- **Bridging**: Some cone types (e.g., `RotatedSecondOrderCone`) may need MOI bridges to be converted to supported types before dualization
