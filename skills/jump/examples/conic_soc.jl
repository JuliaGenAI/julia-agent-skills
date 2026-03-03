# Second-Order Cone Programming (SOCP)
#
# Minimize the Euclidean norm ||x||₂ subject to a linear constraint.
# Solver: SCS (open-source conic solver)
#
# Verified output:
#   Status: OPTIMAL
#   t ≈ 0.707 (= 1/√2)
#   x ≈ [0.5, 0.5]

using JuMP, SCS

model = Model(SCS.Optimizer)
set_silent(model)

@variable(model, t)
@variable(model, x[1:2])

# Second-order cone: ||x||₂ ≤ t
# Format: [t; x] ∈ SOC means t ≥ √(x₁² + x₂²)
@constraint(model, [t; x] in SecondOrderCone())

@constraint(model, x[1] + x[2] == 1)

@objective(model, Min, t)

optimize!(model)

assert_is_solved_and_feasible(model)

println("Status: ", termination_status(model))
println("t = ", value(t))
println("x = ", value.(x))
println("||x||₂ = ", sqrt(sum(value.(x) .^ 2)))

# Other conic sets available:
# RotatedSecondOrderCone()  — ||x||₂² ≤ 2tu
# PSDCone()                 — positive semidefinite
# ExponentialCone()         — (x,y,z): y*exp(x/y) ≤ z, y>0
# NormOneCone(d)            — |x|₁ ≤ t
# NormInfinityCone(d)       — |x|∞ ≤ t
