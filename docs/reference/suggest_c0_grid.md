# Suggest a c0 Grid for FDA-SelectBoost

Builds a data-driven `c0` grid from an FDA-aware association matrix.

## Usage

``` r
suggest_c0_grid(
  x,
  n = 5L,
  method = c("quantile", "linear"),
  association_method = c("correlation", "neighborhood", "hybrid", "interval"),
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

- n:

  Number of grid values to return.

- method:

  Grid construction rule: `"quantile"` or `"linear"`.

- association_method:

  Association structure passed to
  [`functional_association()`](https://fbertran.github.io/SelectBoost.FDA/reference/functional_association.md).

- within_blocks, bandwidth, interval_groups, width, step, decay:

  Passed to
  [`functional_association()`](https://fbertran.github.io/SelectBoost.FDA/reference/functional_association.md).

## Value

A decreasing numeric vector of `c0` values.
