# PolyJuMP.jl — Polynomial optimization via QCQP reformulation
#
# Minimize a polynomial objective subject to polynomial constraints
# using PolyJuMP's QCQP reformulation with Ipopt as the inner solver.

using JuMP, PolyJuMP
import Ipopt

# Minimize x⁴ + y⁴ - x*y  subject to  x² + y² <= 1
model = Model(() -> PolyJuMP.QCQP.Optimizer(Ipopt.Optimizer))
set_silent(model)

@variable(model, x)
@variable(model, y)
@constraint(model, x^2 + y^2 <= 1)
@objective(model, Min, x^4 + y^4 - x * y)

optimize!(model)
println("Status: $(termination_status(model))")
println("x = $(value(x))")
println("y = $(value(y))")
println("Objective = $(objective_value(model))")
