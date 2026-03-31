# Apply an FDA Preprocessor

Applies a fitted preprocessor to new functional predictors and optional
scalar covariates, returning an `fda_matrix` object compatible with the
selection routines.

## Usage

``` r
apply_fda_preprocessor(object, predictors, scalar_covariates = NULL, ...)
```

## Arguments

- object:

  A fitted `fda_preprocessor`.

- predictors:

  New functional predictors.

- scalar_covariates:

  Optional scalar covariates.

- ...:

  Not used.

## Value

An object of class `fda_matrix`.
