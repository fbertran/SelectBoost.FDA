# Scalar Predictor Constructor

Wraps scalar covariates so they can participate in the same
feature-mapping and preprocessing machinery as functional predictors.

## Usage

``` r
fda_scalar(values, name = NULL, unit = NULL)
```

## Arguments

- values:

  Numeric vector or matrix with one row per observation.

- name:

  Optional predictor name.

- unit:

  Optional unit label.

## Value

An object of class `fda_scalar`.
