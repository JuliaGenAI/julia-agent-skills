# Troubleshooting Guide

## Infeasible Model

### Step 1: Verify the formulation
```julia
print(model)                         # human-readable
write_to_file(model, "debug.lp")     # export for inspection
```

### Step 2: Find the Irreducible Infeasible Subsystem (IIS)
```julia
compute_conflict!(model)
if get_attribute(model, MOI.ConflictStatus()) == MOI.CONFLICT_FOUND
    iis_model, _ = copy_conflict(model)
    print(iis_model)
end
```

Not all solvers support `compute_conflict!`. Supported: Gurobi, CPLEX, HiGHS (partial).

### Step 3: Check a candidate point
```julia
candidate = Dict(x => 1.0, y => 2.0)
report = primal_feasibility_report(model, candidate)
for (con, violation) in report
    println(con, " → violation: ", violation)
end
```

### Step 4: Relax constraints with penalty
```julia
# Add slack variables to find which constraints are "most infeasible"
@variable(model, slack[1:num_constraints] >= 0)
# Add slacks to constraints and minimize sum of slacks
```

## Unbounded Model

`termination_status == DUAL_INFEASIBLE` means the dual is infeasible, which *usually* means the primal is unbounded. But verify:

```julia
if termination_status(model) == DUAL_INFEASIBLE
    if primal_status(model) == INFEASIBILITY_CERTIFICATE
        println("Truly unbounded — add bounds or constraints")
        # value(x) returns an unbounded ray direction
    else
        println("Dual infeasible but cannot confirm unbounded")
    end
end
```

**Fix:** Add missing variable bounds or constraints.

## Incorrect or Surprising Results

### Check 1: Solution status
```julia
println(solution_summary(model))
# Look for: termination_status, primal_status, dual_status
```

### Check 2: Feasibility violations
```julia
report = primal_feasibility_report(model)
maximum(values(report))  # largest violation
```

### Check 3: Is the model what you intended?
```julia
print(model)  # or
num_variables(model)
num_constraints(model; count_variable_in_set_constraints = true)
list_of_constraint_types(model)
```

### Check 4: Numerical conditioning
```julia
# Export and inspect coefficient ranges
write_to_file(model, "debug.mps")
# Look for coefficients spanning many orders of magnitude
```

## OptimizeNotCalled Error

Modifying a model after `optimize!()` resets the status. Query results first:

```julia
# WRONG:
optimize!(model)
set_upper_bound(x, 1)
value(x)  # ERROR: OptimizeNotCalled

# RIGHT:
optimize!(model)
x_val = value(x)       # save result first
set_upper_bound(x, 1)  # then modify
optimize!(model)        # re-solve
```

## Slow Performance

### Model Building is Slow
- Use `set_string_name = false` on variables and constraints
- Use `add_to_expression!` instead of `+=` in loops
- Use `direct_model` to skip the caching layer
- Profile with `@time` to isolate the bottleneck

### Solving is Slow
- Check solver logs (remove `set_silent`)
- Try a different solver or algorithm
- Tighten variable bounds
- Add cuts or valid inequalities
- For MIP: set `mip_rel_gap` to accept near-optimal solutions
- Provide a warm start

### Memory Issues
- Use sparse data structures
- Build constraints incrementally rather than all at once
- Use `direct_model` to avoid duplicate storage

## Common Mistakes

### 1. Not checking solution status
```julia
# BAD:
optimize!(model)
println(value(x))  # might crash if infeasible

# GOOD:
optimize!(model)
if is_solved_and_feasible(model)
    println(value(x))
end
```

### 2. Comparing binary values with ==
```julia
# BAD:
if value(z) == 1.0  # may be 0.9999999

# GOOD:
if value(z) > 0.5
```

### 3. Using += in expression loops
```julia
# BAD (creates many temporary objects):
expr = AffExpr(0.0)
for i in 1:1000
    expr += c[i] * x[i]
end

# GOOD:
expr = AffExpr(0.0)
for i in 1:1000
    add_to_expression!(expr, c[i], x[i])
end

# BEST:
@expression(model, sum(c[i] * x[i] for i in 1:1000))
```

### 4. Float64 types in user-defined operators
```julia
# BAD (breaks ForwardDiff):
my_func(x::Float64) = x^2

# GOOD:
my_func(x::Real) = x^2
```

### 5. Forgetting to install solver
```julia
# ERROR: ArgumentError: Package HiGHS not found
# FIX:
import Pkg; Pkg.add("HiGHS")
```
