# Calibrate SelectBoost c0 Values

Runs FDA-SelectBoost on a user-provided or suggested `c0` grid.

## Usage

``` r
calibrate_selectboost(
  design,
  selector = "msgps",
  c0_grid = NULL,
  grid_method = c("quantile", "linear"),
  association_method = c("correlation", "neighborhood", "hybrid", "interval"),
  keep_fit = TRUE,
  ...
)
```

## Arguments

- design:

  An `fda_design` object.

- selector:

  Base selector passed to
  [`fit_selectboost()`](https://fbertran.github.io/SelectBoost.FDA/reference/fit_selectboost.md).

- c0_grid:

  Optional explicit `c0` grid.

- grid_method:

  Rule used by
  [`suggest_c0_grid()`](https://fbertran.github.io/SelectBoost.FDA/reference/suggest_c0_grid.md)
  when `c0_grid` is omitted.

- association_method:

  Passed to
  [`suggest_c0_grid()`](https://fbertran.github.io/SelectBoost.FDA/reference/suggest_c0_grid.md)
  and
  [`fit_selectboost()`](https://fbertran.github.io/SelectBoost.FDA/reference/fit_selectboost.md).

- keep_fit:

  Should the fitted object be stored in the result?

- ...:

  Additional arguments passed to
  [`fit_selectboost()`](https://fbertran.github.io/SelectBoost.FDA/reference/fit_selectboost.md).

## Value

An object of class `fda_calibration_grid`.
