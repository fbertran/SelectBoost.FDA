# Feature-Level Selection Map

Returns a feature map augmented with selection summaries from a fit
object.

## Usage

``` r
selection_map(x, level = c("feature", "group", "basis"), ...)
```

## Arguments

- x:

  An `fda_design`, `fda_stability_selection`, or
  `selectboost_fda_result` object.

- level:

  Summary level. `"feature"` returns one row per coefficient, `"group"`
  returns one row per stability/interval group, and `"basis"` returns
  one row per basis-expanded predictor.

- ...:

  Additional arguments passed to the relevant method.

## Value

A data frame.
