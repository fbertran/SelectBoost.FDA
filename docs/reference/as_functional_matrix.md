# Flatten Functional Predictors Into a Matrix

Accepts a standard numeric matrix/data frame or a named list of
functional blocks. List inputs are column-bound while preserving the
original block membership of each coefficient, which is later reused for
grouped stability selection and FDA-aware SelectBoost grouping.

## Usage

``` r
as_functional_matrix(x, center = FALSE, scale = FALSE)
```

## Arguments

- x:

  A numeric matrix/data frame, an `fda_grid`, an `fda_basis`, an
  `fda_design`, or a list of such objects. Each list element is treated
  as one functional block.

- center, scale:

  Passed to [`base::scale()`](https://rdrr.io/r/base/scale.html) when
  either argument is `TRUE`.

## Value

An object of class `fda_matrix` with elements `x`, `blocks`, and
`positions`.
