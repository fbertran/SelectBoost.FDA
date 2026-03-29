# SelectBoost.FDA News

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
