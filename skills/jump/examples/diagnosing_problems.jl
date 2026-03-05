# Diagnosing Infeasibility and Unboundedness
#
# Shows how to detect and debug infeasible and unbounded models.
#
# Verified output:
#   Test 1: INFEASIBLE, primal_status = NO_SOLUTION
#   Test 2: DUAL_INFEASIBLE

using JuMP, HiGHS

# --- Infeasible Model ---
println("=== Infeasible Model ===")
model = Model(HiGHS.Optimizer)
set_silent(model)

@variable(model, 0 <= z <= 1)
@constraint(model, z >= 2)  # impossible: z ≤ 1 AND z ≥ 2

optimize!(model)

println("Termination: ", termination_status(model))   # INFEASIBLE
println("Primal status: ", primal_status(model))       # NO_SOLUTION

# Do NOT call value(z) — no solution exists
if termination_status(model) == INFEASIBLE
    println("Model is infeasible. Debugging steps:")
    println("  1. Use compute_conflict!(model) to find IIS")
    println("  2. Use primal_feasibility_report(model, candidate) to check a point")
    println("  3. Export with write_to_file(model, \"debug.lp\") for inspection")

    # Find irreducible infeasible subsystem (if solver supports it)
    try
        compute_conflict!(model)
        iis_model, _ = copy_conflict(model)
        println("\nIrreducible Infeasible Subsystem:")
        print(iis_model)
    catch e
        println("\nSolver does not support conflict computation: ", e)
    end
end

# --- Unbounded Model ---
println("\n=== Unbounded Model ===")
model2 = Model(HiGHS.Optimizer)
set_silent(model2)

@variable(model2, w >= 0)
@objective(model2, Max, w)  # maximize w with no upper bound

optimize!(model2)

println("Termination: ", termination_status(model2))  # DUAL_INFEASIBLE
println("Dual status: ", dual_status(model2))

# DUAL_INFEASIBLE does not always mean unbounded.
# Need to also check primal feasibility:
if termination_status(model2) == DUAL_INFEASIBLE
    if primal_status(model2) == INFEASIBILITY_CERTIFICATE
        println("Model is unbounded (primal ray exists)")
    else
        println("Dual infeasible but no primal ray — add bounds or constraints")
    end
end
