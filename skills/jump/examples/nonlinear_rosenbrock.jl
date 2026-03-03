# Nonlinear Programming: Rosenbrock Function
#
# Minimize the Rosenbrock "banana" function — a classic NLP test.
# Solver: Ipopt (interior-point, open-source)
#
# Verified output:
#   Status: LOCALLY_SOLVED
#   x ≈ 1.0, y ≈ 1.0

using JuMP, Ipopt

model = Model(Ipopt.Optimizer)
set_silent(model)

# Start values matter for NLP — solver finds local optimum
@variable(model, x, start = 0.0)
@variable(model, y, start = 0.0)

# Modern syntax (preferred over @NLobjective)
@objective(model, Min, (1 - x)^2 + 100 * (y - x^2)^2)

optimize!(model)

# NLP solvers return LOCALLY_SOLVED, not OPTIMAL
println("Status: ", termination_status(model))
println("x = ", value(x), ", y = ", value(y))
println("Objective: ", objective_value(model))

# The legacy @NL syntax still works but is not recommended:
# @NLobjective(model, Min, (1 - x)^2 + 100 * (y - x^2)^2)
