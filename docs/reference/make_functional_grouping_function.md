# FDA-Aware Grouping Function for SelectBoost

Builds a closure that can be passed directly to `group=` in
[`SelectBoost::fastboost()`](https://fbertran.github.io/SelectBoost/reference/fastboost.html)
or
[`SelectBoost::autoboost()`](https://fbertran.github.io/SelectBoost/reference/autoboost.html).
The returned grouping function respects functional block boundaries and
can optionally restrict groups to local neighborhoods along the
observation grid.

## Usage

``` r
make_functional_grouping_function(
  x,
  association = NULL,
  method = c("threshold", "community"),
  association_method = c("correlation", "neighborhood", "hybrid", "interval"),
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

  Optional square association matrix. When omitted, the correlation
  matrix supplied by `SelectBoost` is reused after applying the
  FDA-specific masks.

- method:

  Grouping strategy. `"threshold"` wraps
  [`SelectBoost::group_func_1()`](https://fbertran.github.io/SelectBoost/reference/group_func_1.html)
  and `"community"` wraps
  [`SelectBoost::group_func_2()`](https://fbertran.github.io/SelectBoost/reference/group_func_2.html).

- association_method:

  Association structure passed to
  [`functional_association()`](https://fbertran.github.io/SelectBoost.FDA/reference/functional_association.md).

- within_blocks:

  Should groups be restricted to features coming from the same
  functional block?

- bandwidth:

  Optional maximum within-block lag retained in groups.

- interval_groups, width, step, decay:

  Additional arguments passed to
  [`functional_association()`](https://fbertran.github.io/SelectBoost.FDA/reference/functional_association.md)
  when using region-aware associations.

## Value

A function with signature `(absXcor, c0)` compatible with `SelectBoost`.
