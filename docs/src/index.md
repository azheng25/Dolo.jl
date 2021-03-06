# Dolo.jl

```@meta
currentModule = Dolo
```

## What is dolo ?

Dolo is a tool to describe and solve economic models. It provides a simple classification scheme to describe many types of models, allows to write the models as simple text files and compiles these files into efficient Julia objects representing them. It also provides many reference solution algorithms to find the solution of these models under rational expectations.

Dolo understand several types of nonlinear models with occasionnally binding constraints (with or without exogenous discrete shocks), as well as local pertubations models, like Dynare. It is a very adequate tool to study zero-lower bound issues, or sudden-stop problems, for instance.

Sophisticated solution routines are available: local perturbations, perfect foresight solution, policy iteration, value iteration. Most of these solutions are either parallelized or vectorized. They are written in pure Julia, and can easily be inspected or adapted.


## Installation
