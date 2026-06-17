# Extract Selection Surface Data

Converts fitted FDA selection objects into renderer-neutral data frames.
The output can be consumed by base plotting, `ggplot2`, WebGL renderers,
or report-generation code without adding plotting dependencies to the
package.

## Usage

``` r
as_selection_surface_data(x, level = NULL, threshold = 0, ...)
```

## Arguments

- x:

  A `fda_perturbation_grid`, `selectboost_fda_result`,
  `fda_stability_selection`, `fda_method_comparison`, or data frame.

- level:

  Selection level. When omitted, all available levels are returned for
  fitted objects.

- threshold:

  Selection cutoff used to populate the `selected` column.

- ...:

  Additional arguments passed to
  [`selection_map()`](https://fbertran.github.io/SelectBoost.FDA/reference/selection_map.md)
  methods.

## Value

A data frame with feature, group, domain, `q`, `c0`, and selection
columns.
