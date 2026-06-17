# Diagnose Functional Association Structures

Builds and summarizes one or more FDA-aware association matrices.

## Usage

``` r
diagnose_functional_association(
  x,
  methods = c("correlation", "neighborhood", "hybrid", "interval"),
  bandwidth = NULL,
  width = NULL,
  step = width,
  within_blocks = TRUE,
  decay = 1
)
```

## Arguments

- x:

  Any input accepted by
  [`as_functional_matrix()`](https://fbertran.github.io/SelectBoost.FDA/reference/as_functional_matrix.md).

- methods:

  Association methods to compare.

- bandwidth, width, step, within_blocks, decay:

  Passed to
  [`functional_association()`](https://fbertran.github.io/SelectBoost.FDA/reference/functional_association.md).

## Value

A data frame with one row per association method.
