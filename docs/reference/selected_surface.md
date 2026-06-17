# Extract Selected Surface Rows

Filters a selection surface by threshold.

## Usage

``` r
selected_surface(
  x,
  threshold = 0,
  level = NULL,
  value = c("selection", "mean_selection", "max_selection"),
  ...
)
```

## Arguments

- x:

  A fitted selection object, perturbation grid, or selection-surface
  data frame.

- threshold:

  Selection threshold.

- level:

  Optional level filter.

- value:

  Selection column used for grouped and basis summaries.

- ...:

  Additional arguments passed to
  [`as_selection_surface_data()`](https://fbertran.github.io/SelectBoost.FDA/reference/as_selection_surface_data.md).

## Value

A filtered selection-surface data frame.
