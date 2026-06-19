# Simulate an FDA Benchmark Scenario

Generates raw functional predictors, scalar covariates, a response, and
the mapped ground truth for the transformed design matrix.

## Usage

``` r
simulate_fda_scenario(
  n = 80L,
  grid_length = 60L,
  family = c("gaussian", "binomial"),
  representation = c("grid", "bspline", "fpca", "basis"),
  transforms = NULL,
  basis_df = 7L,
  n_components = 5L,
  scenario = c("localized_dense", "confounded_blocks", "smooth_sparse",
    "basis_block_signal", "fpca_low_rank_signal", "null_signal", "mislocalized_signal",
    "distributed_smooth"),
  confounding_strength = NULL,
  active_region_scale = 1,
  local_correlation = 0,
  include_scalar = TRUE,
  noise_axis = NULL,
  noise_sd = 0.4,
  snr = NULL,
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
  `"grid"` keeps the raw curves, `"bspline"` applies a spline-basis
  transform, and `"fpca"` applies FPCA scores. The older `"basis"` label
  is accepted as an alias for `"bspline"`.

- transforms:

  Optional transform list passed to
  [`fda_design()`](https://fbertran.github.io/SelectBoost.FDA/reference/fda_design.md).
  When omitted, a sensible default is chosen from `representation`.

- basis_df:

  Degrees of freedom used when `representation = "bspline"`.

- n_components:

  Number of FPCA components used when `representation = "fpca"`.

- scenario:

  Benchmark scenario. Supported values are: `"localized_dense"` for
  dense local signal, `"confounded_blocks"` for correlated nuisance
  blocks, `"smooth_sparse"` for smooth coefficients on a sparse active
  domain, `"basis_block_signal"` for signal aligned with basis-like
  blocks, `"fpca_low_rank_signal"` for signal carried by the first FPCA
  components, `"null_signal"` for no true active effect, and
  `"mislocalized_signal"` for fragmented signal that is intentionally
  poorly aligned with interval/locality rules. `"distributed_smooth"` is
  retained as a backwards-compatible alias for the earlier broad smooth
  scenario.

- confounding_strength:

  Strength of cross-block confounding injected into the nuisance curve.
  Higher values make plain `SelectBoost` less able to separate true
  local signals from correlated nuisance structure.

- active_region_scale:

  Positive multiplier applied to the width of the active regions. Values
  below `1` create narrower active regions.

- local_correlation:

  Non-negative smoothing parameter applied to the simulated curves.
  Larger values increase local correlation along the grid.

- include_scalar:

  Should scalar covariates be included in the design and truth object?

- noise_axis:

  Optional label describing whether the benchmark setting is part of the
  default, fixed-SNR, or fixed-noise axis.

- noise_sd:

  Observation noise level. Ignored for Gaussian responses when `snr` is
  supplied.

- snr:

  Optional target signal-to-noise ratio for Gaussian responses. When
  supplied, the observation noise standard deviation is set to
  `sd(linear_predictor) / snr`.

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
#>   scenario: localized_dense 
#>   confounding strength: 0 
#>   active region scale: 1 
#>   local correlation: 0 
#>   noise axis: noise_sd 
#>   noise sd: 0.4 
#>   active predictors: signal, age, treatment 
head(sim$truth$active_features)
#> [1] "signal_2"  "signal_3"  "signal_4"  "signal_8"  "signal_9"  "signal_10"
```
