# MathOptAnalyzer.jl — Numerical & infeasibility analysis
#
# Demonstrate the three analysis modes: numerical checks,
# feasibility verification, and infeasibility diagnosis.

using JuMP, MathOptAnalyzer, HiGHS

# --- 1. Numerical Analysis ---
println("=== Numerical Analysis ===")
model = Model(HiGHS.Optimizer)
set_silent(model)
@variable(model, x >= 0)
@variable(model, y >= 0)
@constraint(model, 1e6 * x + 1e-4 * y <= 1)  # poorly scaled
@objective(model, Min, x + y)
optimize!(model)

data = MathOptAnalyzer.analyze(MathOptAnalyzer.Numerical.Analyzer(), model)
MathOptAnalyzer.summarize(data)

# --- 2. Feasibility Analysis ---
println("\n=== Feasibility Analysis ===")
model2 = Model(HiGHS.Optimizer)
set_silent(model2)
@variable(model2, x >= 0)
@variable(model2, y >= 0)
@constraint(model2, 2x + 3y == 5)
@constraint(model2, x + 2y <= 3)
@objective(model2, Min, x + y)
optimize!(model2)

data2 = MathOptAnalyzer.analyze(MathOptAnalyzer.Feasibility.Analyzer(), model2)
MathOptAnalyzer.summarize(data2)

# --- 3. Infeasibility Analysis ---
println("\n=== Infeasibility Analysis ===")
model3 = Model(HiGHS.Optimizer)
set_silent(model3)
@variable(model3, 0 <= z <= 1)
@constraint(model3, z >= 2)  # infeasible: z <= 1 but z >= 2
@objective(model3, Min, z)
optimize!(model3)

data3 = MathOptAnalyzer.analyze(
    MathOptAnalyzer.Infeasibility.Analyzer(),
    model3,
    optimizer=HiGHS.Optimizer,
)
MathOptAnalyzer.summarize(data3)
