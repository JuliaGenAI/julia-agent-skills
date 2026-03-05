# Quadratic Programming (QP)
#
# Minimize a quadratic objective with bound constraints.
# Solver: Ipopt (also works with HiGHS for convex QP)
#
# Verified output:
#   Status: LOCALLY_SOLVED
#   a ≈ 0.0, b ≈ 0.0

using JuMP, Ipopt

model = Model(Ipopt.Optimizer)
set_silent(model)

@variable(model, 0 <= a <= 1)
@variable(model, 0 <= b <= 1)

# Quadratic objective — use @objective, not @NLobjective
@objective(model, Min, a^2 + b^2 - 2 * a * b + a + b)

optimize!(model)

println("Status: ", termination_status(model))
println("a = ", value(a), ", b = ", value(b))
println("Objective: ", objective_value(model))

# For convex QP, HiGHS also works:
# model = Model(HiGHS.Optimizer)
# For large-scale QP, consider OSQP:
# using OSQP; model = Model(OSQP.Optimizer)
