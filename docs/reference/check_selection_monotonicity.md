# Check Selection-Path Monotonicity

Diagnoses whether selection scores are monotone along the `c0` or `q`
axis.

## Usage

``` r
check_selection_monotonicity(
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

  A fitted selection object or data frame accepted by
  [`as_monotonicity_path_data()`](https://fbertran.github.io/SelectBoost.FDA/reference/as_monotonicity_path_data.md).

- axis:

  Axis over which paths are checked.

- direction:

  Expected monotonicity direction.

- level:

  Selection level.

- value:

  Selection column to check.

- tolerance:

  Numerical tolerance for violations.

- ...:

  Additional arguments passed to
  [`as_monotonicity_path_data()`](https://fbertran.github.io/SelectBoost.FDA/reference/as_monotonicity_path_data.md).

## Value

A data frame of class `fda_monotonicity_diagnostic`.
