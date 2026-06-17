# Focused Benchmark Workflow

The focused benchmark workflow is designed to demonstrate where
FDA-aware SelectBoost improves on plain SelectBoost for functional
predictors: localized dense signals, confounded blocks, high local
correlation, and narrow active regions.

The driver script writes only to an explicit `--output-dir` or, when
omitted, to [`tempdir()`](https://rdrr.io/r/base/tempfile.html).

``` r
system2(
  file.path(R.home("bin"), "Rscript"),
  c(
    "tools/run_focused_benchmark.R",
    "--quick",
    "--n-replicates=1",
    "--seed=20260616",
    paste0("--output-dir=", file.path(tempdir(), "selectboost_fda_focused_benchmark"))
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
```
