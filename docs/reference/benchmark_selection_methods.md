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
#> 1 feature         34       8         24  6 18  2  8 0.2500000   0.75
#> 2 feature         34       8         29  8 21  0  5 0.2758621   1.00
#> 3   group          4       3          4  3  1  0  0 0.7500000   1.00
#> 4   group          4       3          4  3  1  0  0 0.7500000   1.00
#>   specificity        f1   jaccard selection_rate       c0            method
#> 1   0.3076923 0.3750000 0.2307692      0.7058824 c0 = 0.5       selectboost
#> 2   0.1923077 0.4324324 0.2758621      0.8529412 c0 = 0.5 plain_selectboost
#> 3   0.0000000 0.8571429 0.7500000      1.0000000 c0 = 0.5       selectboost
#> 4   0.0000000 0.8571429 0.7500000      1.0000000 c0 = 0.5 plain_selectboost
```
