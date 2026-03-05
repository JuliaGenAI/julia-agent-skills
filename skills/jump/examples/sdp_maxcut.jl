# Semidefinite Programming (SDP): Max-Cut Relaxation
#
# Solver: SCS (open-source conic solver supporting SDP)
#
# The max-cut SDP relaxation finds an upper bound on the maximum
# weight of edges that can be cut by partitioning graph vertices.

using JuMP, SCS, LinearAlgebra

model = Model(SCS.Optimizer)
set_silent(model)

# Laplacian of a simple graph (triangle with weights)
#   1 --2-- 2
#   |      /
#   1    3
#   |  /
#   3
W = [0 2 1; 2 0 3; 1 3 0]   # weight matrix
n = size(W, 1)
L = Diagonal(vec(sum(W; dims=2))) - W  # Laplacian

# PSD variable
@variable(model, X[1:n, 1:n], PSD)

# Diagonal entries = 1
@constraint(model, [i in 1:n], X[i, i] == 1)

# Maximize 1/4 * tr(L * X)
@objective(model, Max, 1 / 4 * tr(L * X))

optimize!(model)

if is_solved_and_feasible(model)
    println("Status: ", termination_status(model))
    println("Max-cut SDP bound: ", objective_value(model))
    println("X = ")
    display(value.(X))
end
