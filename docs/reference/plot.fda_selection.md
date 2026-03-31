# Plot FDA Selection Results

Plots feature-, group-, interval-, and basis-level summaries derived
from
[`selection_map()`](https://fbertran.github.io/SelectBoost.FDA/reference/selection_map.md).
The available views depend on the fitted object:

## Usage

``` r
# S3 method for class 'fda_stability_selection'
plot(
  x,
  type = c("feature", "group", "interval", "basis"),
  value = c("group", "mean", "max"),
  facet = c("none", "predictor"),
  palette = selection_palette(),
  show_legend = TRUE,
  legend_title = NULL,
  legend_n_ticks = 3L,
  legend_digits = 2L,
  legend_cex = 0.75,
  cutoff = x$cutoff,
  ...
)

# S3 method for class 'selectboost_fda_result'
plot(
  x,
  type = c("feature", "group", "basis"),
  value = c("max", "mean"),
  palette = selection_palette(),
  show_legend = TRUE,
  legend_title = NULL,
  legend_n_ticks = 3L,
  legend_digits = 2L,
  legend_cex = 0.75,
  c0 = NULL,
  ...
)
```

## Arguments

- x:

  An object returned by
  [`stability_selection_fda()`](https://fbertran.github.io/SelectBoost.FDA/reference/stability_selection_fda.md),
  [`interval_stability_selection()`](https://fbertran.github.io/SelectBoost.FDA/reference/interval_stability_selection.md),
  [`fit_stability()`](https://fbertran.github.io/SelectBoost.FDA/reference/fit_stability.md),
  [`selectboost_fda()`](https://fbertran.github.io/SelectBoost.FDA/reference/selectboost_fda.md),
  or
  [`fit_selectboost()`](https://fbertran.github.io/SelectBoost.FDA/reference/fit_selectboost.md).

- type:

  Summary view to plot. Stability-selection fits support `"feature"`,
  `"group"`, `"interval"`, and `"basis"`. SelectBoost fits support
  `"feature"`, `"group"`, and `"basis"`.

- value:

  Quantity summarized in group, interval, and basis views.
  Stability-selection fits accept `"group"`, `"mean"`, and `"max"`.
  SelectBoost fits accept `"mean"` and `"max"`.

- facet:

  Faceting mode for interval heatmaps. Currently only
  `type = "interval"` uses this argument.

- palette:

  Vector of colors used for heatmaps.

- show_legend:

  Logical; should heatmap views draw a legend?

- legend_title:

  Optional legend title for heatmap views. By default an informative
  title is chosen from `type` and `value`.

- legend_n_ticks:

  Approximate number of tick marks used in the heatmap legend.

- legend_digits:

  Number of significant digits used for heatmap legend labels.

- legend_cex:

  Character expansion used for heatmap legend text.

- cutoff:

  Stability threshold. Only used for `fda_stability_selection` objects.

- ...:

  Additional graphical parameters passed to bar-plot-based views.

- c0:

  Optional SelectBoost correlation threshold. When omitted, SelectBoost
  heatmaps are drawn across all available `c0` values.

## Value

Invisibly returns the helper output used to build the plot.

## Details

- `fda_stability_selection` supports `type = "feature"`, `"group"`,
  `"interval"`, and `"basis"`.

- `selectboost_fda_result` supports `type = "feature"`, `"group"`, and
  `"basis"`.

Heatmap-based views are used for interval summaries and for SelectBoost
summaries over multiple `c0` values. Bar-plot views are used otherwise.

## See also

[`selection_map()`](https://fbertran.github.io/SelectBoost.FDA/reference/selection_map.md)
