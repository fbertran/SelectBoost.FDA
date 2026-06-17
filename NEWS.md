# SelectBoost.FDA 0.6.0

- Added a focused benchmarking and validation layer.
- Added `fit_perturbation_grid()`, `selection_surface()`,
  `selected_surface()`, and `summarise_perturbation_grid()` for
  two-parameter selection surfaces indexed by subject subsampling rate `q` and
  SelectBoost perturbation strength `c0`.
- Added renderer-neutral extractors for selection surfaces, monotonicity paths,
  precision-recall paths, association heatmaps, interval maps, and benchmark
  summaries.
- Added monotonicity diagnostics and post-processing helpers:
  `check_selection_monotonicity()`, `enforce_monotone_selection()`, and
  `summarise_monotonicity()`.
- Added precision-recall helpers: `precision_recall_curve_fda()`,
  `best_threshold_fda()`, and `summarise_precision_recall_fda()`.
- Added association diagnostics with `diagnose_functional_association()`,
  `summarise_association_structure()`, and `compare_association_methods()`.
- Added report extraction helpers and a CRAN-safe focused benchmark
  driver at `tools/run_focused_benchmark.R`; the driver writes only to
  `--output-dir` or to `tempdir()` by default.
- Added vignettes for perturbation grids, monotonicity/precision-recall paths,
  association diagnostics, and the focused benchmark workflow.

# SelectBoost.FDA 0.5.1

- Localized RNG handling in exported simulation and stability-selection
  functions so `seed=` no longer leaves the caller's RNG state modified.
- Reworked the benchmark generation script so it writes to an explicit
  `--output-dir=...` path when supplied and otherwise defaults to
  `tempdir()`, rather than writing into the package tree by default.
- Updated tests and top-level documentation to match the revised RNG and
  benchmark-output behavior.

# SelectBoost.FDA 0.5.0

- Added pkgdown website and a package-style README.
- Added targeted FDA benchmark sensitivity utilities with
  `run_selectboost_sensitivity_study()`.
- Added simulation controls for `confounding_strength`,
  `active_region_scale`, and `local_correlation` so benchmarks can stress the
  settings where FDA-aware grouping is expected to help.
- Added shipped benchmark artifacts under `inst/extdata/benchmarks/`,
  including feature-level mean `F1` summaries and ranked `selectboost_fda()`
  versus plain `SelectBoost` settings.
- Added a reproducible benchmark script in
  `tools/run_selectboost_sensitivity_study.R` and updated the benchmark
  vignette to read the saved study outputs directly.

# SelectBoost.FDA 0.4.0

- Added minimal examples to the core functions of the package
- Added a validation layer with `plain_selectboost()`,
  `simulate_fda_scenario()`, `evaluate_selection()`,
  `benchmark_selection_methods()`, and `run_simulation_study()`.
- Added mapped ground-truth utilities so feature-, group-, and basis-level
  recovery can be evaluated on transformed FDA designs.
- Added a simulation and benchmarks vignette plus release-hardening metadata
  for CI and pkgdown workflows.

# SelectBoost.FDA 0.3.0

- Added a broader selector interface with `lasso`, `group_lasso`, and `sparse_group_lasso` aliases, while keeping backend-specific names available.
- Added sparse-group lasso support through the `SGL` package.
- Added overlapping interval groups and region-aware association structures for FDA grouping.
- Added calibration helpers for stability-selection parameters, interval widths, and SelectBoost `c0` grids.
- Added method-comparison utilities to run grouped stability selection, interval stability selection, FDA-SelectBoost, and optional FDboost workflows on the same `fda_design`.
- Added a formula interface with `fda_design_formula()`, `fit_stability_formula()`, and `fit_selectboost_formula()`.

# SelectBoost.FDA 0.2.0

- Added FDA-native preprocessing objects for identity transforms, scalar standardization, spline-basis expansion, and FPCA.
- Added fitted preprocessing workflows with `fit_fda_preprocessor()` and `apply_fda_preprocessor()` so training and new-data transforms use the same mapping.
- Extended `fda_design()` to support multiple functional predictors, scalar covariates, optional fitted preprocessors, and richer reversible domain metadata.
- Standardized fit outputs across stability selection and SelectBoost with consistent `print()`, `summary()`, `selection_map()`, `plot()`, and `selected()` behavior.
- Added packaged example datasets for end-to-end workflows and updated the vignettes to start from raw functional inputs.
- Expanded test coverage and refreshed package documentation for the FDA-native core API.

# SelectBoost.FDA 0.1.0

- Initial package release.
- Added grouped stability selection for functional predictors represented on grids or in basis form.
- Added FDA-aware SelectBoost wrappers, interval grouping helpers, plotting methods, and introductory vignettes.
