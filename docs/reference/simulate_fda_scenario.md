# Simulate an FDA Benchmark Scenario

Generates raw functional predictors, scalar covariates, a response, and
the mapped ground truth for the transformed design matrix.

## Usage

``` r
simulate_fda_scenario(
  n = 80L,
  grid_length = 60L,
  family = c("gaussian", "binomial"),
  representation = c("grid", "basis", "fpca"),
  transforms = NULL,
  basis_df = 7L,
  n_components = 5L,
  include_scalar = TRUE,
  noise_sd = 0.4,
  seed = NULL
)
```

## Arguments

- n:

  Number of observations.

- grid_length:

  Number of grid points per functional predictor.

- family:

  Model family used to generate the response.

- representation:

  Representation used when building the returned
  [`fda_design()`](https://fbertran.github.io/SelectBoost.FDA/reference/fda_design.md):
  `"grid"` keeps the raw curves, `"basis"` applies a spline-basis
  transform, and `"fpca"` applies FPCA scores.

- transforms:

  Optional transform list passed to
  [`fda_design()`](https://fbertran.github.io/SelectBoost.FDA/reference/fda_design.md).
  When omitted, a sensible default is chosen from `representation`.

- basis_df:

  Degrees of freedom used when `representation = "basis"`.

- n_components:

  Number of FPCA components used when `representation = "fpca"`.

- include_scalar:

  Should scalar covariates be included in the design and truth object?

- noise_sd:

  Observation noise level.

- seed:

  Optional random seed.

## Value

An object of class `fda_simulation_data`.

## Examples

``` r
sim <- simulate_fda_scenario(n = 24, grid_length = 16, seed = 1)
sim
#> FDA simulation data
#>   observations: 24 
#>   features: 34 
#>   active features: 8 
#>   active predictors: signal, age, treatment 
head(sim$truth$active_features)
#> [1] "signal_2"  "signal_3"  "signal_4"  "signal_8"  "signal_9"  "signal_10"
```
