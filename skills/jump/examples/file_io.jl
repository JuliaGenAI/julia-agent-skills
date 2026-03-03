# Model File I/O
#
# Write and read optimization models in standard formats.
#
# Verified output:
#   Writes LP format, reads it back

using JuMP, HiGHS

# Build a simple model
model = Model()
@variable(model, x >= 0)
@objective(model, Min, x)
@constraint(model, x >= 3)

# Write to various formats
write_to_file(model, "/tmp/test_model.lp")    # LP format (human-readable)
# write_to_file(model, "/tmp/test_model.mps")   # MPS format (standard)
# write_to_file(model, "/tmp/test_model.mof.json")  # MOF JSON (preserves NL)

println("LP file contents:")
println(read("/tmp/test_model.lp", String))

# Read back
model2 = read_from_file("/tmp/test_model.lp")
set_optimizer(model2, HiGHS.Optimizer)
set_silent(model2)
optimize!(model2)

# Note: containers are NOT preserved — use variable_by_name
x2 = variable_by_name(model2, "x")
println("Read-back solution: x = ", value(x2))

# For debugging, write_to_file is invaluable:
# build_model()
# write_to_file(model, "debug.lp")
# # Open debug.lp in a text editor to inspect the formulation
