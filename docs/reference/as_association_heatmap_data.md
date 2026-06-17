# Extract Association Heatmap Data

Converts a functional association matrix into long-form data with
feature metadata for heatmaps or network displays.

## Usage

``` r
as_association_heatmap_data(
  x,
  association = NULL,
  method = c("correlation", "neighborhood", "hybrid", "interval"),
  within_blocks = TRUE,
  bandwidth = NULL,
  interval_groups = NULL,
  width = NULL,
  step = width,
  decay = 1
)
```

## Arguments

- x:

  Any input accepted by
  [`as_functional_matrix()`](https://fbertran.github.io/SelectBoost.FDA/reference/as_functional_matrix.md).

- association:

  Optional precomputed association matrix.

- method, within_blocks, bandwidth, interval_groups, width, step, decay:

  Passed to
  [`functional_association()`](https://fbertran.github.io/SelectBoost.FDA/reference/functional_association.md).

## Value

A long-form data frame with one row per matrix cell.
