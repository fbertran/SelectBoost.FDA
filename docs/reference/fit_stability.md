# Fit Grouped Stability Selection from an FDA Design

Fit Grouped Stability Selection from an FDA Design

## Usage

``` r
fit_stability(design, ...)
```

## Arguments

- design:

  An `fda_design` object.

- ...:

  Additional arguments forwarded to
  [`stability_selection_fda()`](https://fbertran.github.io/SelectBoost.FDA/reference/stability_selection_fda.md).

## Value

An object inheriting from `fda_stability_selection`.

## Examples

``` r
sim <- simulate_fda_scenario(n = 24, grid_length = 16, seed = 1)
if (requireNamespace("glmnet", quietly = TRUE)) {
  fit <- fit_stability(
    sim$design,
    selector = "lasso",
    B = 4,
    cutoff = 0.4,
    seed = 1
  )
  head(selection_map(fit))
}
#> Warning: Option grouped=FALSE enforced in cv.glmnet, since < 3 observations per fold
#> Warning: Option grouped=FALSE enforced in cv.glmnet, since < 3 observations per fold
#> Warning: Option grouped=FALSE enforced in cv.glmnet, since < 3 observations per fold
#> Warning: Option grouped=FALSE enforced in cv.glmnet, since < 3 observations per fold
#>           feature predictor  block position             argval representation
#> signal.1 signal_1    signal signal        1                  0           grid
#> signal.2 signal_2    signal signal        2 0.0666666666666667           grid
#> signal.3 signal_3    signal signal        3  0.133333333333333           grid
#> signal.4 signal_4    signal signal        4                0.2           grid
#> signal.5 signal_5    signal signal        5  0.266666666666667           grid
#> signal.6 signal_6    signal signal        6  0.333333333333333           grid
#>          basis_type transform source_predictor source_representation
#> signal.1       <NA>  identity           signal                  grid
#> signal.2       <NA>  identity           signal                  grid
#> signal.3       <NA>  identity           signal                  grid
#> signal.4       <NA>  identity           signal                  grid
#> signal.5       <NA>  identity           signal                  grid
#> signal.6       <NA>  identity           signal                  grid
#>          source_position_start source_position_end source_argval_start
#> signal.1                     1                   1                   0
#> signal.2                     2                   2  0.0666666666666667
#> signal.3                     3                   3   0.133333333333333
#> signal.4                     4                   4                 0.2
#> signal.5                     5                   5   0.266666666666667
#> signal.6                     6                   6   0.333333333333333
#>           source_argval_end       domain_start         domain_end component
#> signal.1                  0                  0                  0      <NA>
#> signal.2 0.0666666666666667 0.0666666666666667 0.0666666666666667      <NA>
#> signal.3  0.133333333333333  0.133333333333333  0.133333333333333      <NA>
#> signal.4                0.2                0.2                0.2      <NA>
#> signal.5  0.266666666666667  0.266666666666667  0.266666666666667      <NA>
#> signal.6  0.333333333333333  0.333333333333333  0.333333333333333      <NA>
#>          unit feature_index basis_component       domain_label
#> signal.1 <NA>             1            <NA>                  0
#> signal.2 <NA>             2            <NA> 0.0666666666666667
#> signal.3 <NA>             3            <NA>  0.133333333333333
#> signal.4 <NA>             4            <NA>                0.2
#> signal.5 <NA>             5            <NA>  0.266666666666667
#> signal.6 <NA>             6            <NA>  0.333333333333333
#>          feature_frequency selected group_id  group group_frequency
#> signal.1              0.00    FALSE        1 signal            0.25
#> signal.2              0.25    FALSE        1 signal            0.25
#> signal.3              0.00    FALSE        1 signal            0.25
#> signal.4              0.00    FALSE        1 signal            0.25
#> signal.5              0.00    FALSE        1 signal            0.25
#> signal.6              0.25    FALSE        1 signal            0.25
#>          group_selected
#> signal.1          FALSE
#> signal.2          FALSE
#> signal.3          FALSE
#> signal.4          FALSE
#> signal.5          FALSE
#> signal.6          FALSE
```
