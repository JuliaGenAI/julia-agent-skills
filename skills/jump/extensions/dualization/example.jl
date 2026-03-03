# Dualization.jl — Dualize a conic model and solve via dual
#
# Demonstrates both `dualize()` to inspect the dual formulation
# and `dual_optimizer()` to solve a problem via its dual.

using JuMP, Dualization
import SCS

# --- 1. Inspect the dual formulation ---
println("=== Dualize a SOC model ===")
model = Model()
@variable(model, x)
@variable(model, y >= 0)
@constraint(model, [x + 2, y, 0.5] in SecondOrderCone())
@constraint(model, x == 1)
@objective(model, Min, y + 0.5)

println("Primal:")
print(model)

dual_model = dualize(model; dual_names=DualNames("dv_", "dc_"))
println("\n\nDual:")
print(dual_model)

# --- 2. Solve via dual_optimizer ---
println("\n\n=== Solve via dual_optimizer ===")
model2 = Model(dual_optimizer(SCS.Optimizer))
set_silent(model2)
@variable(model2, x >= 0)
@variable(model2, y >= 0)
@constraint(model2, [1.0 * x + 1.0 * y, x - y] in SecondOrderCone())
@objective(model2, Max, x + y)
optimize!(model2)

println("Status: $(termination_status(model2))")
println("x = $(value(x)), y = $(value(y))")
println("Objective = $(objective_value(model2))")
