# Numerical Stability Guide

## The Four Tolerances

Solvers use numerical tolerances — results are approximate, not exact.

### 1. Primal Feasibility (~1e-8)
A constraint `6x + 8y >= 100` is satisfied if `6x + 8y >= 100 - ε`.

Example: HiGHS uses `primal_feasibility_tolerance` (default 1e-7).

### 2. Dual Feasibility (~1e-8)
Dual constraints satisfied within tolerance.

### 3. Integrality (~1e-6)
A variable `x ∈ {0,1}` is integer-feasible if `|x - round(x)| ≤ ε`.

Example: HiGHS uses `mip_feasibility_tolerance` (default 1e-6).

**Consequence:** `value(z)` for a binary may return `1e-8`, `-0.0`, or `0.9999999`.

### 4. Optimality
Primal-dual gap acceptable. Example: HiGHS `ipm_optimality_tolerance`.

## Problem Scaling Rules

**Keep all coefficients between 1e-3 and 1e6.** Keep the ratio of largest to smallest coefficient below 1e6.

### How to Scale

Change your units. If capacity is in Watts (1e9) and cost in dollars:

```julia
# BAD — coefficient range spans 10^9
@variable(model, 0 <= capacity_W <= 10^9)
@constraint(model, 1.78 * capacity_W <= 200e6)

# GOOD — scale to MW and millions of dollars
@variable(model, 0 <= capacity_MW <= 10^3)
@constraint(model, 1.78 * capacity_MW <= 200)
```

**You must scale both variables AND constraints.** Scaling only one side shifts the problem rather than fixing it.

## Big-M Pitfalls

Big-M constraints model logical conditions: `x ≤ M * z` (if z=0, then x=0).

### The Problem

With integrality tolerance ε ≈ 1e-6 and M = 1e12:
- `z = 1e-6` is considered integer-feasible (≈ 0)
- But `M * z = 1e6` allows `x` up to 1e6 even when switch is "off"

### The Fix

Use the **tightest possible M** derived from problem structure:

```julia
# BAD
M = 1e12
@constraint(model, x <= M * z)

# GOOD — if x can be at most 100 from other constraints
M = 100
@constraint(model, x <= M * z)
```

Or use indicator constraints (no big-M needed):
```julia
@constraint(model, z --> {x <= 0})
```

## Rounding Integer Solutions

After solving, binary/integer values may not be exactly integral.

### Safe Rounding Pattern

```julia
if is_solved_and_feasible(model)
    for v in all_variables(model)
        if is_integer(v) || is_binary(v)
            val = value(v)
            rounded = round(Int, val)
            if abs(val - rounded) > 1e-4
                @warn "Variable $(name(v)) far from integer: $val"
            end
        end
    end
end
```

### Fix-and-Resolve Pattern

Round integers, fix them, and re-solve the continuous part:

```julia
int_vars = filter(v -> is_integer(v) || is_binary(v), all_variables(model))
fix.(int_vars, round.(Int, value.(int_vars)); force = true)
optimize!(model)
assert_is_solved_and_feasible(model)  # may fail if rounding broke feasibility
```

**Warning:** Rounding can cause primal feasibility violations larger than tolerance.

## Contradictory Results Between Solvers

Different solvers (or algorithms) may give different feasibility answers on the same problem. This is expected when the problem is near the boundary of feasibility. It is not a bug.

Causes:
- Different internal tolerances
- Presolve techniques
- Floating-point ordering differences

## "Optimal but Infeasible" Status

Sometimes `termination_status = OPTIMAL` but `primal_status = INFEASIBLE_POINT`. This means the solver found an optimal solution for its internal (scaled) representation, but it's slightly infeasible when unscaled.

Debug with:
```julia
report = primal_feasibility_report(model)
for (con, violation) in report
    if violation > 1e-6
        println(con, " violated by ", violation)
    end
end
```

## Solver-Specific Tolerance Settings

### HiGHS
```julia
set_attribute(model, "primal_feasibility_tolerance", 1e-8)
set_attribute(model, "dual_feasibility_tolerance", 1e-8)
set_attribute(model, "mip_feasibility_tolerance", 1e-6)
set_attribute(model, "mip_rel_gap", 1e-4)
```

### Ipopt
```julia
set_attribute(model, "tol", 1e-8)
set_attribute(model, "acceptable_tol", 1e-6)
set_attribute(model, "max_iter", 3000)
```

### SCS
```julia
set_attribute(model, "eps_abs", 1e-9)
set_attribute(model, "eps_rel", 1e-9)
set_attribute(model, "max_iters", 100_000)
```
