# Choose the Best FDA Selection Threshold

Selects the best threshold from precision-recall path data.

## Usage

``` r
best_threshold_fda(
  x,
  metric = c("f1", "jaccard", "precision_at_recall", "recall_at_precision"),
  min_precision = NULL,
  min_recall = NULL,
  truth = NULL,
  ...
)
```

## Arguments

- x:

  Precision-recall data or an object accepted by
  [`precision_recall_curve_fda()`](https://fbertran.github.io/SelectBoost.FDA/reference/precision_recall_curve_fda.md).

- metric:

  Optimization target.

- min_precision, min_recall:

  Optional constraints for constrained threshold selection.

- truth:

  Optional truth object when `x` is a fitted object.

- ...:

  Additional arguments passed to
  [`as_precision_recall_path_data()`](https://fbertran.github.io/SelectBoost.FDA/reference/as_precision_recall_path_data.md).

## Value

The best row for each method/level/path group.
