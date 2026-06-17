# Extract Precision-Recall Path Data

Computes threshold-indexed precision, recall, F1, Jaccard, and selection
rates from a fitted FDA selection object or benchmark table.

## Usage

``` r
as_precision_recall_path_data(
  x,
  truth = NULL,
  level = c("feature", "group", "basis"),
  threshold_grid = seq(0, 1, by = 0.01),
  value = c("selection", "mean_selection", "max_selection"),
  ...
)
```

## Arguments

- x:

  A fitted selection object, perturbation-grid object, benchmark object,
  simulation-study object, or selection-surface data frame.

- truth:

  Optional simulation truth object. Required for fitted objects unless
  they already store truth.

- level:

  Selection level.

- threshold_grid:

  Numeric thresholds applied to selection scores.

- value:

  Selection column used for grouped and basis summaries.

- ...:

  Additional arguments passed to
  [`as_selection_surface_data()`](https://fbertran.github.io/SelectBoost.FDA/reference/as_selection_surface_data.md).

## Value

A data frame with precision-recall metrics.
