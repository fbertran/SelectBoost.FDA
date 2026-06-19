# Focused Benchmark Workflow

The focused benchmark workflow is designed to demonstrate where
FDA-aware SelectBoost improves on plain SelectBoost for functional
predictors: localized dense signals, confounded blocks, high local
correlation, and narrow active regions.

The driver script writes only to an explicit `--output-dir` or, when
omitted, to [`tempdir()`](https://rdrr.io/r/base/tempfile.html). The
current named baseline is `baseline_focused_benchmark_2026`. Its grid
definition is stored in
`inst/extdata/benchmarks/config_focused_baseline.yml`, and each run
writes a copy named `benchmark_config_baseline.yml` beside the CSV
outputs.

Three run profiles are available:

- `--quick --n-replicates=1` keeps the smoke-test benchmark small.
- `--medium` runs the n = 30 benchmark and writes
  `benchmark_summary_n30.csv`.
- `--final` runs the n = 50 benchmark and also writes
  `benchmark_summary_n50_or_n100.csv`.

All raw metrics include the replicate index, simulation seed, benchmark
seed, and method metadata. Summary tables include means, standard
deviations, standard errors, and `paired_gain_summary.csv` reports
paired `F1` gains for FDA-aware SelectBoost over plain SelectBoost. The
paired comparison is computed as a replicate-level difference,
`F1_selectboost_fda - F1_plain_selectboost`, for each matched setting.
The driver also writes `paired_gain_bootstrap_ci.csv` with deterministic
percentile bootstrap confidence intervals, win rates, valid paired
replicate counts, and method-failure flags. Long runs also update
`progress.tsv` after study, replicate, simulation, and setting
milestones; append `benchmark_raw_metrics_checkpoint.csv` at the cadence
set by `--checkpoint-every=N` and at each completed replicate; write
setting-level checkpoint files to
`checkpoints/benchmark_raw_metrics_settingNNNNNN.csv`; overwrite
`checkpoints/benchmark_raw_metrics_latest.csv` with the latest
checkpointed setting; and write per-replicate raw metrics to
`checkpoints/benchmark_raw_metrics_repNNN.csv`. Each run writes
`run_metadata.yml`, creates `RUNNING` while active, writes `COMPLETED`
on successful completion, and removes `RUNNING` only after success. Use
distinct `--output-dir` values for parallel runs. `--resume` preserves
previous checkpoint files but does not yet skip completed settings. For
reproducibility, the driver uses a recorded deterministic SelectBoost
perturbation backend by default. Pass `--upstream-rfast-rvmf` only when
comparing against the upstream `Rfast` perturbation generator directly.

For assessment interpretation, use `benchmark_best_settings.csv` only
together with `assessment_all_setting_summary.csv`. The driver also
writes `assessment_top_positive_settings.csv`,
`assessment_negative_gain_settings.csv`, and
`assessment_failure_modes.csv`, so the report can state both where
FDA-aware grouping helps and where it loses against plain SelectBoost. A
short defensible interpretation is: FDA-aware grouping is most useful in
settings with local correlation and localized signal, but its advantage
is not uniform; negative gain rows and failure-mode labels should be
shown alongside top positive gains.

The driver also produces a compact two-parameter perturbation analysis
for representative scenario types. It evaluates selection surfaces
`(q, c0) -> Pi_hat_j(q, c0)` on a smoke-test grid in `--quick` runs and
on the baseline grid `q = 0.5, 0.632, 0.8` crossed with
`c0 = 0.9, 0.7, 0.5, 0.3` in larger runs. The outputs are
`assessment_surface_summary.csv`, `assessment_monotonicity_summary.csv`,
`assessment_precision_recall_paths.csv`, and
`assessment_best_thresholds.csv`. Together they support heatmap-like
summaries, monotonicity checks across the two axes, precision-recall
paths, the best threshold by `F1`, and fixed-threshold summaries at
`0.5`, `0.75`, and `0.9`.

Association geometry is measured separately from selection performance.
The driver writes `association_diagnostics.csv` with sparsity, mean and
median association, within-block and cross-block mass, local and
nonlocal mass, and effective degree. It also writes
`association_group_size_summary.csv` with the number of induced groups
and group-size summaries at each `c0`, plus
`assessment_association_comparison_table.csv` for compact method
comparisons. The diagnostic tables retain the same scenario,
representation, size, noise, and association-setting keys used by the
benchmark metrics.

Method comparison is measured separately from the main FDA-versus-plain
SelectBoost contrast. The driver writes `method_comparison_summary.csv`,
`method_comparison_runtime.csv`, and
`assessment_method_comparison_table.csv` for seven labeled methods:
`plain_selectboost`, `selectboost_fda_lasso`,
`selectboost_fda_group_lasso`, `selectboost_fda_sparse_group_lasso`,
`stability_lasso`, `stability_group_lasso`, and
`stability_sparse_group_lasso`. These labels keep perturbation type
separate from base selector choice. Optional backends are guarded with
package checks: `glmnet` for lasso, `grpreg` for group lasso, and `SGL`
for sparse-group lasso. Missing packages produce skipped rows in the
runtime and assessment tables rather than aborting the benchmark.

Runtime reporting is available at two granularities.
`runtime_by_setting.csv` keeps one row per main benchmark method and
setting, including elapsed time, user time, system time, warning and
failure counts, selected-feature summaries, and fitted-object memory
size where available. `runtime_by_method.csv` summarizes the same
diagnostics by method and runtime source, combining the main benchmark
and method-comparison runs. Failed settings are represented as failed
runtime rows, so they can be counted in assessment tables instead of
being silently dropped.

Size-resolution sensitivity is controlled with comma-separated grids:
`--n-grid=50,100,200` and `--grid-length-grid=30,75,150`. These values
are crossed with the scenario, representation, and SelectBoost setting
grids. The driver writes `benchmark_size_resolution_summary.csv` for
recovery metrics by `n` and `grid_length`, plus
`benchmark_runtime_by_size_resolution.csv` for runtime summaries at the
corresponding setting level.

Noise and signal-strength sensitivity are controlled with
`--snr-grid=0.5,1,2,4` and `--noise-sd-grid=0.5,1,2`. The fixed-SNR grid
is the recommended axis for the main method comparison because it keeps
relative difficulty comparable across scenarios, representations, and
signal structures. The fixed-noise grid is useful as a stress test for
absolute observation noise. Both axes are recorded in the raw metrics
and summaries through `noise_axis`, `snr`, `noise_sd`, `effective_snr`,
and `effective_variance_snr`. Here `snr` is a signal-to-noise
standard-deviation ratio; `effective_variance_snr` is `effective_snr^2`
for variance-ratio reporting. The driver writes
`benchmark_noise_summary.csv` for performance by noise condition and
`benchmark_noise_f1_gain_panel.csv` for a plot-ready `F1` gain panel.

## Campaign interface

The driver accepts comma-separated grids for assessment and extended
benchmark campaigns:

- `--representation-grid=grid,bspline,fpca` chooses the functional
  encoding.
- `--scenario-grid=localized_dense,confounded_blocks,smooth_sparse`
  chooses the simulation scenarios.
- `--n-grid=50,100,200` and `--grid-length-grid=30,75,150` choose sample
  size and functional resolution.
- `--snr-grid=0.5,1,2,4` and `--noise-sd-grid=0.5,1,2` choose fixed-SNR
  and fixed-noise sensitivity axes.
- `--q-grid=0.5,0.632,0.8` and `--c0-grid=0.9,0.7,0.5,0.3` choose the
  subsampling and SelectBoost perturbation surface.
- `--association-grid=correlation,neighborhood,hybrid,interval` and
  `--bandwidth-grid=4,8` choose the FDA-aware grouping geometry.
- `--bootstrap-reps=2000` controls the deterministic bootstrap used for
  paired `F1` gain confidence intervals.
- `--checkpoint-every=100` controls setting-level raw-metric checkpoint
  frequency; use `--checkpoint-every=1` when every completed setting
  should be materialized immediately.
- `--resume` preserves existing checkpoint files in an output directory
  but does not yet skip previously completed settings.
- `--surface-use-main-settings` makes surface diagnostics inherit `n`,
  `grid_length`, and noise/SNR from the first representative row of the
  main simulation grid. It does not run surface diagnostics for every
  main-grid setting.

Assessment-oriented summaries, perturbation surfaces, and association
diagnostics are written by default for compatibility with the saved
baseline outputs. Use `--assessment-summary`, `--save-surfaces`, and
`--save-association-diagnostics` to make that choice explicit in command
logs. For lighter local runs, use `--no-save-surfaces` or
`--no-save-association-diagnostics` to skip the heavier optional
diagnostics. The broader `--no-assessment-summary` shortcut disables
both of those optional diagnostic families while keeping the core
benchmark and paired-gain tables.

``` r

system2(
  file.path(R.home("bin"), "Rscript"),
  c(
    "tools/run_focused_benchmark.R",
    "--quick",
    "--n-replicates=1",
    "--seed=20260616",
    "--n-grid=50,100",
    "--grid-length-grid=30,75",
    "--snr-grid=0.5,1,2,4",
    "--checkpoint-every=1",
    paste0("--output-dir=", file.path(tempdir(), "selectboost_fda_focused_benchmark"))
  )
)
```

``` r

system2(
  file.path(R.home("bin"), "Rscript"),
  c(
    "tools/run_focused_benchmark.R",
    "--medium",
    "--seed=20260616",
    "--representation-grid=grid,bspline",
    "--scenario-grid=localized_dense,confounded_blocks,smooth_sparse",
    "--n-grid=50,100",
    "--grid-length-grid=30,75",
    "--snr-grid=0.5,1,2,4",
    "--q-grid=0.5,0.632,0.8",
    "--c0-grid=0.9,0.7,0.5,0.3",
    "--association-grid=correlation,neighborhood,hybrid,interval",
    "--bandwidth-grid=4,8",
    "--checkpoint-every=100",
    "--assessment-summary",
    "--save-surfaces",
    "--surface-use-main-settings",
    "--save-association-diagnostics",
    "--bootstrap-reps=2000",
    paste0("--output-dir=", file.path(tempdir(), "selectboost_fda_focused_campaign"))
  )
)
```

``` r

system2(
  file.path(R.home("bin"), "Rscript"),
  c(
    "tools/run_focused_benchmark.R",
    "--medium",
    "--seed=20260616",
    paste0("--output-dir=", file.path(tempdir(), "selectboost_fda_focused_n30"))
  )
)
```

The package also exposes table extractors for report material.

``` r

library(SelectBoost.FDA)

report_summary_table()
#>             Component
#> 1     Row subsampling
#> 2 Column perturbation
#> 3 Functional grouping
#> 4   Selection surface
#> 5    Path diagnostics
#> 6  Benchmark evidence
#>                                                                           Role
#> 1                          Estimate stability frequencies at the subject level
#> 2                       Perturb correlated features through SelectBoost groups
#> 3            Respect curve blocks, intervals, basis blocks, or FPCA components
#> 4              Track selection over subsampling rate and perturbation strength
#> 5                       Summarize monotonicity and precision-recall trade-offs
#> 6 Compare FDA-aware SelectBoost with plain SelectBoost and stability baselines
#>                                                        Output
#> 1                                       q-indexed frequencies
#> 2                                      c0-indexed proportions
#> 3                    feature, group, interval, and basis maps
#> 4                                (q, c0) selection data frame
#> 5                        diagnostic and threshold-path tables
#> 6 mean F1, Jaccard, recall, precision, and win-rate summaries
report_method_table()
#>                         Method
#> 1  Grouped stability selection
#> 2 Interval stability selection
#> 3        FDA-aware SelectBoost
#> 4            Plain SelectBoost
#> 5  FDboost stability selection
#>                                                     Perturbation
#> 1                                            Subject subsampling
#> 2                                            Subject subsampling
#> 3 Subject subsampling plus correlation-aware column perturbation
#> 4                          Correlation-aware column perturbation
#> 5                                       Model-native subsampling
#>                                         Group structure
#> 1                  Functional blocks or supplied groups
#> 2                                      Domain intervals
#> 3 Correlation, neighborhood, hybrid, or interval groups
#> 4     Correlation-driven groups on the flattened matrix
#> 5                              Functional model effects
#>                                                   Output
#> 1                          Feature and group frequencies
#> 2                                   Interval frequencies
#> 3 Feature, group, basis, and interval selection surfaces
#> 4                Feature and group selection proportions
#> 5                Functional-effect stability frequencies
#>                                      Best suited for
#> 1                       General grouped FDA recovery
#> 2  Interpretable selected time or wavelength regions
#> 3 Dense functional correlation and confounded blocks
#> 4            Finite-dimensional baseline comparisons
#> 5        Already specified FDboost regression models
report_formula_blocks()[c("selection_surface", "precision_recall")]
#> $selection_surface
#> [1] "(q,c_0)\\longmapsto \\widehat{\\Pi}_j(q,c_0)"
#> 
#> $precision_recall
#> [1] "\\mathrm{Precision}=\\frac{|\\widehat S\\cap S^\\star|}{|\\widehat S|},\\quad \\mathrm{Recall}=\\frac{|\\widehat S\\cap S^\\star|}{|S^\\star|}"
```

Saved sensitivity-study artifacts shipped with the package can be turned
into a compact benchmark table:

``` r

report_benchmark_table(top_n = 5)
#>            Scenario  Association Bandwidth F1 FDA-aware  F1 plain      Delta
#> 1 confounded_blocks     interval         8    0.5362319 0.4087266 0.12750533
#> 2 confounded_blocks       hybrid         4    0.5885135 0.4826750 0.10583853
#> 3 confounded_blocks       hybrid         4    0.5833671 0.4944862 0.08888092
#> 4   localized_dense neighborhood         4    0.4972542 0.4144859 0.08276831
#> 5 confounded_blocks       hybrid         4    0.5429293 0.4657088 0.07722048
#>    Win rate
#> 1 1.0000000
#> 2 1.0000000
#> 3 1.0000000
#> 4 0.6666667
#> 5 0.6666667
```

For new benchmark objects, use the renderer-neutral summary extractor:

``` r

metrics <- data.frame(
  scenario = "localized_dense",
  representation = "grid",
  family = "gaussian",
  method = c("selectboost", "plain_selectboost"),
  level = "feature",
  precision = c(0.8, 0.6),
  recall = c(0.7, 0.6),
  f1 = c(0.746, 0.6),
  jaccard = c(0.59, 0.43),
  selection_rate = c(0.2, 0.3),
  stringsAsFactors = FALSE
)

as_benchmark_summary_data(metrics)
#>                                                                scenario
#> localized_dense.grid.gaussian.plain_selectboost.feature localized_dense
#> localized_dense.grid.gaussian.selectboost.feature       localized_dense
#>                                                         representation   family
#> localized_dense.grid.gaussian.plain_selectboost.feature           grid gaussian
#> localized_dense.grid.gaussian.selectboost.feature                 grid gaussian
#>                                                                    method
#> localized_dense.grid.gaussian.plain_selectboost.feature plain_selectboost
#> localized_dense.grid.gaussian.selectboost.feature             selectboost
#>                                                           level
#> localized_dense.grid.gaussian.plain_selectboost.feature feature
#> localized_dense.grid.gaussian.selectboost.feature       feature
#>                                                         association_method
#> localized_dense.grid.gaussian.plain_selectboost.feature                 NA
#> localized_dense.grid.gaussian.selectboost.feature                       NA
#>                                                         bandwidth group_method
#> localized_dense.grid.gaussian.plain_selectboost.feature        NA           NA
#> localized_dense.grid.gaussian.selectboost.feature              NA           NA
#>                                                         within_blocks n_rep
#> localized_dense.grid.gaussian.plain_selectboost.feature            NA     1
#> localized_dense.grid.gaussian.selectboost.feature                  NA     1
#>                                                         precision_mean
#> localized_dense.grid.gaussian.plain_selectboost.feature            0.6
#> localized_dense.grid.gaussian.selectboost.feature                  0.8
#>                                                         precision_sd
#> localized_dense.grid.gaussian.plain_selectboost.feature            0
#> localized_dense.grid.gaussian.selectboost.feature                  0
#>                                                         recall_mean recall_sd
#> localized_dense.grid.gaussian.plain_selectboost.feature         0.6         0
#> localized_dense.grid.gaussian.selectboost.feature               0.7         0
#>                                                         f1_mean f1_sd
#> localized_dense.grid.gaussian.plain_selectboost.feature   0.600     0
#> localized_dense.grid.gaussian.selectboost.feature         0.746     0
#>                                                         jaccard_mean jaccard_sd
#> localized_dense.grid.gaussian.plain_selectboost.feature         0.43          0
#> localized_dense.grid.gaussian.selectboost.feature               0.59          0
#>                                                         selection_rate_mean
#> localized_dense.grid.gaussian.plain_selectboost.feature                 0.3
#> localized_dense.grid.gaussian.selectboost.feature                       0.2
#>                                                         selection_rate_sd
#> localized_dense.grid.gaussian.plain_selectboost.feature                 0
#> localized_dense.grid.gaussian.selectboost.feature                       0
#>                                                         effective_snr_mean
#> localized_dense.grid.gaussian.plain_selectboost.feature                 NA
#> localized_dense.grid.gaussian.selectboost.feature                       NA
#>                                                         effective_snr_sd
#> localized_dense.grid.gaussian.plain_selectboost.feature               NA
#> localized_dense.grid.gaussian.selectboost.feature                     NA
#>                                                         effective_variance_snr_mean
#> localized_dense.grid.gaussian.plain_selectboost.feature                          NA
#> localized_dense.grid.gaussian.selectboost.feature                                NA
#>                                                         effective_variance_snr_sd
#> localized_dense.grid.gaussian.plain_selectboost.feature                        NA
#> localized_dense.grid.gaussian.selectboost.feature                              NA
```
