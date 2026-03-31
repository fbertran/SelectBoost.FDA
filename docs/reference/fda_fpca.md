# FPCA Preprocessing Spec

FPCA Preprocessing Spec

## Usage

``` r
fda_fpca(
  n_components = 3L,
  variance_explained = NULL,
  center = TRUE,
  scale = FALSE
)
```

## Arguments

- n_components:

  Number of principal components to retain.

- variance_explained:

  Optional cumulative explained variance target in `(0, 1]`. When
  supplied, it overrides `n_components`.

- center, scale:

  Passed to [`stats::prcomp()`](https://rdrr.io/r/stats/prcomp.html).

## Value

An object of class `fda_preprocess_spec`.
