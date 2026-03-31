# Spectroscopy-Style Functional Example

Simulated dense spectra with one signal block, one nuisance block, and
two scalar covariates. The response is continuous and depends on
localized regions of the signal spectrum plus the scalar covariates.

## Usage

``` r
spectra_example
```

## Format

A list with four components:

- grid:

  Numeric vector of wavelength locations.

- response:

  Numeric response vector.

- predictors:

  Named list of functional predictor matrices.

- scalar_covariates:

  Data frame with scalar covariates.

## Source

Simulated for package examples.
