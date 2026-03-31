# Plain SelectBoost Baseline for Functional Predictors

Runs `SelectBoost` directly on the flattened predictor matrix without
the FDA-specific grouping heuristics used by
[`selectboost_fda()`](https://fbertran.github.io/SelectBoost.FDA/reference/selectboost_fda.md).
This is useful as a benchmark against the FDA-aware variant.

## Usage

``` r
plain_selectboost(
  x,
  y = NULL,
  mode = c("fast", "auto"),
  selector = "msgps",
  selector_fun = NULL,
  selector_args = list(),
  groups = NULL,
  family = c("gaussian", "binomial"),
  association = NULL,
  group_method = c("threshold", "community"),
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

- mode:

  `"fast"` for a fixed `c0` grid or `"auto"` for the adaptive version.

- selector:

  Base selector used inside SelectBoost. Choose from `"msgps"`,
  `"lasso"`, `"group_lasso"`, `"sparse_group_lasso"`, the
  backend-specific aliases `"glmnet"`, `"grpreg"`, `"sgl"`, or provide a
  custom function.

- selector_fun:

  Optional custom base selector. It must return a coefficient vector of
  length `p`.

- selector_args:

  Optional named list of arguments forwarded to the base selector.

- groups:

  Optional feature groups used by grouped base selectors such as
  `"grpreg"`. Defaults to block-level groups for list inputs.

- family:

  Model family passed to built-in selectors.

- association:

  Optional absolute association matrix used directly by the raw
  SelectBoost grouping function.

- group_method:

  Functional grouping backend: threshold-based or community-based.

- ...:

  Additional arguments passed to
  [`SelectBoost::fastboost()`](https://fbertran.github.io/SelectBoost/reference/fastboost.html)
  or
  [`SelectBoost::autoboost()`](https://fbertran.github.io/SelectBoost/reference/autoboost.html).

## Value

An object of class `plain_selectboost_result`.
