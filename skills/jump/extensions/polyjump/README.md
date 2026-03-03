# PolyJuMP.jl

A JuMP extension for polynomial optimization. Supports polynomial nonnegativity constraints (via SOS/SAGE) and polynomial objective/constraint reformulations.

- **Repository**: https://github.com/jump-dev/PolyJuMP.jl
- **Docs**: Included in [SumOfSquares.jl docs](https://jump.dev/SumOfSquares.jl/stable)

## Installation

```julia
import Pkg
Pkg.add("PolyJuMP")
```

## When to Use

- You have **polynomial optimization** problems: minimizing a polynomial objective subject to polynomial constraints
- You need to certify that a **polynomial is nonnegative** for all values of symbolic variables
- You want to use **Sum-of-Squares (SOS)** or **SAGE** relaxations for polynomial nonnegativity
- You need to solve polynomial optimization via **QCQP reformulation** or **KKT conditions**

## Two Main Capabilities

### 1. Polynomial Nonnegativity Constraints

Constrain a polynomial (whose coefficients depend on JuMP variables) to be nonnegative for all values of symbolic variables:

```julia
using DynamicPolynomials
@polyvar x y  # symbolic variables (NOT JuMP variables)

using JuMP
model = Model()
@variable(model, a)  # JuMP decision variable

# Constrain: a·x·y² + y³ ≥ a·x for all (x, y) ∈ ℝ²
@constraint(model, a * x * y^2 + y^3 >= a * x)
```

Since checking multivariate polynomial nonnegativity is NP-hard, you must choose a **sufficient condition**:

#### Sum-of-Squares (SOS)

```julia
import SumOfSquares
PolyJuMP.setpolymodule!(model, SumOfSquares)
# or use SOSModel() directly:
model = SOSModel()
```

#### SAGE (Sum of Arithmetic-Geometric Exponentials)

```julia
import PolyJuMP
PolyJuMP.setpolymodule!(model, PolyJuMP.SAGE)
```

#### Explicit Cone Constraints (mix SOS and SAGE)

```julia
# Can mix different nonnegativity certificates in the same model
@constraint(model, p1 in SumOfSquares.SOSCone())
@constraint(model, p2 in PolyJuMP.SAGE.Polynomials())
```

### 2. Polynomial Optimization (JuMP variables only)

For problems where all variables are JuMP decision variables (no symbolic variables), PolyJuMP provides two solver-like reformulation approaches:

#### QCQP Reformulation

Reformulates polynomial optimization into a nonconvex Quadratically Constrained Quadratic Program, then solves with a QCQP-capable solver:

```julia
using JuMP, PolyJuMP

# Requires a solver that handles nonconvex QCQP (e.g., Gurobi, SCIP)
model = Model(() -> PolyJuMP.QCQP.Optimizer(Gurobi.Optimizer))

@variable(model, x)
@variable(model, y)
@constraint(model, x^4 + y^4 <= 1)
@objective(model, Min, x^3 - y^2)

optimize!(model)
```

#### KKT Reformulation

Reformulates via KKT conditions into a system of polynomial equations, solved by an algebraic system solver:

```julia
using JuMP, PolyJuMP, HomotopyContinuation

model = Model(optimizer_with_attributes(
    PolyJuMP.KKT.Optimizer,
    "solver" => HomotopyContinuation.SemialgebraicSetsHCSolver(),
))

@variable(model, x)
@variable(model, y)
@objective(model, Min, x^2 + y^2)
@constraint(model, x + y >= 1)

optimize!(model)
```

## Related Packages

| Package | Role |
|---|---|
| [DynamicPolynomials.jl](https://github.com/JuliaAlgebra/DynamicPolynomials.jl) | Provides `@polyvar` for symbolic polynomial variables |
| [SumOfSquares.jl](https://github.com/jump-dev/SumOfSquares.jl) | SOS decomposition backend; provides `SOSModel()` and `SOSCone()` |
| [HomotopyContinuation.jl](https://github.com/JuliaHomotopyContinuation/HomotopyContinuation.jl) | Algebraic equation solver for KKT approach |
| [SemialgebraicSets.jl](https://github.com/JuliaAlgebra/SemialgebraicSets.jl) | Interface for algebraic system solvers |

## Gotchas

- **Symbolic vs JuMP variables**: `@polyvar x y` creates symbolic polynomial variables (for nonnegativity constraints). `@variable(model, x)` creates JuMP decision variables (for optimization). Don't confuse them.
- **SOS requires SDP solver**: Sum-of-Squares decomposition needs a semidefinite programming solver (e.g., SCS, Mosek, CSDP)
- **QCQP inner solver**: The QCQP reformulation requires a solver that handles nonconvex quadratic constraints (e.g., Gurobi with `NonConvex=2`, SCIP, BARON)
- **Nonnegativity ≠ global optimality**: SOS and SAGE provide *sufficient* conditions for nonnegativity. They may be conservative (declare infeasible when feasible solutions exist)
- **Scaling**: Polynomial optimization problems can be notoriously ill-conditioned. Pay attention to coefficient magnitudes
- **Documentation**: PolyJuMP's documentation is included in the SumOfSquares.jl docs, not at its own URL
