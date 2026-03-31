# Interval Stability Selection

Convenience wrapper around
[`stability_selection_fda()`](https://fbertran.github.io/SelectBoost.FDA/reference/stability_selection_fda.md)
that first creates non-overlapping interval groups within each
functional block.

## Usage

``` r
interval_stability_selection(
  x,
  y = NULL,
  width,
  step = width,
  overlap = FALSE,
  ...
)
```

## Arguments

- x:

  Any input accepted by
  [`as_functional_matrix()`](https://fbertran.github.io/SelectBoost.FDA/reference/as_functional_matrix.md),
  or an `fda_design` object.

- y:

  Response vector. Leave as `NULL` when `x` is an `fda_design`.

- width:

  Positive interval width.

- step:

  Step size between interval starts.

- overlap:

  Logical; should the interval groups overlap?

- ...:

  Additional arguments forwarded to
  [`stability_selection_fda()`](https://fbertran.github.io/SelectBoost.FDA/reference/stability_selection_fda.md).

## Value

An object of class `fda_interval_stability_selection`.
