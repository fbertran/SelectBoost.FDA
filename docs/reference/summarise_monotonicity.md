# Summarize Monotonicity Diagnostics

Collapses path-level monotonicity diagnostics into report-ready
summaries.

## Usage

``` r
summarise_monotonicity(
  x,
  axis = c("c0", "q"),
  direction = c("nonincreasing", "nondecreasing"),
  level = c("feature", "group", "basis"),
  value = c("selection", "mean_selection", "max_selection"),
  tolerance = 1e-08,
  ...
)
```

## Arguments

- x:

  A fitted object or an object returned by
  [`check_selection_monotonicity()`](https://fbertran.github.io/SelectBoost.FDA/reference/check_selection_monotonicity.md).

- axis, direction, level, value, tolerance:

  Passed to
  [`check_selection_monotonicity()`](https://fbertran.github.io/SelectBoost.FDA/reference/check_selection_monotonicity.md)
  when `x` is not already diagnostic data.

- ...:

  Additional arguments passed to
  [`check_selection_monotonicity()`](https://fbertran.github.io/SelectBoost.FDA/reference/check_selection_monotonicity.md).

## Value

A compact data frame with path counts and violation summaries.
