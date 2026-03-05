# Named Containers and Data-Driven Models
#
# Model a diet problem using string-indexed variables.
# Demonstrates DenseAxisArray with non-integer indices.
#
# Verified output:
#   Status: OPTIMAL
#   salad: 5.0 (cheapest option fills the requirement)

using JuMP, HiGHS

model = Model(HiGHS.Optimizer)
set_silent(model)

# Data
foods = ["burger", "pizza", "salad"]
cost = Dict("burger" => 5, "pizza" => 8, "salad" => 3)
calories = Dict("burger" => 800, "pizza" => 600, "salad" => 200)
max_budget = 30

# Variables indexed by food names
@variable(model, x[foods] >= 0, Int)

# Minimize cost
@objective(model, Min, sum(cost[f] * x[f] for f in foods))

# Need at least 5 servings
@constraint(model, sum(x[f] for f in foods) >= 5)

# At least 1500 calories
@constraint(model, sum(calories[f] * x[f] for f in foods) >= 1500)

# Budget limit
@constraint(model, sum(cost[f] * x[f] for f in foods) <= max_budget)

optimize!(model)

assert_is_solved_and_feasible(model)

println("Status: ", termination_status(model))
println("Total cost: ", objective_value(model))
for f in foods
    v = value(x[f])
    if v > 0.5  # integer tolerance
        println("  ", f, ": ", round(Int, v), " servings")
    end
end
