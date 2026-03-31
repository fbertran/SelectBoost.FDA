# Build an FDA Design from a Formula

Supports additive formulas of the form
`y ~ signal + noise + age + batch`, where functional terms are supplied
as matrices, `fda_grid`, or `fda_basis` objects in `data`, and scalar
terms are expanded through
[`stats::model.matrix()`](https://rdrr.io/r/stats/model.matrix.html).

## Usage

``` r
fda_design_formula(
  formula,
  data,
  family = c("gaussian", "binomial"),
  transforms = NULL,
  scalar_transform = NULL,
  preprocessor = NULL,
  center = FALSE,
  scale = FALSE
)
```

## Arguments

- formula:

  An additive formula with a single response.

- data:

  A list or data frame containing the variables referenced in `formula`.

- family, transforms, scalar_transform, preprocessor, center, scale:

  Passed to
  [`fda_design()`](https://fbertran.github.io/SelectBoost.FDA/reference/fda_design.md).

## Value

An object of class `fda_design`.
