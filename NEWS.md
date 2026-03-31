# SelectBoost.FDA News

## SelectBoost.FDA 0.5.0

- Added pkgdown website
- Added readme

## SelectBoost.FDA 0.4.0

- Added minimal examples to the core functions of the package
- Added a validation layer with `plain_selectboost()`,
  `simulate_fda_scenario()`, `evaluate_selection()`,
  `benchmark_selection_methods()`, and `run_simulation_study()`.
- Added mapped ground-truth utilities so feature-, group-, and basis-level
  recovery can be evaluated on transformed FDA designs.
- Added a simulation and benchmarks vignette plus release-hardening metadata
  for CI and pkgdown workflows.

## SelectBoost.FDA 0.3.0

- Added a broader selector interface with `lasso`, `group_lasso`, and `sparse_group_lasso` aliases, while keeping backend-specific names available.
- Added sparse-group lasso support through the `SGL` package.
- Added overlapping interval groups and region-aware association structures for FDA grouping.
- Added calibration helpers for stability-selection parameters, interval widths, and SelectBoost `c0` grids.
- Added method-comparison utilities to run grouped stability selection, interval stability selection, FDA-SelectBoost, and optional FDboost workflows on the same `fda_design`.
- Added a formula interface with `fda_design_formula()`, `fit_stability_formula()`, and `fit_selectboost_formula()`.

## SelectBoost.FDA 0.2.0

- Added FDA-native preprocessing objects for identity transforms, scalar standardization, spline-basis expansion, and FPCA.
- Added fitted preprocessing workflows with `fit_fda_preprocessor()` and `apply_fda_preprocessor()` so training and new-data transforms use the same mapping.
- Extended `fda_design()` to support multiple functional predictors, scalar covariates, optional fitted preprocessors, and richer reversible domain metadata.
- Standardized fit outputs across stability selection and SelectBoost with consistent `print()`, `summary()`, `selection_map()`, `plot()`, and `selected()` behavior.
- Added packaged example datasets for end-to-end workflows and updated the vignettes to start from raw functional inputs.
- Expanded test coverage and refreshed package documentation for the FDA-native core API.

## SelectBoost.FDA 0.1.0

- Initial package release.
- Added grouped stability selection for functional predictors represented on grids or in basis form.
- Added FDA-aware SelectBoost wrappers, interval grouping helpers, plotting methods, and introductory vignettes.
