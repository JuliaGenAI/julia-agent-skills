---
name: jump
description: Use when building, solving, or debugging mathematical optimization models in Julia with JuMP.jl. Triggers on LP, MIP, MILP, QP, SOCP, SDP, NLP, conic programming, linear programming, mixed-integer, nonlinear optimization, or when the user mentions JuMP, HiGHS, Ipopt, Gurobi, CPLEX, SCS, GLPK, or solver selection. Also use when diagnosing infeasibility, numerical issues, or solver status codes.
---

# JuMP.jl

JuMP is a domain-specific modeling language for mathematical optimization in Julia. It translates algebraic models into solver-specific representations via MathOptInterface (MOI).

For working examples, see `examples/`. For solver recommendations and numerical stability guidance, see `references/`.

## Core Workflow

```julia
using JuMP, HiGHS
model = Model(HiGHS.Optimizer)
set_silent(model)
@variable(model, x >= 0)
@variable(model, y >= 0)
@objective(model, Max, 5x + 4y)
@constraint(model, c1, 6x + 4y <= 24)
@constraint(model, c2, x + 2y <= 6)
optimize!(model)
if is_solved_and_feasible(model)
    println("x = ", value(x), ", y = ", value(y))
    println("Objective: ", objective_value(model))
end
```

**Always check status before accessing results.** Use `is_solved_and_feasible(model)` or `assert_is_solved_and_feasible(model)`.

## Variable Types

```julia
@variable(model, x)                              # free (unbounded)
@variable(model, x >= 0)                          # lower bound
@variable(model, x <= 10)                         # upper bound
@variable(model, 0 <= x <= 10)                    # interval
@variable(model, x == 5)                          # fixed
@variable(model, x, Bin)                          # binary {0,1}
@variable(model, x, Int)                          # integer
@variable(model, x in Semicontinuous(1.5, 3.5))   # {0} ∪ [1.5, 3.5]
@variable(model, x in Semiinteger(1, 5))           # {0} ∪ {1,2,3,4,5}
@variable(model, X[1:n, 1:n], PSD)                # positive semidefinite
@variable(model, p in Parameter(1.0))              # optimization parameter
```

### Containers

```julia
@variable(model, x[1:3])                        # Array
@variable(model, x[1:2, [:A, :B]])               # DenseAxisArray
@variable(model, x[i=1:3, j=i:3])                # SparseAxisArray (triangular)
@variable(model, x[i=1:9; mod(i, 3) == 0])       # filtered
@variable(model, x[foods] >= 0, Int)              # named indices (Dict keys, strings)
```

### Start Values (Warmstart)

```julia
@variable(model, x, start = 1.0)
set_start_value(x, 2.0)
# Warmstart from previous solution:
set_start_value.(all_variables(model), value.(all_variables(model)))
```

## Constraint Types

```julia
@constraint(model, x + 2y <= 10)                  # linear
@constraint(model, 1 <= x + y <= 5)                # interval
@constraint(model, x^2 + y^2 <= 1)                 # quadratic
@constraint(model, [t; x] in SecondOrderCone())     # SOC: ||x||₂ ≤ t
@constraint(model, X >= 0, PSDCone())               # semidefinite
@constraint(model, x in SOS1())                     # at most one non-zero
@constraint(model, x in SOS2([1.0, 2.0, 3.0]))      # at most two consecutive non-zero
@constraint(model, z --> {x + y <= 1})               # indicator (z binary)
@constraint(model, !z --> {x + y <= 1})              # negated indicator
@constraint(model, F ⟂ x)                           # complementarity
```

### Vectorized vs Broadcast

```julia
@constraint(model, A * x == b)     # single conic constraint (VectorAffineFunction)
@constraint(model, A * x .== b)    # N scalar constraints (for LP solvers, row-level duals)
```

## Objective

```julia
@objective(model, Min, 2x + 3y)                   # linear
@objective(model, Max, x^2 + y^2)                  # quadratic
@objective(model, Min, exp(x) + log(y))            # nonlinear
```

## Solution Queries

```julia
termination_status(model)     # OPTIMAL, INFEASIBLE, DUAL_INFEASIBLE, TIME_LIMIT, ...
primal_status(model)          # FEASIBLE_POINT, NO_SOLUTION, INFEASIBILITY_CERTIFICATE
dual_status(model)            # FEASIBLE_POINT, NO_SOLUTION, INFEASIBILITY_CERTIFICATE

value(x)                      # primal value
value.(x)                     # broadcast over containers
objective_value(model)        # optimal objective
dual(c1)                      # constraint dual (MOI convention)
shadow_price(c1)              # textbook LP dual (accounts for objective sense)
reduced_cost(x)               # textbook LP reduced cost

solution_summary(model)                # concise summary
solution_summary(model; verbose=true)  # includes all values
```

### Important Status Codes

| Status | Meaning |
|--------|---------|
| `OPTIMAL` | Globally optimal (proved) |
| `LOCALLY_SOLVED` | Locally optimal (NLP solvers like Ipopt) |
| `INFEASIBLE` | No feasible solution exists |
| `DUAL_INFEASIBLE` | Dual infeasible — check if primal is unbounded |
| `TIME_LIMIT` | May still have a feasible solution (check `primal_status`) |
| `INFEASIBLE_OR_UNBOUNDED` | Ambiguous — try disabling presolve |

### Sensitivity Analysis (LP only)

