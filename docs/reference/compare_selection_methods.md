# Compare FDA Selection Methods

Runs multiple selection workflows on the same `fda_design` object and
returns both the fitted objects and a comparison table.

## Usage

``` r
compare_selection_methods(
  design,
  methods = c("stability", "interval", "selectboost"),
  stability_args = list(),
  interval_args = list(),
  selectboost_args = list(),
  plain_selectboost_args = list(),
  fdboost_model = NULL,
  fdboost_args = list()
)
```

## Arguments

- design:

  An `fda_design` object.

- methods:

  Methods to run. Supported values are `"stability"`, `"interval"`,
  `"selectboost"`, `"plain_selectboost"`, and `"fdboost"`.

- stability_args, interval_args, selectboost_args,
  plain_selectboost_args:

  Named lists of arguments passed to the corresponding fitting
  functions.

- fdboost_model:

  Optional fitted `FDboost` object used when `methods` includes
  `"fdboost"`.

- fdboost_args:

  Additional arguments passed to
  [`fdboost_stability_selection()`](https://fbertran.github.io/SelectBoost.FDA/reference/fdboost_stability_selection.md).

## Value

An object of class `fda_method_comparison`.

## Examples

``` r
sim <- simulate_fda_scenario(n = 24, grid_length = 16, seed = 1)
comparison <- compare_selection_methods(
  sim$design,
  methods = c("selectboost", "plain_selectboost"),
  selectboost_args = list(B = 3, steps.seq = 0.5, c0lim = FALSE),
  plain_selectboost_args = list(B = 3, steps.seq = 0.5, c0lim = FALSE)
)
summary(comparison)
#> FDA method comparison summary
#>   methods: selectboost, plain_selectboost 
#>        c0 n_selected_features n_selected_groups mean_feature_selection
#>  c0 = 0.5                  26                 4              0.4411765
#>  c0 = 0.5                  30                 4              0.6078431
#>  max_feature_selection mean_group_selection max_group_selection
#>                      1            0.7031250                   1
#>                      1            0.7916667                   1
#>             method
#>        selectboost
#>  plain_selectboost
```
