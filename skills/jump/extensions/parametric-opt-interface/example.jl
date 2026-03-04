# ParametricOptInterface.jl — Parametric sensitivity study
#
# Solve a production planning LP for varying demand levels
# without rebuilding the model each time.

using JuMP, HiGHS, Printf
import ParametricOptInterface as POI

model = Model(() -> POI.Optimizer(HiGHS.Optimizer))
set_silent(model)

# Decision variables
@variable(model, x >= 0)  # units to produce
@variable(model, y >= 0)  # units to outsource

# Parameter: demand level (will be varied)
@variable(model, demand in Parameter(100.0))

# Constraints
@constraint(model, x + y >= demand)   # meet demand
@constraint(model, x <= 80)           # production capacity

# Objective: minimize cost (production=2, outsourcing=5)
@objective(model, Min, 2x + 5y)

# Sweep demand from 50 to 150
println("Demand → Cost   | x (produce) | y (outsource)")
println("-"^50)
for d in 50:25:150
    set_parameter_value(demand, Float64(d))
    optimize!(model)
    @assert termination_status(model) == OPTIMAL
    @printf("  %3d  → %6.1f | %11.1f | %12.1f\n",
        d, objective_value(model), value(x), value(y))
end
