# Extract Monotonicity Path Data

Builds one row per selection path step across a chosen `c0` or `q` axis.

## Usage

``` r
as_monotonicity_path_data(
  x,
  axis = c("c0", "q"),
  level = c("feature", "group", "basis"),
  value = c("selection", "mean_selection", "max_selection"),
  tolerance = sqrt(.Machine$double.eps),
  ...
)
```

## Arguments

- x:

  A selection fit or data frame accepted by
  [`as_selection_surface_data()`](https://fbertran.github.io/SelectBoost.FDA/reference/as_selection_surface_data.md).

- axis:

  Axis over which paths are evaluated.

- level:

  Selection level.

- value:

  Selection column to track.

- tolerance:

  Numerical tolerance used for the default violation flag.

- ...:

  Additional arguments passed to
  [`as_selection_surface_data()`](https://fbertran.github.io/SelectBoost.FDA/reference/as_selection_surface_data.md).

## Value

A data frame with path identifiers, axis values, deltas, and violation
flags.
