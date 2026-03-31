# Calibrate Interval Widths

Runs interval stability selection over candidate interval widths.

## Usage

``` r
calibrate_interval_width(
  design,
  widths,
  step = NULL,
  overlap = FALSE,
  selector = "lasso",
  keep_fits = FALSE,
  seed = NULL,
  ...
)
```

## Arguments

- design:

  An `fda_design` object.

- widths:

  Candidate interval widths.

- step:

  Optional step size. Defaults to `widths`.

- overlap:

  Should the interval groups overlap?

- selector:

  Base selector passed to
  [`interval_stability_selection()`](https://fbertran.github.io/SelectBoost.FDA/reference/interval_stability_selection.md).

- keep_fits:

  Should the fitted objects be stored in the result?

- seed:

  Optional seed used to create deterministic per-grid seeds.

- ...:

  Additional arguments passed to
  [`interval_stability_selection()`](https://fbertran.github.io/SelectBoost.FDA/reference/interval_stability_selection.md).

## Value

An object of class `fda_calibration_grid`.
