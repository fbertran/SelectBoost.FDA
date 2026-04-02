# Summarize Benchmark Performance by Method

Collapses raw benchmark rows into method-level performance summaries,
with an option to retain only the best `c0` per method and replication.

## Usage

``` r
summarise_benchmark_performance(
  x,
  level = c("feature", "group", "basis"),
  metric = "f1",
  optimize = c("max", "min"),
  select_c0 = c("best", "all")
)
```

## Arguments

- x:

  An `fda_benchmark` or `fda_simulation_study` object.

- level:

  Evaluation level.

- metric:

  Metric used to pick the best `c0` when `select_c0 = "best"`.

- optimize:

  Should larger or smaller values of `metric` be preferred?

- select_c0:

  Keep all `c0` rows or only the best one per method and replicate.

## Value

A data frame.
