# Workflow Guide

`SelectBoost.FDA` now covers several distinct FDA workflows: raw-grid
designs, basis and FPCA preprocessing, grouped stability selection,
FDA-aware `SelectBoost`, perturbation surfaces, diagnostics, and
benchmarking. This vignette is the entry point for the rest of the
documentation.

## Start here

If you are new to the package, use the vignettes in this order.

1.  [Discretized Curves and Grouped Stability
    Selection](https://fbertran.github.io/SelectBoost.FDA/articles/discretized-curves.md)
    starts from raw functional curves and builds the main `fda_design`
    object.
2.  [Basis and FPCA
    Workflows](https://fbertran.github.io/SelectBoost.FDA/articles/basis-fpca-workflows.md)
    shows how to fit and reuse spline-basis or FPCA preprocessing.
3.  [SelectBoost for Dense
    Spectra](https://fbertran.github.io/SelectBoost.FDA/articles/selectboost-spectra.md)
    focuses on the dense, highly correlated setting where FDA-aware
    `SelectBoost` is most useful.
4.  [Methods, Calibration, and Formula
    Workflows](https://fbertran.github.io/SelectBoost.FDA/articles/methods-and-formulas.md)
    covers the broader modeling API: selector backends, formulas, and
    calibration helpers.

## Diagnostics and Validation

Once the core workflow is clear, the next vignettes explain how to
inspect and compare results.

1.  [Association Diagnostics for Functional
    Predictors](https://fbertran.github.io/SelectBoost.FDA/articles/association-diagnostics.md)
    explains correlation, neighborhood, hybrid, and interval association
    structures.
2.  [Perturbation Grids for FDA
    Selection](https://fbertran.github.io/SelectBoost.FDA/articles/perturbation-grid.md)
    introduces the two-parameter selection surface indexed by `q` and
    `c0`.
3.  [Monotonicity and Precision-Recall
    Paths](https://fbertran.github.io/SelectBoost.FDA/articles/monotonicity-and-pr-paths.md)
    shows how to summarize those surfaces without relying on a plotting
    backend.

## Benchmark Material

The last two vignettes are benchmark-oriented.

1.  [Simulation and Benchmark
    Workflows](https://fbertran.github.io/SelectBoost.FDA/articles/simulation-and-benchmarks.md)
    covers the general simulation engine and method-comparison
    utilities.
2.  [Focused Benchmark
    Workflow](https://fbertran.github.io/SelectBoost.FDA/articles/focused-benchmark-workflow.md)
    focuses on the saved benchmark tables and the dedicated benchmark
    driver.

## Minimal Orientation Example

The package entry point is still the FDA-native design object.

``` r

library(SelectBoost.FDA)

sim <- simulate_fda_scenario(
  n = 18,
  grid_length = 10,
  include_scalar = FALSE,
  seed = 1
)

sim$design
#> FDA design
#>   observations: 18 
#>   features: 20 
#>   functional predictors: 2 
#>   scalar covariates: 0 
#>   family: gaussian 
#>   response available: TRUE
head(selection_map(sim$design))
#>           feature predictor  block position            argval representation
#> signal.1 signal_1    signal signal        1                 0           grid
#> signal.2 signal_2    signal signal        2 0.111111111111111           grid
#> signal.3 signal_3    signal signal        3 0.222222222222222           grid
#> signal.4 signal_4    signal signal        4 0.333333333333333           grid
#> signal.5 signal_5    signal signal        5 0.444444444444444           grid
#> signal.6 signal_6    signal signal        6 0.555555555555556           grid
#>          basis_type transform source_predictor source_representation
#> signal.1       <NA>  identity           signal                  grid
#> signal.2       <NA>  identity           signal                  grid
#> signal.3       <NA>  identity           signal                  grid
#> signal.4       <NA>  identity           signal                  grid
#> signal.5       <NA>  identity           signal                  grid
#> signal.6       <NA>  identity           signal                  grid
#>          source_position_start source_position_end source_argval_start
#> signal.1                     1                   1                   0
#> signal.2                     2                   2   0.111111111111111
#> signal.3                     3                   3   0.222222222222222
#> signal.4                     4                   4   0.333333333333333
#> signal.5                     5                   5   0.444444444444444
#> signal.6                     6                   6   0.555555555555556
#>          source_argval_end      domain_start        domain_end component unit
#> signal.1                 0                 0                 0      <NA> <NA>
#> signal.2 0.111111111111111 0.111111111111111 0.111111111111111      <NA> <NA>
#> signal.3 0.222222222222222 0.222222222222222 0.222222222222222      <NA> <NA>
#> signal.4 0.333333333333333 0.333333333333333 0.333333333333333      <NA> <NA>
#> signal.5 0.444444444444444 0.444444444444444 0.444444444444444      <NA> <NA>
#> signal.6 0.555555555555556 0.555555555555556 0.555555555555556      <NA> <NA>
#>          feature_index basis_component      domain_label
#> signal.1             1            <NA>                 0
#> signal.2             2            <NA> 0.111111111111111
#> signal.3             3            <NA> 0.222222222222222
#> signal.4             4            <NA> 0.333333333333333
#> signal.5             5            <NA> 0.444444444444444
#> signal.6             6            <NA> 0.555555555555556
```

From that point, the package branches into grouped stability selection,
FDA-aware `SelectBoost`, or benchmark workflows depending on the
question you want to answer.
