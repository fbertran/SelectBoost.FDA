# Run a Repeated FDA Simulation Study

Repeats
[`simulate_fda_scenario()`](https://fbertran.github.io/SelectBoost.FDA/reference/simulate_fda_scenario.md)
and
[`benchmark_selection_methods()`](https://fbertran.github.io/SelectBoost.FDA/reference/benchmark_selection_methods.md)
over multiple replications and aggregates the resulting recovery
metrics.

## Usage

``` r
run_simulation_study(
  n_rep = 10L,
  simulate_args = list(),
  benchmark_args = list(),
  seed = NULL,
  keep_results = FALSE
)
```

## Arguments

- n_rep:

  Number of simulation replications.

- simulate_args:

  Named list forwarded to
  [`simulate_fda_scenario()`](https://fbertran.github.io/SelectBoost.FDA/reference/simulate_fda_scenario.md).

- benchmark_args:

  Named list forwarded to
  [`benchmark_selection_methods()`](https://fbertran.github.io/SelectBoost.FDA/reference/benchmark_selection_methods.md).

- seed:

  Optional seed used to derive deterministic per-replication seeds.

- keep_results:

  Should the individual benchmark objects be returned?

## Value

An object of class `fda_simulation_study`.
