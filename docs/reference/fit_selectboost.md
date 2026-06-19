# Fit SelectBoost from an FDA Design

Fit SelectBoost from an FDA Design

## Usage

``` r
fit_selectboost(design, ...)
```

## Arguments

- design:

  An `fda_design` object.

- ...:

  Additional arguments forwarded to
  [`selectboost_fda()`](https://fbertran.github.io/SelectBoost.FDA/reference/selectboost_fda.md).

## Value

An object inheriting from `selectboost_fda_result`.

## Examples

``` r
sim <- simulate_fda_scenario(n = 24, grid_length = 16, seed = 1)
fit <- fit_selectboost(
  sim$design,
  mode = "fast",
  steps.seq = 0.5,
  c0lim = FALSE,
  B = 3
)
head(selection_map(fit, c0 = colnames(fit$feature_selection)[1]))
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
#>          unit feature_index basis_component       domain_label selection
#> signal.1 <NA>             1            <NA>                  0 0.0000000
#> signal.2 <NA>             2            <NA> 0.0666666666666667 1.0000000
#> signal.3 <NA>             3            <NA>  0.133333333333333 1.0000000
#> signal.4 <NA>             4            <NA>                0.2 0.6666667
#> signal.5 <NA>             5            <NA>  0.266666666666667 1.0000000
#> signal.6 <NA>             6            <NA>  0.333333333333333 1.0000000
#>                c0 group_id  group
#> signal.1 c0 = 0.5        1 signal
#> signal.2 c0 = 0.5        1 signal
#> signal.3 c0 = 0.5        1 signal
#> signal.4 c0 = 0.5        1 signal
#> signal.5 c0 = 0.5        1 signal
#> signal.6 c0 = 0.5        1 signal
```
