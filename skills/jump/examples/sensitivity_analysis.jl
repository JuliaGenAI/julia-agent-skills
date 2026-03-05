# Sensitivity Analysis for LP
#
# Compute shadow prices, reduced costs, and perturbation ranges.
#
# Verified output:
#   Objective: 21.0
#   c1 shadow price: 0.75
#   c2 shadow price: 0.5

using JuMP, HiGHS

model = Model(HiGHS.Optimizer)
set_silent(model)

@variable(model, x >= 0)
@variable(model, y >= 0)

@objective(model, Max, 5x + 4y)

@constraint(model, c1, 6x + 4y <= 24)
@constraint(model, c2, x + 2y <= 6)

optimize!(model)
assert_is_solved_and_feasible(model)

println("Objective: ", objective_value(model))
println("x = ", value(x), ", y = ", value(y))

# Shadow prices (textbook convention — sign depends on Max/Min)
println("\nShadow prices:")
println("  c1: ", shadow_price(c1))  # value of relaxing c1 by 1 unit
println("  c2: ", shadow_price(c2))

# Reduced costs
println("\nReduced costs:")
println("  x: ", reduced_cost(x))
println("  y: ", reduced_cost(y))

# Sensitivity report — ranges for which basis remains optimal
report = lp_sensitivity_report(model)
println("\nSensitivity ranges:")

# Objective coefficient ranges: current coeff can change by (lo, hi)
x_lo, x_hi = report[x]
println("  x obj coeff range: [", 5 + x_lo, ", ", 5 + x_hi, "]")

# RHS ranges: current RHS can change by (lo, hi)
c1_lo, c1_hi = report[c1]
println("  c1 RHS range: [", 24 + c1_lo, ", ", 24 + c1_hi, "]")
