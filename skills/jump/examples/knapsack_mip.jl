# Mixed-Integer Programming: Knapsack Problem
#
# Select items to maximize profit without exceeding weight capacity.
# Solver: HiGHS (supports MILP)
#
# Verified output:
#   Status: OPTIMAL
#   Objective: 16.0
#   Items selected: [1, 4, 5]

using JuMP, HiGHS

model = Model(HiGHS.Optimizer)
set_silent(model)

profit = [5, 3, 2, 7, 4]
weight = [2, 8, 4, 2, 5]
capacity = 10
n = length(profit)

@variable(model, x[1:n], Bin)  # binary: take item or not

@objective(model, Max, sum(profit[i] * x[i] for i in 1:n))

@constraint(model, sum(weight[i] * x[i] for i in 1:n) <= capacity)

optimize!(model)

assert_is_solved_and_feasible(model)

println("Status: ", termination_status(model))
println("Objective: ", objective_value(model))

# Note: binary values may not be exactly 0 or 1 — use > 0.5
selected = [i for i in 1:n if value(x[i]) > 0.5]
println("Items selected: ", selected)
println("Total weight: ", sum(weight[i] for i in selected))
println("Total profit: ", sum(profit[i] for i in selected))
