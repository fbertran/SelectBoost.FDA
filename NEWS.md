# SelectBoost.FDA 0.6.1

- Added the named focused benchmark baseline
  `baseline_focused_benchmark_2026`, with a committed machine-readable grid
  definition at `inst/extdata/benchmarks/config_focused_baseline.yml`.
- Updated `tools/run_focused_benchmark.R` so generated benchmark CSV outputs
  carry package version, Git commit SHA when available, seed, replicate,
  method, scenario, representation, association method, bandwidth, selector,
  `B`, and `steps.seq`.
- Added quick, medium, and final focused benchmark profiles. The medium profile
  writes `benchmark_summary_n30.csv`; final n = 50 or n = 100 runs also write
  `benchmark_summary_n50_or_n100.csv`.
- Added paired simulation and benchmark seed columns plus
  `paired_gain_summary.csv`, including mean, standard deviation, standard
  error, win rate, valid paired replicate count, method-failure flags, and
  deterministic bootstrap confidence intervals for FDA-aware versus plain
  SelectBoost `F1` gains.
- Added `paired_gain_bootstrap_ci.csv` as a focused uncertainty table derived
  from replicate-level paired `F1` differences.
- Added Phase 8 assessment-oriented all-setting summaries:
  `assessment_top_positive_settings.csv`, `assessment_negative_gain_settings.csv`,
  `assessment_all_setting_summary.csv`, and `assessment_failure_modes.csv`. These make
  negative-gain settings and failure modes visible, and document the rule that
  best settings should be interpreted together with the all-setting summary.
- Added Phase 9 two-parameter perturbation-surface summaries to the focused
  benchmark driver. Runs now write `assessment_surface_summary.csv`,
  `assessment_monotonicity_summary.csv`, `assessment_precision_recall_paths.csv`, and
  `assessment_best_thresholds.csv` for representative scenario types, including
  fixed-threshold summaries at 0.5, 0.75, and 0.9 plus best-`F1` thresholds.
- Added Phase 10 association-geometry diagnostics to the focused benchmark
  driver. Runs now write `association_diagnostics.csv`,
  `association_group_size_summary.csv`, and
  `assessment_association_comparison_table.csv`, retaining benchmark setting keys
  for joins to performance summaries.
- Added Phase 11 method-comparison outputs to distinguish FDA-aware grouping
  from the base selector choice. Runs now write
  `method_comparison_summary.csv`, `method_comparison_runtime.csv`, and
  `assessment_method_comparison_table.csv`, with optional `glmnet`, `grpreg`, and
  `SGL` backends recorded as skipped when unavailable. Method-comparison
  metrics now retain `effective_variance_snr` when SNR-controlled simulations
  are used.
- Added Phase 12 runtime and computational reporting to the focused benchmark
  driver. Runs now write `runtime_by_setting.csv` and
  `runtime_by_method.csv`, with elapsed, user, and system time; warning and
  failure counts; selected-feature summaries; and fitted-object memory size
  where available. Failed settings are recorded as failed runtime rows instead
  of being silently dropped.
- Made the focused benchmark driver reproducible for fixed seeds by using a
  recorded deterministic SelectBoost perturbation backend by default, with
  `--upstream-rfast-rvmf` available for direct upstream-generator comparisons.
- Added Phase 4 simulation scenarios: `smooth_sparse`, `basis_block_signal`,
  `fpca_low_rank_signal`, `null_signal`, and `mislocalized_signal`, while
  retaining `localized_dense`, `confounded_blocks`, and the legacy
  `distributed_smooth` scenario. Null-signal runs now provide explicit empty
  ground truth for false-positive summaries.
- Added `benchmark_scenario_summary.csv` to the focused benchmark driver,
  summarizing scenario-level mean, standard deviation, and standard error for
  recovery and false-positive metrics.
- Added live focused-benchmark progress artifacts: `progress.tsv`,
  `benchmark_raw_metrics_checkpoint.csv`, and per-replicate raw-metric
  checkpoint files under `checkpoints/`, so long runs can be inspected before
  final summary files are written.
- Added setting-level focused-benchmark checkpointing with
  `--checkpoint-every=N` and `--checkpoint-every N`. Checkpoints now include
  numbered setting files, `checkpoints/benchmark_raw_metrics_latest.csv`, and
  append-only raw-metric checkpoint rows, while preserving the existing
  per-replicate checkpoint files.
- Added `--resume` preservation mode plus `RUNNING`, `COMPLETED`, and
  `run_metadata.yml` run markers. A completed or active output directory is
  protected from accidental reuse unless `--resume` is supplied; `--resume`
  preserves previous checkpoint files but does not yet skip completed settings.
- Added Phase 5 size-resolution controls to the focused benchmark driver:
  `--n-grid=50,100,200` and `--grid-length-grid=30,75,150`. Runs now keep
  `n`, `grid_length`, and per-setting elapsed-time columns in raw metrics, and
  write `benchmark_size_resolution_summary.csv` plus
  `benchmark_runtime_by_size_resolution.csv`.
- Added Phase 6 noise and signal-strength controls:
  `--snr-grid=0.5,1,2,4` for fixed-SNR comparisons and
  `--noise-sd-grid=0.5,1,2` for fixed-noise stress tests. Benchmark outputs
  now carry `noise_axis`, `snr`, `noise_sd`, `effective_snr`, and
  `effective_variance_snr`, and the driver writes `benchmark_noise_summary.csv`
  plus `benchmark_noise_f1_gain_panel.csv`. The `snr` argument is documented as
  a signal-to-noise standard-deviation ratio.
- Added Phase 13 campaign-level controls to `tools/run_focused_benchmark.R`:
  `--representation-grid`, `--scenario-grid`, `--n-grid`,
  `--grid-length-grid`, `--snr-grid`, `--noise-sd-grid`, `--q-grid`,
  `--c0-grid`, `--association-grid`, `--bandwidth-grid`,
  `--assessment-summary`, `--save-surfaces`,
  `--save-association-diagnostics`, `--bootstrap-reps`,
  `--checkpoint-every`, and `--surface-use-main-settings`. Generated
  benchmark configuration files now record these interface arguments so
  assessment and extended benchmark campaigns can be audited and reproduced.
  `--surface-use-main-settings` is documented as inheriting from the first
  representative row of the main simulation grid, not every main-grid setting.


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
