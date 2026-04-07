# Changelog

## SelectBoost.FDA 0.5.1

- Localized RNG handling in exported simulation and stability-selection
  functions so `seed=` no longer leaves the caller’s RNG state modified.
- Reworked the benchmark generation script so it writes to an explicit
  `--output-dir=...` path when supplied and otherwise defaults to
  [`tempdir()`](https://rdrr.io/r/base/tempfile.html), rather than
  writing into the package tree by default.
- Updated tests and top-level documentation to match the revised RNG and
  benchmark-output behavior.

## SelectBoost.FDA 0.5.0

- Added pkgdown website and a package-style README.
- Added targeted FDA benchmark sensitivity utilities with
  [`run_selectboost_sensitivity_study()`](https://fbertran.github.io/SelectBoost.FDA/reference/run_selectboost_sensitivity_study.md).
- Added simulation controls for `confounding_strength`,
  `active_region_scale`, and `local_correlation` so benchmarks can
  stress the settings where FDA-aware grouping is expected to help.
- Added shipped benchmark artifacts under `inst/extdata/benchmarks/`,
  including feature-level mean `F1` summaries and ranked
  [`selectboost_fda()`](https://fbertran.github.io/SelectBoost.FDA/reference/selectboost_fda.md)
  versus plain `SelectBoost` settings.
- Added a reproducible benchmark script in
  `tools/run_selectboost_sensitivity_study.R` and updated the benchmark
  vignette to read the saved study outputs directly.

## SelectBoost.FDA 0.4.0

- Added minimal examples to the core functions of the package
- Added a validation layer with
  [`plain_selectboost()`](https://fbertran.github.io/SelectBoost.FDA/reference/plain_selectboost.md),
  [`simulate_fda_scenario()`](https://fbertran.github.io/SelectBoost.FDA/reference/simulate_fda_scenario.md),
  [`evaluate_selection()`](https://fbertran.github.io/SelectBoost.FDA/reference/evaluate_selection.md),
  [`benchmark_selection_methods()`](https://fbertran.github.io/SelectBoost.FDA/reference/benchmark_selection_methods.md),
  and
  [`run_simulation_study()`](https://fbertran.github.io/SelectBoost.FDA/reference/run_simulation_study.md).
- Added mapped ground-truth utilities so feature-, group-, and
  basis-level recovery can be evaluated on transformed FDA designs.
- Added a simulation and benchmarks vignette plus release-hardening
  metadata for CI and pkgdown workflows.

## SelectBoost.FDA 0.3.0

- Added a broader selector interface with `lasso`, `group_lasso`, and
  `sparse_group_lasso` aliases, while keeping backend-specific names
  available.
- Added sparse-group lasso support through the `SGL` package.
- Added overlapping interval groups and region-aware association
  structures for FDA grouping.
- Added calibration helpers for stability-selection parameters, interval
  widths, and SelectBoost `c0` grids.
- Added method-comparison utilities to run grouped stability selection,
  interval stability selection, FDA-SelectBoost, and optional FDboost
  workflows on the same `fda_design`.
- Added a formula interface with
  [`fda_design_formula()`](https://fbertran.github.io/SelectBoost.FDA/reference/fda_design_formula.md),
  [`fit_stability_formula()`](https://fbertran.github.io/SelectBoost.FDA/reference/fit_stability_formula.md),
  and
  [`fit_selectboost_formula()`](https://fbertran.github.io/SelectBoost.FDA/reference/fit_selectboost_formula.md).

## SelectBoost.FDA 0.2.0

- Added FDA-native preprocessing objects for identity transforms, scalar
  standardization, spline-basis expansion, and FPCA.
- Added fitted preprocessing workflows with
  [`fit_fda_preprocessor()`](https://fbertran.github.io/SelectBoost.FDA/reference/fit_fda_preprocessor.md)
  and
  [`apply_fda_preprocessor()`](https://fbertran.github.io/SelectBoost.FDA/reference/apply_fda_preprocessor.md)
  so training and new-data transforms use the same mapping.
- Extended
  [`fda_design()`](https://fbertran.github.io/SelectBoost.FDA/reference/fda_design.md)
  to support multiple functional predictors, scalar covariates, optional
  fitted preprocessors, and richer reversible domain metadata.
- Standardized fit outputs across stability selection and SelectBoost
  with consistent [`print()`](https://rdrr.io/r/base/print.html),
  [`summary()`](https://rdrr.io/r/base/summary.html),
  [`selection_map()`](https://fbertran.github.io/SelectBoost.FDA/reference/selection_map.md),
  [`plot()`](https://rdrr.io/r/graphics/plot.default.html), and
  [`selected()`](https://fbertran.github.io/SelectBoost.FDA/reference/selected.md)
  behavior.
- Added packaged example datasets for end-to-end workflows and updated
  the vignettes to start from raw functional inputs.
- Expanded test coverage and refreshed package documentation for the
  FDA-native core API.

## SelectBoost.FDA 0.1.0

- Initial package release.
- Added grouped stability selection for functional predictors
  represented on grids or in basis form.
- Added FDA-aware SelectBoost wrappers, interval grouping helpers,
  plotting methods, and introductory vignettes.
