# DiffOpt.jl — Forward-mode sensitivity of an LP
#
# Compute how the optimal solution changes when a constraint
# right-hand side is perturbed, using forward differentiation.

using JuMP
import DiffOpt
import HiGHS

# Create a differentiable optimizer wrapping HiGHS
model = Model(() -> DiffOpt.diff_optimizer(HiGHS.Optimizer))
set_silent(model)

# Simple LP: min x + 2y  s.t.  x + y >= p,  x,y >= 0
@variable(model, x >= 0)
@variable(model, y >= 0)
@variable(model, p in Parameter(3.0))  # parametric RHS
@constraint(model, con, x + y >= p)
@objective(model, Min, x + 2y)

optimize!(model)
println("Solution: x = $(value(x)), y = $(value(y))")
println("Objective = $(objective_value(model))")

# Forward differentiation: perturb p by +1
MOI.set(model, DiffOpt.ForwardConstraintSet(), ParameterRef(p), Parameter(1.0))
DiffOpt.forward_differentiate!(model)

dx = MOI.get(model, DiffOpt.ForwardVariablePrimal(), x)
dy = MOI.get(model, DiffOpt.ForwardVariablePrimal(), y)
println("\nSensitivity (dp = +1):")
println("  dx/dp = $dx")
println("  dy/dp = $dy")
