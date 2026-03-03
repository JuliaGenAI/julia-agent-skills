# Solver Selection Guide

## Full Solver Table

| Solver | Julia Package | License | Problem Types |
|---|---|---|---|
| Alpine.jl | — | Triad NS | (MI)NLP |
| BARON | BARON.jl | Commercial | (MI)NLP |
| Bonmin | AmplNLWriter.jl | EPL | (MI)NLP |
| Cbc | Cbc.jl | EPL | (MI)LP |
| Clarabel.jl | — | Apache | LP, QP, SOCP, SDP |
| Clp | Clp.jl | EPL | LP |
| COPT | COPT.jl | Commercial | (MI)LP, SOCP, SDP |
| COSMO.jl | — | Apache | LP, QP, SOCP, SDP |
| Couenne | AmplNLWriter.jl | EPL | (MI)NLP |
| CPLEX | CPLEX.jl | Commercial | (MI)LP, (MI)SOCP |
| CSDP | CSDP.jl | EPL | LP, SDP |
| DAQP | DAQP.jl | MIT | QP (mixed-binary) |
| ECOS | ECOS.jl | GPL | LP, SOCP |
| GLPK | GLPK.jl | GPL | (MI)LP |
| Gurobi | Gurobi.jl | Commercial | (MI)LP, (MI)SOCP |
| **HiGHS** | **HiGHS.jl** | **MIT** | **(MI)LP, QP** |
| Hypatia.jl | — | MIT | LP, SOCP, SDP |
| Ipopt | Ipopt.jl | EPL | LP, QP, NLP |
| Juniper.jl | — | MIT | (MI)SOCP, (MI)NLP |
| Knitro | KNITRO.jl | Commercial | (MI)LP, (MI)SOCP, (MI)NLP |
| MadNLP.jl | — | MIT | LP, QP, NLP |
| MOSEK | MosekTools.jl | Commercial | (MI)LP, (MI)SOCP, SDP |
| NLopt | NLopt.jl | GPL | LP, QP, NLP |
| OSQP | OSQP.jl | Apache | LP, QP |
| PATH | PATHSolver.jl | MIT | MCP |
| SCS | SCS.jl | MIT | LP, QP, SOCP, SDP |
| SCIP | SCIP.jl | Apache | (MI)LP, (MI)NLP |
| Uno | UnoSolver.jl | MIT | NLP |
| Xpress | Xpress.jl | Commercial | (MI)LP, (MI)SOCP |

Where: LP=Linear, QP=Quadratic, SOCP=Second-order conic, SDP=Semidefinite, NLP=Nonlinear, MCP=Mixed-complementarity, (MI)=Mixed-integer variant.

## Recommendations by Problem Type

### LP (Linear Programming)
- **Default**: HiGHS — MIT license, excellent performance, pure Julia install
- **Alternative open-source**: GLPK, Clp
- **Commercial**: Gurobi, CPLEX, Xpress (significantly faster on very large instances)

### QP (Quadratic Programming)
- **Convex QP**: HiGHS (convex only), OSQP (first-order, large-scale)
- **General QP**: Ipopt
- **Commercial**: Gurobi, Mosek

### MILP (Mixed-Integer Linear)
- **Default**: HiGHS — competitive with commercial solvers for many problems
- **Alternative**: GLPK (simpler), Cbc (mature), SCIP (constraint programming features)
- **Commercial**: Gurobi, CPLEX (state-of-the-art for large-scale MILP)

### SOCP (Second-Order Cone)
- **Default**: SCS — handles large-scale, low-accuracy solutions
- **Higher accuracy**: ECOS, Clarabel
- **Commercial**: Mosek, Gurobi

### SDP (Semidefinite)
- **Default**: SCS (large-scale, moderate accuracy)
- **Higher accuracy**: Clarabel, COSMO, CSDP
- **Commercial**: Mosek (gold standard for SDP)

### NLP (Nonlinear)
- **Default**: Ipopt — interior-point, handles large problems well
- **Derivative-free**: NLopt (multiple algorithms)
- **GPU-accelerated**: MadNLP
- **Commercial**: Knitro (best-in-class)

### MINLP (Mixed-Integer Nonlinear)
- **Default**: Juniper.jl (wraps any NLP solver + MIP solver)
- **Alternative**: SCIP, Bonmin, Couenne (via AmplNLWriter)
- **Commercial**: Knitro, BARON (global optimization)

## Installation Patterns

Most open-source solvers install automatically:
```julia
import Pkg
Pkg.add("HiGHS")
```

Commercial solvers require manual binary installation:
```julia
# Gurobi: install from gurobi.com, set GUROBI_HOME env var, then:
Pkg.add("Gurobi")
Pkg.build("Gurobi")

# CPLEX: install from IBM, set CPLEX_STUDIO_BINARIES env var, then:
Pkg.add("CPLEX")
Pkg.build("CPLEX")
```

## Setting Solver Options

```julia
# Common options pattern
model = Model(HiGHS.Optimizer)
set_silent(model)                        # suppress output
set_time_limit_sec(model, 60.0)          # time limit
set_attribute(model, "presolve", "on")   # solver-specific

# Solver-specific option names vary:
# HiGHS: "mip_rel_gap", "primal_feasibility_tolerance"
# Ipopt: "tol", "max_iter", "print_level"
# Gurobi: "MIPGap", "TimeLimit", "Threads"
# SCS: "eps_abs", "eps_rel", "max_iters"
```

## Using AMPL-Based Solvers

```julia
using JuMP, AmplNLWriter

# Bonmin
model = Model() do
    AmplNLWriter.Optimizer(Bonmin_jll.amplexe)
end

# Couenne (global MINLP)
model = Model() do
    AmplNLWriter.Optimizer(Couenne_jll.amplexe)
end
```
