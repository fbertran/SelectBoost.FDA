# Functional Association Matrix

Computes or post-processes an absolute association matrix for
discretized or basis-expanded functional predictors.

## Usage

``` r
functional_association(
  x,
  association = NULL,
  method = c("correlation", "neighborhood", "hybrid", "interval"),
  within_blocks = TRUE,
  bandwidth = NULL,
  interval_groups = NULL,
  width = NULL,
  step = width,
  decay = 1
)
```

## Arguments

- x:

  Any input accepted by
  [`as_functional_matrix()`](https://fbertran.github.io/SelectBoost.FDA/reference/as_functional_matrix.md).

- association:

  Optional square association matrix supplied by the user. When omitted,
  `abs(stats::cor(X))` is used.

- method:

  Association structure. `"correlation"` uses the absolute correlation
  matrix, `"neighborhood"` uses local positional similarity, `"hybrid"`
  multiplies correlation by a neighborhood kernel, and `"interval"`
  induces associations within interval groups.

- within_blocks:

  Should cross-block associations be zeroed out?

- bandwidth:

  Optional maximum within-block lag retained in the association matrix.

- interval_groups:

  Optional interval grouping used when `method = "interval"`.

- width, step:

  Interval parameters used when `method = "interval"` and
  `interval_groups` is omitted.

- decay:

  Positive exponent controlling the neighborhood kernel.

## Value

A square absolute association matrix with unit diagonal.
