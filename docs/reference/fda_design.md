# Functional Design Object

Bundles the response, functional predictors, family, and a reversible
feature map. This is the FDA-native entry point for the higher-level
fitting functions.

## Usage

``` r
fda_design(
  response = NULL,
  predictors,
  scalar_covariates = NULL,
  family = c("gaussian", "binomial"),
  id = NULL,
  center = FALSE,
  scale = FALSE,
  transforms = NULL,
  scalar_transform = NULL,
  preprocessor = NULL
)
```

## Arguments

- response:

  Response vector.

- predictors:

  A single predictor or a named list of predictors. Elements can be
  `fda_grid`, `fda_basis`, `fda_scalar`, matrices, data frames, or
  numeric vectors.

- scalar_covariates:

  Optional scalar covariates supplied separately from the functional
  predictors.

- family:

  Model family.

- id:

  Optional observation identifiers.

- center, scale:

  Backward-compatible shortcuts for applying an identity transform with
  centering and scaling to the functional predictors.

- transforms:

  Optional preprocessing specs for the functional predictors.

- scalar_transform:

  Optional preprocessing specs for scalar covariates.

- preprocessor:

  Optional fitted `fda_preprocessor`. When supplied, it is reused
  instead of fitting preprocessing from the current data.

## Value

An object of class `fda_design`.

## Examples

``` r
data("spectra_example", package = "SelectBoost.FDA")
idx <- 1:20
design <- fda_design(
  response = spectra_example$response[idx],
  predictors = list(
    signal = fda_grid(
      spectra_example$predictors$signal[idx, ],
      argvals = spectra_example$grid,
      name = "signal"
    ),
    nuisance = fda_grid(
      spectra_example$predictors$nuisance[idx, ],
      argvals = spectra_example$grid,
      name = "nuisance"
    )
  ),
  scalar_covariates = spectra_example$scalar_covariates[idx, ],
  scalar_transform = fda_standardize(),
  family = "gaussian"
)
summary(design)
#> FDA design summary
#>   observations: 20 
#>   features: 82 
#>   family: gaussian 
#>   response available: TRUE 
#>   functional predictors: 2 
#>   scalar covariates: 2 
#>  predictor representation n_features
#>   nuisance           grid         40
#>     signal           grid         40
#>        age         scalar          1
#>  treatment         scalar          1
```
