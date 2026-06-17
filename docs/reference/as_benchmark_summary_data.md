# Extract Benchmark Summary Data

Produces benchmark summary rows suitable for tables and figures.

## Usage

``` r
as_benchmark_summary_data(
  x,
  level = NULL,
  metric = "f1",
  select_c0 = c("best", "all"),
  ...
)
```

## Arguments

- x:

  A benchmark object, simulation-study object, or benchmark data frame.

- level:

  Evaluation level. When omitted, summaries are returned for all levels
  present in `x`.

- metric:

  Metric used to choose best `c0` rows when applicable.

- select_c0:

  Passed to
  [`summarise_benchmark_performance()`](https://fbertran.github.io/SelectBoost.FDA/reference/summarise_benchmark_performance.md).

- ...:

  Additional arguments passed to benchmark summary helpers.

## Value

A data frame with mean and standard-deviation metric columns.
