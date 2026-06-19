# Run a Targeted Sensitivity Study for FDA-SelectBoost

Repeats the FDA benchmark over a grid of simulation settings and a grid
of FDA-aware `SelectBoost` settings. This is intended to answer the
specific benchmark question of when
[`selectboost_fda()`](https://fbertran.github.io/SelectBoost.FDA/reference/selectboost_fda.md)
improves on plain `SelectBoost`.

## Usage

``` r
run_selectboost_sensitivity_study(
  n_rep = 10L,
  simulate_grid = expand.grid(scenario = c("localized_dense", "confounded_blocks",
    "smooth_sparse", "null_signal"), confounding_strength = c(0.4, 0.9),
    active_region_scale = c(1, 0.7), local_correlation = c(0, 2), stringsAsFactors =
    FALSE),
  selectboost_grid = expand.grid(association_method = c("correlation", "neighborhood",
    "hybrid", "interval"), bandwidth = c(NA, 4, 8), stringsAsFactors = FALSE),
  simulate_args = list(),
  benchmark_args = list(),
  seed = NULL,
  keep_results = FALSE,
  progress = NULL
)
```

## Arguments

- n_rep:

  Number of replications per setting combination.

- simulate_grid:

  Data frame of simulation-setting combinations. Columns are merged into
  `simulate_args` and can include `scenario`, `confounding_strength`,
  `active_region_scale`, and `local_correlation`.

- selectboost_grid:

  Data frame of
  [`selectboost_fda()`](https://fbertran.github.io/SelectBoost.FDA/reference/selectboost_fda.md)
  setting combinations. Columns are merged into
  `benchmark_args$selectboost_args` and can include
  `association_method`, `bandwidth`, `width`, or `step`.

- simulate_args:

  Named list forwarded to
  [`simulate_fda_scenario()`](https://fbertran.github.io/SelectBoost.FDA/reference/simulate_fda_scenario.md).

- benchmark_args:

  Named list forwarded to
  [`benchmark_selection_methods()`](https://fbertran.github.io/SelectBoost.FDA/reference/benchmark_selection_methods.md).
  When omitted, the study compares FDA-aware `SelectBoost`, plain
  `SelectBoost`, and grouped stability selection.

- seed:

  Optional seed used to derive deterministic per-replication and
  per-setting seeds.

- keep_results:

  Should the individual benchmark objects be returned?

- progress:

  Optional callback function used for long-running studies. When
  supplied, it is called with named arguments including `event`,
  `replicate`, `completed_runs`, `total_runs`, and, at replicate
  completion, the completed replicate `metrics`. No files are written by
  default.

  The returned raw metrics include runtime diagnostics for each setting:
  elapsed, user, and system time; warning and failure counts; runtime
  status; error messages for failed settings; and fitted benchmark
  object size in MB when available. Failed benchmark settings are
  retained as rows with missing recovery metrics and
  `runtime_status = "failed"`.

## Value

An object inheriting from `fda_selectboost_sensitivity_study` and
`fda_simulation_study`.

## Examples

``` r
grid <- data.frame(
  scenario = "confounded_blocks",
  confounding_strength = 0.9,
  active_region_scale = 0.7,
  local_correlation = 2,
  stringsAsFactors = FALSE
)
methods <- data.frame(
  association_method = c("correlation", "hybrid"),
  bandwidth = c(NA, 4),
  stringsAsFactors = FALSE
)
study <- run_selectboost_sensitivity_study(
  n_rep = 1,
  simulate_grid = grid,
  selectboost_grid = methods,
  simulate_args = list(n = 24, grid_length = 16),
  benchmark_args = list(
    methods = c("selectboost", "plain_selectboost"),
    levels = "feature",
    selectboost_args = list(B = 3, steps.seq = 0.5, c0lim = FALSE),
    plain_selectboost_args = list(B = 3, steps.seq = 0.5, c0lim = FALSE)
  ),
  seed = 1
)
summarise_benchmark_advantage(
  study,
  target = "selectboost",
  reference = "plain_selectboost",
  level = "feature"
)
#>                                                                                                                                scenario
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.9.0.7.2.feature.selectboost.plain_selectboost.f1 confounded_blocks
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1         confounded_blocks
#>                                                                                                                       representation
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.9.0.7.2.feature.selectboost.plain_selectboost.f1           grid
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1                   grid
#>                                                                                                                         family
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.9.0.7.2.feature.selectboost.plain_selectboost.f1 gaussian
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1         gaussian
#>                                                                                                                       noise_axis
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.9.0.7.2.feature.selectboost.plain_selectboost.f1   noise_sd
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1           noise_sd
#>                                                                                                                       snr
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.9.0.7.2.feature.selectboost.plain_selectboost.f1  NA
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1          NA
#>                                                                                                                       noise_sd
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.9.0.7.2.feature.selectboost.plain_selectboost.f1      0.4
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1              0.4
#>                                                                                                                       association_method
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.9.0.7.2.feature.selectboost.plain_selectboost.f1        correlation
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1                     hybrid
#>                                                                                                                       bandwidth
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.9.0.7.2.feature.selectboost.plain_selectboost.f1        NA
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1                 4
#>                                                                                                                       confounding_strength
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.9.0.7.2.feature.selectboost.plain_selectboost.f1                  0.9
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1                          0.9
#>                                                                                                                       active_region_scale
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.9.0.7.2.feature.selectboost.plain_selectboost.f1                 0.7
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1                         0.7
#>                                                                                                                       local_correlation
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.9.0.7.2.feature.selectboost.plain_selectboost.f1                 2
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1                         2
#>                                                                                                                         level
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.9.0.7.2.feature.selectboost.plain_selectboost.f1 feature
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1         feature
#>                                                                                                                            target
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.9.0.7.2.feature.selectboost.plain_selectboost.f1 selectboost
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1         selectboost
#>                                                                                                                               reference
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.9.0.7.2.feature.selectboost.plain_selectboost.f1 plain_selectboost
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1         plain_selectboost
#>                                                                                                                       metric
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.9.0.7.2.feature.selectboost.plain_selectboost.f1     f1
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1             f1
#>                                                                                                                       n_rep
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.9.0.7.2.feature.selectboost.plain_selectboost.f1     1
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1             1
#>                                                                                                                       target_value_mean
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.9.0.7.2.feature.selectboost.plain_selectboost.f1         0.3500000
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1                 0.3529412
#>                                                                                                                       reference_value_mean
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.9.0.7.2.feature.selectboost.plain_selectboost.f1            0.3333333
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1                    0.4000000
#>                                                                                                                        delta_mean
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.9.0.7.2.feature.selectboost.plain_selectboost.f1  0.01666667
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1         -0.04705882
#>                                                                                                                       delta_sd
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.9.0.7.2.feature.selectboost.plain_selectboost.f1        0
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1                0
#>                                                                                                                       win_rate
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.9.0.7.2.feature.selectboost.plain_selectboost.f1        1
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1                0
```
