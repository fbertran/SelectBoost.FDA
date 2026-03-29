# SelectBoost.FDA

`SelectBoost.FDA` is an R package scaffold for variable selection in functional
data analysis, with an emphasis on highly correlated discretized curves and
basis-expanded predictors.

It currently implements three complementary layers:

1. `fdboost_stability_selection()`: an optional adapter to the native
   `FDboost` stability-selection workflow when your model is already fitted with
   `FDboost`.
2. `stability_selection_fda()` and `interval_stability_selection()`: generic
   subject-level subsampling routines for basis expansions, FPCA scores, and
   interval-based summaries.
3. `selectboost_fda()`: an FDA-aware wrapper around `SelectBoost::fastboost()`
   and `SelectBoost::autoboost()` with block-constrained and region-aware
   grouping.

## Core workflow

Functional predictors can be supplied either as a plain matrix or as a named
list of blocks. List inputs preserve block membership automatically.

```r
library(SelectBoost.FDA)

set.seed(123)
n <- 80
signal <- cbind(
  rnorm(n),
  rnorm(n),
  rnorm(n)
)
noise <- cbind(
  rnorm(n),
  rnorm(n),
  rnorm(n)
)
y <- 1.5 * signal[, 1] - signal[, 2] + rnorm(n, sd = 0.4)

x <- list(signal = signal, noise = noise)

fda_x <- as_functional_matrix(x)
functional_block_groups(x)
functional_interval_groups(x, width = 2)
```

## Generic grouped stability selection

```r
stab <- stability_selection_fda(
  x = x,
  y = y,
  selector = "grpreg",
  B = 50,
  seed = 1
)

stab$group_frequency
stab$selected_groups
```

For interval-level interpretation:

```r
interval_stab <- interval_stability_selection(
  x = x,
  y = y,
  width = 2,
  selector = "glmnet",
  B = 50,
  seed = 1
)

interval_stab$interval_table
interval_stab$group_frequency
```

## FDA-aware SelectBoost

`selectboost_fda()` reuses the core perturbation engine from `SelectBoost` while
constraining grouping to functional blocks or local neighborhoods:

```r
sb <- selectboost_fda(
  x = x,
  y = y,
  selector = "glmnet",
  mode = "fast",
  steps.seq = c(0.6, 0.2),
  B = 20
)

sb$feature_selection
```

You can also build a custom grouping function up front:

```r
group_fn <- make_functional_grouping_function(
  x,
  method = "threshold",
  within_blocks = TRUE,
  bandwidth = 1
)
```

## Notes

- `FDboost` is kept optional because it is not required for the generic or
  SelectBoost-based workflows.
- Built-in selectors currently support `glmnet` and `grpreg`, and both
  stability-selection interfaces accept user-defined selector functions.
- Interval grouping in the grouped-stability interface uses non-overlapping
  regions, which fits `grpreg` and similar grouped selectors cleanly.
