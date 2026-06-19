# Benchmark FDA Selection Methods on Shared Ground Truth

Runs
[`compare_selection_methods()`](https://fbertran.github.io/SelectBoost.FDA/reference/compare_selection_methods.md)
on a simulated dataset and evaluates the fitted objects against the
mapped truth.

## Usage

``` r
benchmark_selection_methods(
  data,
  methods = c("stability", "interval", "selectboost", "plain_selectboost"),
  levels = c("feature", "group"),
  stability_args = list(),
  interval_args = list(),
  selectboost_args = list(),
  plain_selectboost_args = list(),
  fdboost_model = NULL,
  fdboost_args = list(),
  keep_comparison = TRUE
)
```

## Arguments

- data:

  An object returned by
  [`simulate_fda_scenario()`](https://fbertran.github.io/SelectBoost.FDA/reference/simulate_fda_scenario.md).

- methods:

  Methods passed to
  [`compare_selection_methods()`](https://fbertran.github.io/SelectBoost.FDA/reference/compare_selection_methods.md).

- levels:

  Evaluation levels.

- stability_args, interval_args, selectboost_args,
  plain_selectboost_args:

  Additional arguments passed to
  [`compare_selection_methods()`](https://fbertran.github.io/SelectBoost.FDA/reference/compare_selection_methods.md).

- fdboost_model, fdboost_args:

  Optional `FDboost` inputs forwarded to
  [`compare_selection_methods()`](https://fbertran.github.io/SelectBoost.FDA/reference/compare_selection_methods.md).

- keep_comparison:

  Should the fitted comparison object be stored?

## Value

An object of class `fda_benchmark`.

## Examples

``` r
sim <- simulate_fda_scenario(n = 24, grid_length = 16, seed = 1)
bench <- benchmark_selection_methods(
  sim,
  methods = c("selectboost", "plain_selectboost"),
  selectboost_args = list(B = 3, steps.seq = 0.5, c0lim = FALSE),
  plain_selectboost_args = list(B = 3, steps.seq = 0.5, c0lim = FALSE)
)
head(bench$metrics)
#>     level n_universe n_truth n_selected tp fp fn tn precision recall
#> 1 feature         34       8         29  7 22  1  4 0.2413793  0.875
#> 2 feature         34       8         27  8 19  0  7 0.2962963  1.000
#> 3   group          4       3          4  3  1  0  0 0.7500000  1.000
#> 4   group          4       3          4  3  1  0  0 0.7500000  1.000
#>   specificity        f1   jaccard selection_rate       c0            method
#> 1   0.1538462 0.3783784 0.2333333      0.8529412 c0 = 0.5       selectboost
#> 2   0.2692308 0.4571429 0.2962963      0.7941176 c0 = 0.5 plain_selectboost
#> 3   0.0000000 0.8571429 0.7500000      1.0000000 c0 = 0.5       selectboost
#> 4   0.0000000 0.8571429 0.7500000      1.0000000 c0 = 0.5 plain_selectboost
#>          scenario representation   family noise_axis snr noise_sd
#> 1 localized_dense           grid gaussian   noise_sd  NA      0.4
#> 2 localized_dense           grid gaussian   noise_sd  NA      0.4
#> 3 localized_dense           grid gaussian   noise_sd  NA      0.4
#> 4 localized_dense           grid gaussian   noise_sd  NA      0.4
#>   effective_noise_sd effective_snr effective_variance_snr
#> 1                0.4      1.509747               2.279335
#> 2                0.4      1.509747               2.279335
#> 3                0.4      1.509747               2.279335
#> 4                0.4      1.509747               2.279335
```
