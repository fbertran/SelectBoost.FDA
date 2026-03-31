# Spline-Basis Preprocessing Spec

Spline-Basis Preprocessing Spec

## Usage

``` r
fda_bspline(
  df = 6L,
  degree = 3L,
  intercept = TRUE,
  center = FALSE,
  scale = FALSE
)
```

## Arguments

- df:

  Degrees of freedom used by
  [`splines::bs()`](https://rdrr.io/r/splines/bs.html).

- degree:

  Spline degree.

- intercept:

  Should the spline basis include an intercept column?

- center, scale:

  Logical flags controlling column-wise centering and scaling of the
  resulting coefficients.

## Value

An object of class `fda_preprocess_spec`.
