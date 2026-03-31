# Fit Stability Selection from a Formula

Fit Stability Selection from a Formula

## Usage

``` r
fit_stability_formula(
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
  [`fit_stability()`](https://fbertran.github.io/SelectBoost.FDA/reference/fit_stability.md).

## Value

An object inheriting from `fda_stability_selection`.
