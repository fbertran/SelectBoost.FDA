# Interval Groups for Discretized Functional Predictors

Creates non-overlapping interval groups within each functional block.
This is useful when one wants region-level stability summaries instead
of pointwise selection frequencies.

## Usage

``` r
functional_interval_groups(x, width, step = width, overlap = FALSE)
```

## Arguments

- x:

  Any input accepted by
  [`as_functional_matrix()`](https://fbertran.github.io/SelectBoost.FDA/reference/as_functional_matrix.md).

- width:

  Positive integer interval width within each block.

- step:

  Step size between interval starts. Only non-overlapping intervals are
  supported by default.

- overlap:

  Logical; should intervals be allowed to overlap? When `TRUE`, the
  result is returned as an overlapping group structure.

## Value

Either an integer group vector with an `interval_table` attribute or an
overlapping group structure of class `fda_group_list`.
