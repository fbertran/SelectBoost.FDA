# Extract Functional Interval Map Data

Returns interval or group-level selection summaries with
functional-domain boundaries.

## Usage

``` r
as_functional_interval_map_data(x, threshold = 0, ...)
```

## Arguments

- x:

  A fitted selection object or selection-surface data frame.

- threshold:

  Selection cutoff.

- ...:

  Additional arguments passed to
  [`as_selection_surface_data()`](https://fbertran.github.io/SelectBoost.FDA/reference/as_selection_surface_data.md).

## Value

A data frame with interval labels, domain boundaries, and selection
values.
