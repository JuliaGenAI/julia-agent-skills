# Basic Linear Programming with JuMP
#
# Minimize cost while satisfying resource constraints.
# Solver: HiGHS (open-source, MIT license)
#
# Verified output:
#   Status: OPTIMAL
#   Objective: 205.0
#   x = 15.0, y = 1.25
#   Shadow price c1: -0.25, c2: -1.5

using JuMP, HiGHS

model = Model(HiGHS.Optimizer)
set_silent(model)

@variable(model, x >= 0)
@variable(model, 0 <= y <= 3)

@objective(model, Min, 12x + 20y)

@constraint(model, c1, 6x + 8y >= 100)
@constraint(model, c2, 7x + 12y >= 120)

optimize!(model)

if !is_solved_and_feasible(model)
    error("Solver did not find an optimal solution")
end

println("Status: ", termination_status(model))
println("Objective: ", objective_value(model))
println("x = ", value(x), ", y = ", value(y))

# Sensitivity analysis (LP only)
println("Shadow price c1: ", shadow_price(c1))
println("Shadow price c2: ", shadow_price(c2))
println("Reduced cost x: ", reduced_cost(x))

report = lp_sensitivity_report(model)
println("Objective coeff range for x: ", report[x])
println("RHS range for c1: ", report[c1])
