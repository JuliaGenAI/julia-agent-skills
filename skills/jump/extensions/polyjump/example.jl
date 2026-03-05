# SumOfSquares.jl — Proving polynomial nonnegativity via SOS decomposition
#
# Verify that a polynomial is nonnegative by finding a Sum-of-Squares (SOS)
# decomposition using an SDP solver.
# Adapted from SOSTOOLS SOSDEMO1 / Example 2.4 of Parrilo & Jadbabaie (2008).

using SumOfSquares, DynamicPolynomials
import CSDP

solver = optimizer_with_attributes(CSDP.Optimizer, MOI.Silent() => true)

# --- Example 1: SOS certificate for a quartic polynomial ---
@polyvar x y
p = 2x^4 + 2x^3 * y - x^2 * y^2 + 5y^4
println("Polynomial: $p")

model = SOSModel(solver)
con_ref = @constraint(model, p >= 0)
optimize!(model)
println("\nExample 1 — SOS nonnegativity certificate")
println("  Status: $(primal_status(model))")
println("  Gram matrix:\n  $(gram_matrix(con_ref))")
println("  SOS decomposition:\n  $(SOSDecomposition(gram_matrix(con_ref)))")

# --- Example 2: SOS decomposition via SOSCone() ---
p2 = 4x^4 * y^6 + x^2 - x * y^2 + y^2
println("\nExample 2 — SOSCone constraint")
println("Polynomial: $p2")

model2 = Model(solver)
con_ref2 = @constraint(model2, p2 in SOSCone())
optimize!(model2)
println("  Status: $(primal_status(model2))")
println("  SOS decomposition:\n  $(sos_decomposition(con_ref2))")
