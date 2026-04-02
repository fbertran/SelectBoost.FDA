# Summarize the Advantage of FDA-SelectBoost Over Baselines

Computes the per-scenario and per-level gain of a target method over one
or more reference methods. This is intended to make the benchmark story
explicit when comparing FDA-aware `SelectBoost` to existing baselines.

## Usage

``` r
summarise_benchmark_advantage(
  x,
  target = "selectboost",
  reference = c("plain_selectboost", "stability"),
  level = c("feature", "group", "basis"),
  metric = "f1",
  optimize = c("max", "min"),
  select_c0 = c("best", "all")
)
```

## Arguments

- x:

  An `fda_benchmark` or `fda_simulation_study` object.

- target:

  Method whose gain should be assessed.

- reference:

  One or more baseline methods.

- level:

  Evaluation level.

- metric:

  Metric used both for best-`c0` selection and for the reported gains.

- optimize:

  Should larger or smaller values of `metric` be preferred?

- select_c0:

  Keep all `c0` rows or only the best one per method and replicate.

## Value

A data frame.
