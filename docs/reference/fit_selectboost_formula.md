# Fit FDA-SelectBoost from a Formula

Fit FDA-SelectBoost from a Formula

## Usage

``` r
fit_selectboost_formula(
  formula,
  data,
  family = c("gaussian", "binomial"),
  transforms = NULL,
  scalar_transform = NULL,
  preprocessor = NULL,
  center = FALSE,
  scale = FALSE,
  ...
)
```

## Arguments

- formula, data, family, transforms, scalar_transform, preprocessor,
  center, scale:

  Passed to
  [`fda_design_formula()`](https://fbertran.github.io/SelectBoost.FDA/reference/fda_design_formula.md).

- ...:

  Additional arguments passed to
  [`fit_selectboost()`](https://fbertran.github.io/SelectBoost.FDA/reference/fit_selectboost.md).

## Value

An object inheriting from `selectboost_fda_result`.
