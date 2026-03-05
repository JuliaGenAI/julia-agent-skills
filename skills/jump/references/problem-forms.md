# Problem Formulation Patterns

## LP (Linear Programming)

Standard form: minimize c'x subject to Ax ≤ b, x ≥ 0.

```julia
using JuMP, HiGHS
model = Model(HiGHS.Optimizer)
set_silent(model)

n = 3
c = [1.0, 2.0, 3.0]
A = [1 1 0; 0 1 1; 1 0 1]
b = [4.0, 6.0, 5.0]

@variable(model, x[1:n] >= 0)
@objective(model, Min, sum(c[i] * x[i] for i in 1:n))
@constraint(model, A * x .<= b)
optimize!(model)
```

### Vectorized Form
```julia
@variable(model, x[1:n] >= 0)
@objective(model, Min, c' * x)
@constraint(model, A * x .<= b)
```

### Modeling Absolute Value (LP trick)
Minimize |x|: introduce auxiliary variable t:
```julia
@variable(model, t >= 0)
@constraint(model, t >= x)
@constraint(model, t >= -x)
@objective(model, Min, t)
```

## QP (Quadratic Programming)

Minimize x'Qx + c'x subject to Ax ≤ b.

```julia
using JuMP, HiGHS  # HiGHS supports convex QP
model = Model(HiGHS.Optimizer)
set_silent(model)

Q = [2.0 0.5; 0.5 1.0]  # must be positive semidefinite for convex QP
c = [1.0, 2.0]

@variable(model, x[1:2])
@objective(model, Min, x' * Q * x + c' * x)
@constraint(model, sum(x) >= 1)
optimize!(model)
```

**Key:** Prefer `@objective` for quadratic — JuMP detects and passes as QP. Only use `@NLobjective` for non-quadratic nonlinear.

## MILP (Mixed-Integer Linear Programming)

LP with integrality constraints on some variables.

```julia
using JuMP, HiGHS
model = Model(HiGHS.Optimizer)
set_silent(model)

@variable(model, x >= 0)           # continuous
@variable(model, y >= 0, Int)      # integer
@variable(model, z, Bin)           # binary

@objective(model, Max, x + 2y + 5z)
@constraint(model, x + y + z <= 10)
@constraint(model, x <= 5 * z)     # linking: x > 0 only if z = 1
optimize!(model)
```

### Big-M Formulation (if-then)
If z = 1, then x ≤ U; if z = 0, then x = 0:
```julia
M = upper_bound_of_x  # use TIGHTEST possible value
@constraint(model, x <= M * z)
```

### Indicator Constraints (preferred over big-M when supported)
```julia
@variable(model, z, Bin)
@constraint(model, z --> {x + y <= 10})    # if z=1, then x+y≤10
@constraint(model, !z --> {x == 0})        # if z=0, then x=0
```

### Piecewise Linear (SOS2)
```julia
breakpoints = [0.0, 1.0, 2.0, 3.0]
values_at = [0.0, 1.0, 4.0, 9.0]  # f(x) = x² at breakpoints

n = length(breakpoints)
@variable(model, λ[1:n] >= 0)
@constraint(model, sum(λ) == 1)
@constraint(model, λ in SOS2(collect(1.0:n)))  # at most 2 adjacent non-zero
x_approx = sum(breakpoints[i] * λ[i] for i in 1:n)
f_approx = sum(values_at[i] * λ[i] for i in 1:n)
```

## SOCP (Second-Order Cone Programming)

Constraints of the form ||Ax + b||₂ ≤ c'x + d.

```julia
using JuMP, SCS
model = Model(SCS.Optimizer)
set_silent(model)

@variable(model, t)
@variable(model, x[1:3])

# Norm constraint: ||x||₂ ≤ t
@constraint(model, [t; x] in SecondOrderCone())

# Rotated SOC: ||x||₂² ≤ 2 * u * v, u,v ≥ 0
@variable(model, u >= 0)
@variable(model, v >= 0)
@constraint(model, [u; v; x] in RotatedSecondOrderCone())
```

### Common SOCP Reformulations
```julia
# Minimize ||Ax - b||₂
@variable(model, t)
@constraint(model, [t; A * x - b] in SecondOrderCone())
@objective(model, Min, t)

# Epigraph of quadratic: x'x ≤ t
@constraint(model, [t; x] in SecondOrderCone())
```

## SDP (Semidefinite Programming)

Matrix variable X must be positive semidefinite: X ≽ 0.

```julia
using JuMP, SCS
model = Model(SCS.Optimizer)
set_silent(model)

n = 3
@variable(model, X[1:n, 1:n], PSD)

# Linear matrix inequality
C = [1 0 0; 0 2 0; 0 0 3]
@objective(model, Min, tr(C * X))
@constraint(model, tr(X) == 1)
optimize!(model)
```

### Symmetric Variables (without PSD)
```julia
@variable(model, X[1:n, 1:n], Symmetric)  # symmetric but not necessarily PSD
@constraint(model, X >= 0, PSDCone())       # add PSD separately if needed
```

## NLP (Nonlinear Programming)

```julia
using JuMP, Ipopt
model = Model(Ipopt.Optimizer)
set_silent(model)

@variable(model, x[1:2], start = 0.0)

# Nonlinear objective
@objective(model, Min, (x[1] - 1)^2 + 100 * (x[2] - x[1]^2)^2)

# Nonlinear constraint
@constraint(model, x[1]^2 + x[2]^2 <= 2)

optimize!(model)
```

### User-Defined Operators
```julia
function my_nonlinear(a::Real, b::Real)
    return sin(a) * exp(-b)
end

@operator(model, op_nl, 2, my_nonlinear)
@constraint(model, op_nl(x[1], x[2]) <= 1.0)
```

### NLP with Parameters
```julia
@variable(model, p in Parameter(1.0))
@objective(model, Min, (x[1] - p)^2)
optimize!(model)

# Update parameter and re-solve (efficient — no model rebuild)
set_parameter_value(p, 5.0)
optimize!(model)
```

## MCP (Mixed Complementarity Problem)

Find x such that F(x) ⟂ x, with bounds on x.

```julia
using JuMP, PATHSolver
model = Model(PATHSolver.Optimizer)

@variable(model, x >= 0)
@variable(model, y >= 0)

# F₁(x,y) ⟂ x means: F₁ ≥ 0, x ≥ 0, x * F₁ = 0
@constraint(model, 2x - 1 ⟂ x)
@constraint(model, y - x ⟂ y)

optimize!(model)
```
