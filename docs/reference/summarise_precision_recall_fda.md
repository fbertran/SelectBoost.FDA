# Summarize FDA Precision-Recall Paths

Returns one best-threshold row per method and level.

## Usage

``` r
summarise_precision_recall_fda(
  x,
  metric = c("f1", "jaccard", "precision_at_recall", "recall_at_precision"),
  truth = NULL,
  ...
)
```

## Arguments

- x:

  Precision-recall data or an object accepted by
  [`precision_recall_curve_fda()`](https://fbertran.github.io/SelectBoost.FDA/reference/precision_recall_curve_fda.md).

- metric:

  Metric optimized by
  [`best_threshold_fda()`](https://fbertran.github.io/SelectBoost.FDA/reference/best_threshold_fda.md).

- truth:

  Optional truth object when `x` is a fitted object.

- ...:

  Additional arguments passed to
  [`best_threshold_fda()`](https://fbertran.github.io/SelectBoost.FDA/reference/best_threshold_fda.md).

## Value

A compact data frame with best threshold and recovery metrics.
