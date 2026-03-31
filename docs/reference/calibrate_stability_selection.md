# Calibrate Stability-Selection Parameters

Runs grouped stability selection over a grid of subsampling fractions
and cutoff values.

## Usage

``` r
calibrate_stability_selection(
  design,
  selector = "group_lasso",
  sample_fraction_grid = c(0.5, 0.632, 0.75),
  cutoff_grid = c(0.6, 0.75, 0.9),
  keep_fits = FALSE,
  seed = NULL,
  ...
)
```

## Arguments

- design:

  An `fda_design` object.

- selector:

  Base selector passed to
  [`fit_stability()`](https://fbertran.github.io/SelectBoost.FDA/reference/fit_stability.md).

- sample_fraction_grid:

  Candidate subsampling fractions.

- cutoff_grid:

  Candidate cutoff values.

- keep_fits:

  Should the fitted objects be stored in the result?

- seed:

  Optional seed used to create deterministic per-grid seeds.

- ...:

  Additional arguments passed to
  [`fit_stability()`](https://fbertran.github.io/SelectBoost.FDA/reference/fit_stability.md).

## Value

An object of class `fda_calibration_grid`.
