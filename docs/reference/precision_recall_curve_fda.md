# Compute FDA Precision-Recall Curves

Wrapper around
[`as_precision_recall_path_data()`](https://fbertran.github.io/SelectBoost.FDA/reference/as_precision_recall_path_data.md)
for threshold-path evaluation of FDA selection results.

## Usage

``` r
precision_recall_curve_fda(
  x,
  truth = NULL,
  level = c("feature", "group", "basis"),
  value = c("selection", "mean_selection", "max_selection"),
  threshold_grid = seq(0, 1, by = 0.01),
  ...
)
```

## Arguments

- x:

  A fitted selection object, perturbation-grid object, benchmark object,
  simulation-study object, or selection-surface data frame.

- truth:

  Ground-truth object, typically from
  [`simulate_fda_scenario()`](https://fbertran.github.io/SelectBoost.FDA/reference/simulate_fda_scenario.md).

- level:

  Selection level.

- value:

  Selection column used for grouped and basis summaries.

- threshold_grid:

  Numeric thresholds.

- ...:

  Additional arguments passed to
  [`as_precision_recall_path_data()`](https://fbertran.github.io/SelectBoost.FDA/reference/as_precision_recall_path_data.md).

## Value

A threshold-indexed metric data frame.
