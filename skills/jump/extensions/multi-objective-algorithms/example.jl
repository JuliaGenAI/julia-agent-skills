# MultiObjectiveAlgorithms.jl — Bi-objective knapsack
#
# Find Pareto-optimal solutions for a knapsack problem with
# two objectives: maximize profit AND maximize desirability.

using JuMP
import HiGHS
import MultiObjectiveAlgorithms as MOA

# Data
profit = [77, 94, 71, 63, 96, 82, 85, 75, 72, 91]
desire = [65, 90, 90, 77, 95, 84, 70, 94, 66, 92]
weight = [80, 87, 68, 72, 66, 77, 99, 85, 70, 93]
capacity = 500
N = length(profit)

# Model
model = Model(() -> MOA.Optimizer(HiGHS.Optimizer))
set_silent(model)
set_attribute(model, MOA.Algorithm(), MOA.EpsilonConstraint())

@variable(model, x[1:N], Bin)
@constraint(model, sum(weight[i] * x[i] for i in 1:N) <= capacity)

# Vector-valued objective
@expression(model, profit_expr, sum(profit[i] * x[i] for i in 1:N))
@expression(model, desire_expr, sum(desire[i] * x[i] for i in 1:N))
@objective(model, Max, [profit_expr, desire_expr])

optimize!(model)
assert_is_solved_and_feasible(model)

# Print all Pareto-optimal solutions
n_sol = result_count(model)
println("Found $n_sol Pareto-optimal solutions:\n")
println("  #  | Profit | Desire | Items")
println("-"^50)
for i in 1:n_sol
    obj = objective_value(model; result=i)
    items = [j for j in 1:N if value(x[j]; result=i) > 0.5]
    println("  $i  |  $(Int(obj[1]))  |  $(Int(obj[2]))  | $items")
end
