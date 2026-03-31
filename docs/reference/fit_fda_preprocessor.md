# Fit an FDA Preprocessor

Learns train/test-safe preprocessing transforms for functional
predictors and optional scalar covariates. The fitted object can be
reused to create compatible `fda_design` objects on new data.

## Usage

``` r
fit_fda_preprocessor(
  predictors,
  scalar_covariates = NULL,
  transforms = NULL,
  scalar_transform = NULL
)
```

## Arguments

- predictors:

  One predictor or a named list of predictors.

- scalar_covariates:

  Optional scalar covariates supplied as a vector, matrix/data frame,
  `fda_scalar`, or a named list.

- transforms:

  Optional preprocessing specs for functional predictors.

- scalar_transform:

  Optional preprocessing specs for scalar covariates.

## Value

An object of class `fda_preprocessor`.
