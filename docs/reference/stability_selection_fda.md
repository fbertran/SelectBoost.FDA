# Grouped Stability Selection for Functional Predictors

Repeatedly subsamples observations, refits a sparse base selector, and
computes exact feature- and group-level selection frequencies. This is
the generic FDA recipe for basis expansions, discretized curves, or FPCA
scores.

## Usage

``` r
stability_selection_fda(
  x,
  y = NULL,
  selector = "group_lasso",
  selector_fun = NULL,
  groups = NULL,
  family = c("gaussian", "binomial"),
  B = 100L,
  sample_fraction = 0.5,
  cutoff = 0.75,
  seed = NULL,
  keep_subsamples = FALSE,
  ...
)
```

## Arguments

- x:

  Any input accepted by
  [`as_functional_matrix()`](https://fbertran.github.io/SelectBoost.FDA/reference/as_functional_matrix.md),
  or an `fda_design` object.

- y:

  Response vector. Leave as `NULL` when `x` is an `fda_design`.

- selector:

  Either `"lasso"`, `"group_lasso"`, `"sparse_group_lasso"`, one of the
  backend-specific aliases (`"glmnet"`, `"grpreg"`, `"sgl"`), or a
  custom function.

- selector_fun:

  Optional custom selector. It must accept `X`, `y`, `groups`, and
  `family`, and return either a coefficient vector or a logical
  selection vector of length `p`.

- groups:

  Optional grouping structure. Defaults to block-level groups when `x`
  is supplied as a list, and otherwise to one group per feature.

- family:

  Model family passed to the built-in selectors.

- B:

  Number of subsampling replicates.

- sample_fraction:

  Fraction of observations drawn without replacement in each subsample.

- cutoff:

  Stability threshold used to define `selected_features` and
  `selected_groups`.

- seed:

  Optional random seed.

- keep_subsamples:

  Should the sampled row indices be returned?

- ...:

  Additional arguments forwarded to the built-in or custom selector.

## Value

An object of class `fda_stability_selection`.
