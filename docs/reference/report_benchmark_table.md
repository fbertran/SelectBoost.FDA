# Report Benchmark Table

Extracts a compact benchmark comparison table for FDA-aware versus plain
SelectBoost.

## Usage

``` r
report_benchmark_table(x = NULL, top_n = 6L)
```

## Arguments

- x:

  Optional benchmark object or data frame. When omitted, the shipped
  saved sensitivity-study table is used if available.

- top_n:

  Number of rows to return.

## Value

A data frame with scenario, association, mean F1 values, delta, and win
rate.
