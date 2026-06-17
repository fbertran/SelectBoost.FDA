# Fit a Two-Parameter FDA Perturbation Grid

Runs FDA-aware `SelectBoost` over a grid of subject subsampling rates
and `c0` perturbation strengths, returning a renderer-neutral selection
surface.

## Usage

``` r
fit_perturbation_grid(
  x,
  y = NULL,
  q_grid = c(0.5, 0.632, 0.8),
  c0_grid = seq(0.1, 0.9, by = 0.1),
  B = 100L,
  selectboost_B = 1L,
  selector = "group_lasso",
  selector_fun = NULL,
  selector_args = list(),
  family = c("gaussian", "binomial"),
  association_method = c("correlation", "neighborhood", "hybrid", "interval"),
  group_method = c("threshold", "community"),
  within_blocks = TRUE,
  bandwidth = NULL,
  width = NULL,
  step = width,
  levels = c("feature", "group", "basis"),
  cutoff = 0,
  seed = NULL,
  n_cores = 1L,
  keep_fits = FALSE,
  ...
)
```

## Arguments

- x:

  Any input accepted by
  [`as_functional_matrix()`](https://fbertran.github.io/SelectBoost.FDA/reference/as_functional_matrix.md),
  or an `fda_design`.

- y:

  Response vector. Leave as `NULL` when `x` is an `fda_design`.

- q_grid:

  Subsampling fractions.

- c0_grid:

  SelectBoost `c0` values.

- B:

  Number of row-subsampling replicates.

- selectboost_B:

  Number of internal SelectBoost perturbation replicates per subsample.

- selector, selector_fun, selector_args, family, association_method,
  group_method:

  Base selector and FDA-aware grouping arguments passed to
  [`selectboost_fda()`](https://fbertran.github.io/SelectBoost.FDA/reference/selectboost_fda.md).

- within_blocks, bandwidth, width, step:

  Functional association and interval-structure arguments passed to
  [`selectboost_fda()`](https://fbertran.github.io/SelectBoost.FDA/reference/selectboost_fda.md).

- levels:

  Selection levels to store in the surface.

- cutoff:

  Selection cutoff used for the `selected` column.

- seed:

  Optional seed used in a local RNG scope.

- n_cores:

  Reserved for future parallel backends. The current implementation runs
  serially.

- keep_fits:

  Should individual fitted objects be retained?

- ...:

  Additional arguments passed to
  [`selectboost_fda()`](https://fbertran.github.io/SelectBoost.FDA/reference/selectboost_fda.md).

## Value

An object of class `fda_perturbation_grid`.
