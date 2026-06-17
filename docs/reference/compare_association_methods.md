# Compare Functional Association Methods

Alias for
[`diagnose_functional_association()`](https://fbertran.github.io/SelectBoost.FDA/reference/diagnose_functional_association.md)
with method-comparison naming.

## Usage

``` r
compare_association_methods(
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

A data frame with association diagnostics.
