# FDA-Oriented SelectBoost Wrapper

Wraps
[`SelectBoost::fastboost()`](https://fbertran.github.io/SelectBoost/reference/fastboost.html)
or
[`SelectBoost::autoboost()`](https://fbertran.github.io/SelectBoost/reference/autoboost.html)
while adding FDA-specific structure through block-aware and region-aware
grouping.

## Usage

``` r
selectboost_fda(
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
  association_method = c("correlation", "neighborhood", "hybrid", "interval"),
  within_blocks = TRUE,
  bandwidth = NULL,
  interval_groups = NULL,
  width = NULL,
  step = width,
  decay = 1,
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

  Optional custom association matrix used to define FDA-aware groups.

- group_method:

  Functional grouping backend: threshold-based or community-based.

- association_method:

  Association structure used to build FDA-aware groups.

- within_blocks:

  Should SelectBoost groups stay within functional blocks?

- bandwidth:

  Optional maximum within-block lag retained in groups.

- interval_groups, width, step, decay:

  Additional arguments passed to
  [`make_functional_grouping_function()`](https://fbertran.github.io/SelectBoost.FDA/reference/make_functional_grouping_function.md).

- ...:

  Additional arguments passed to
  [`SelectBoost::fastboost()`](https://fbertran.github.io/SelectBoost/reference/fastboost.html)
  or
  [`SelectBoost::autoboost()`](https://fbertran.github.io/SelectBoost/reference/autoboost.html).

## Value

An object of class `selectboost_fda_result`.