```julia
report = lp_sensitivity_report(model)
report[x]   # (decrease, increase) for objective coefficient of x
report[c1]  # (decrease, increase) for RHS of c1
```

## Nonlinear Modeling

JuMP supports nonlinear via operator overloading. The legacy `@NL*` macros still work but prefer the new syntax.

```julia
@objective(model, Min, (1 - x)^2 + 100 * (y - x^2)^2)
@constraint(model, exp(x) + log(y) <= 10)
```

### User-Defined Operators

```julia
my_func(a, b) = sin(a) * cos(b)
@operator(model, op_myfunc, 2, my_func)
@objective(model, Min, op_myfunc(x, y))
```

**Gotchas:**
- Must return a scalar, accept `Real` args (not `Float64`) for ForwardDiff
- Use splatted args `f(x...)`, not `f(x::Vector)`
- Operator name must differ from function name
- Test with `ForwardDiff.gradient(x -> f(x...), [1.0, 2.0])` before using

### Common Subexpression Elimination

JuMP does NOT do automatic CSE. Extract manually with auxiliary variables:

```julia
@variable(model, denom)
@constraint(model, denom == sum(exp.(x)))
@objective(model, Min, sum(exp(x[i]) / denom for i in 1:n))
```

## Solver Selection Quick Reference

| Problem Type | Open Source | Commercial |
|---|---|---|
| LP | HiGHS, GLPK, Clp | Gurobi, CPLEX, Xpress, COPT |
| QP | HiGHS, OSQP, Ipopt | Gurobi, CPLEX, COPT, Mosek |
| MILP | HiGHS, GLPK, Cbc, SCIP | Gurobi, CPLEX, Xpress, COPT |
| SOCP | SCS, ECOS, Clarabel | Gurobi, CPLEX, Mosek, COPT |
| SDP | SCS, Clarabel, COSMO, CSDP | Mosek, COPT |
| NLP | Ipopt, NLopt, MadNLP | Knitro |
| MINLP | Juniper + NLP solver, SCIP | Knitro, BARON |

See `references/solver-guide.md` for full details.

## Numerical Stability — Critical Rules

1. **Scale coefficients** to [1e-3, 1e6]. Ratio of largest to smallest < 1e6.
2. **Big-M values**: keep as small as possible. M = 1e12 causes integrality leakage.
3. **Binary tolerance**: `value(z)` may return `1e-8` or `0.9999`. Use `value(z) > 0.5`, never `== 1`.
4. **Round carefully**: rounding integer solutions can violate constraints.

See `references/numerical-stability.md` for details.

## Diagnosing Problems

```julia
# Infeasible — find irreducible infeasible subsystem:
compute_conflict!(model)
iis_model, _ = copy_conflict(model)
print(iis_model)

# Check constraint violations:
report = primal_feasibility_report(model)

# Export for debugging:
write_to_file(model, "debug.lp")
```

See `references/troubleshooting.md` for complete procedures.

## Model I/O

```julia
write_to_file(model, "model.mps")          # .mps, .lp, .mof.json, .nl, .cbf
model = read_from_file("model.mps")
variable_by_name(model, "x")               # containers not preserved after read
```

## Performance Tips

- Use `add_to_expression!(expr, coef, var)` instead of `expr += coef * var` in loops
- Use `set_string_name = false` on variables/constraints for large models
- Use `direct_model(Solver.Optimizer())` to skip caching layer
- Prefer `@constraint` macros over manual `add_constraint`

## Follow-Up Actions

After building and solving a model, typical next steps:
1. **Sensitivity analysis** — `lp_sensitivity_report` for LP
2. **Warm-starting** — pass previous solution as start values for modified problems
3. **Relax integrality** — `relax_integrality(model)` for LP relaxation bounds
4. **Export** — `write_to_file` for external validation or solver comparison
5. **Parametric studies** — use `Parameter` variables, update with `set_parameter_value`, re-solve

## Extension Packages

For detailed instructions on each extension, see the dedicated guides in `extensions/`.

| Package | Purpose | Guide |
|---|---|---|
| [ParametricOptInterface.jl](https://github.com/jump-dev/ParametricOptInterface.jl) | Parametric optimization — update parameters and re-solve without rebuilding | [extensions/parametric-opt-interface/](extensions/parametric-opt-interface/README.md) |
| [DiffOpt.jl](https://github.com/jump-dev/DiffOpt.jl) | Differentiate optimization programs w.r.t. parameters (forward/reverse AD) | [extensions/diffopt/](extensions/diffopt/README.md) |
| [MultiObjectiveAlgorithms.jl](https://github.com/jump-dev/MultiObjectiveAlgorithms.jl) | Multi-objective optimization with Pareto front computation | [extensions/multi-objective-algorithms/](extensions/multi-objective-algorithms/README.md) |
| [MathOptAnalyzer.jl](https://github.com/jump-dev/MathOptAnalyzer.jl) | Numerical analysis, feasibility verification, infeasibility diagnosis | [extensions/math-opt-analyzer/](extensions/math-opt-analyzer/README.md) |
| [Dualization.jl](https://github.com/jump-dev/Dualization.jl) | Compute and solve the dual of conic optimization problems | [extensions/dualization/](extensions/dualization/README.md) |
| [PolyJuMP.jl](https://github.com/jump-dev/PolyJuMP.jl) | Polynomial optimization via SOS/SAGE and QCQP/KKT reformulations | [extensions/polyjump/](extensions/polyjump/README.md) |
