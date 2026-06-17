# Enforce Monotone Selection Paths

Returns path data with an additional `adjusted_value` column after
applying cumulative or isotonic monotone post-processing.

## Usage

``` r
enforce_monotone_selection(
  x,
  axis = c("c0", "q"),
  direction = c("nonincreasing", "nondecreasing"),
  method = c("cummin", "cummax", "isotonic"),
  level = c("feature", "group", "basis"),
  value = c("selection", "mean_selection", "max_selection"),
  ...
)
```

## Arguments

- x:

  A fitted selection object or data frame.

- axis, direction, level, value:

  Path specification.

- method:

  Monotone enforcement method.

- ...:

  Additional arguments passed to
  [`as_monotonicity_path_data()`](https://fbertran.github.io/SelectBoost.FDA/reference/as_monotonicity_path_data.md).

## Value

A data frame preserving the path metadata and adding `adjusted_value`.
