# SelectBoost.FDA ![](reference/figures/logo_selectboost_FDA.png)

## Frédéric Bertrand

`SelectBoost.FDA` is an R package for variable selection in functional
data analysis. It combines FDA-native preprocessing and design objects
with grouped stability selection, interval summaries, FDA-aware
`SelectBoost`, and a small validation layer for simulation and
benchmarking.

The package is designed for workflows where functional predictors are
observed on a grid, represented through basis expansions, or reduced to
FPCA scores, and where strong local or block-wise correlation makes
ordinary variable selection unstable.

## Main features

- FDA-native design objects built directly from raw curves, basis
  representations, FPCA scores, and scalar covariates.
- Train/test-safe preprocessing with identity transforms,
  standardization, spline-basis expansion, and FPCA.
- Grouped stability selection for functional blocks and interval
  summaries.
- FDA-aware `SelectBoost` wrappers plus a plain `SelectBoost` baseline.
- Simulation, benchmark, and evaluation helpers with mapped ground
  truth.
- Shipped sensitivity-study benchmark summaries for direct mean `F1`
  comparisons between
  [`selectboost_fda()`](https://fbertran.github.io/SelectBoost.FDA/reference/selectboost_fda.md)
  and plain `SelectBoost`.
- Seeded simulation and stability-selection workflows that keep RNG
  changes local to the function call.

## Installation

You can install the development version from GitHub with:

``` r
# install.packages("remotes")
remotes::install_github("bertran7/SelectBoost.FDA")
```

Some workflows rely on optional backends:

- `glmnet` for lasso-based grouped stability selection.
- `grpreg` for group lasso.
- `SGL` for sparse-group lasso.
- `FDboost` and `stabs` for the native `FDboost` stability-selection
  route.

## A first FDA-native workflow

The package ships with small example datasets so the full workflow can
start from raw functional inputs.

``` r
data("spectra_example", package = "SelectBoost.FDA")

idx <- 1:30

design <- fda_design(
  response = spectra_example$response[idx],
  predictors = list(
    signal = fda_grid(
      spectra_example$predictors$signal[idx, ],
      argvals = spectra_example$grid,
      name = "signal",
      unit = "nm"
    ),
    nuisance = fda_grid(
      spectra_example$predictors$nuisance[idx, ],
      argvals = spectra_example$grid,
      name = "nuisance",
      unit = "nm"
    )
  ),
  scalar_covariates = spectra_example$scalar_covariates[idx, ],
  transforms = list(
    signal = fda_fpca(n_components = 3),
    nuisance = fda_bspline(df = 5)
  ),
  scalar_transform = fda_standardize(),
  family = "gaussian"
)

summary(design)
#> FDA design summary
#>   observations: 30 
#>   features: 10 
#>   family: gaussian 
#>   response available: TRUE 
#>   functional predictors: 2 
#>   scalar covariates: 2 
#>  predictor representation n_features
#>   nuisance          basis          5
#>     signal          basis          3
#>        age         scalar          1
#>  treatment         scalar          1
head(selection_map(design, level = "basis"))
#>                 predictor representation basis_type source_representation n_components
#> nuisance.spline  nuisance          basis     spline                  grid            5
#> signal.fpca        signal          basis       fpca                  grid            3
#>                 first_component last_component         components domain_start domain_end
#> nuisance.spline              B1             B5 B1, B2, B3, B4, B5         1100       2500
#> signal.fpca                 PC1            PC3      PC1, PC2, PC3         1100       2500
```

## FDA-aware SelectBoost

`SelectBoost.FDA` extends `SelectBoost` with block-aware and
region-aware grouping while keeping the original perturbation engine.

``` r
fit_sb <- fit_selectboost(
  design,
  mode = "fast",
  steps.seq = c(0.6, 0.3),
  c0lim = FALSE,
  B = 4
)

summary(fit_sb)
#> FDA SelectBoost summary
#>   family: gaussian 
#>   predictors: 4 
#>   mode: fast 
#>   features: 10 
#>   groups: 4 
#>   c0 values: 2
head(selection_map(fit_sb, level = "group", c0 = colnames(fit_sb$feature_selection)[1]))
#>   predictor group_id     group representation basis_type source_representation n_features
#> 1    signal        1    signal          basis       fpca                  grid          3
#> 2  nuisance        2  nuisance          basis     spline                  grid          5
#> 3       age        3       age         scalar                           scalar          1
#> 4 treatment        4 treatment         scalar                           scalar          1
#>   start_position end_position start_argval end_argval domain_start domain_end       c0
#> 1              1            3          PC1        PC3         1100       2500 c0 = 0.6
#> 2              1            5           B1         B5         1100       2500 c0 = 0.6
#> 3              1            1          age        age          age        age c0 = 0.6
#> 4              1            1    treatment  treatment    treatment  treatment c0 = 0.6
#>   mean_selection max_selection selected_features
#> 1      0.6666667          1.00                 2
#> 2      0.3000000          0.50                 4
#> 3      0.7500000          0.75                 1
#> 4      1.0000000          1.00                 1
```

## Grouped stability selection

Grouped stability selection is available through a common FDA interface.
The lasso route below requires the optional `glmnet` package.

``` r
if (requireNamespace("glmnet", quietly = TRUE)) {
  fit_stab <- fit_stability(
    design,
    selector = "lasso",
    B = 8,
    cutoff = 0.5,
    seed = 1
  )

  summary(fit_stab)
  head(selection_map(fit_stab, level = "group"))
}
#>   predictor group_id     group representation basis_type source_representation n_features
#> 1    signal        1    signal          basis       fpca                  grid          3
#> 2  nuisance        2  nuisance          basis     spline                  grid          5
#> 3       age        3       age         scalar                           scalar          1
#> 4 treatment        4 treatment         scalar                           scalar          1
#>   start_position end_position start_argval end_argval domain_start domain_end
#> 1              1            3          PC1        PC3         1100       2500
#> 2              1            5           B1         B5         1100       2500
#> 3              1            1          age        age          age        age
#> 4              1            1    treatment  treatment    treatment  treatment
#>   mean_feature_frequency max_feature_frequency selected_features group_frequency
#> 1              0.4166667                 0.750                 2           0.750
#> 2              0.0500000                 0.125                 0           0.125
#> 3              0.0000000                 0.000                 0           0.000
#> 4              0.2500000                 0.250                 0           0.250
#>   group_selected
#> 1           TRUE
#> 2          FALSE
#> 3          FALSE
#> 4          FALSE
```

Interval summaries can be requested directly:

``` r
if (requireNamespace("glmnet", quietly = TRUE)) {
  fit_interval <- interval_stability_selection(
    x = design,
    selector = "lasso",
    width = 4,
    B = 8,
    cutoff = 0.5,
    seed = 1
  )

  head(selection_map(fit_interval, level = "group"))
}
#>   predictor group_id          group representation basis_type source_representation
#> 1    signal        1    signal[1:3]          basis       fpca                  grid
#> 2  nuisance        2  nuisance[1:4]          basis     spline                  grid
#> 3  nuisance        3  nuisance[5:5]          basis     spline                  grid
#> 4       age        4       age[1:1]         scalar                           scalar
#> 5 treatment        5 treatment[1:1]         scalar                           scalar
#>   n_features start_position end_position start_argval end_argval     domain_start
#> 1          3              1            3          PC1        PC3             1100
#> 2          4              1            4           B1         B4             1100
#> 3          1              5            5           B5         B5 1817.94871794872
#> 4          1              1            1          age        age              age
#> 5          1              1            1    treatment  treatment        treatment
#>         domain_end mean_feature_frequency max_feature_frequency selected_features
#> 1             2500              0.4166667                 0.750                 2
#> 2 2464.10256410256              0.0625000                 0.125                 0
#> 3             2500              0.0000000                 0.000                 0
#> 4              age              0.0000000                 0.000                 0
#> 5        treatment              0.2500000                 0.250                 0
#>   group_frequency group_selected interval_start interval_end interval_label
#> 1           0.750           TRUE              1            3    signal[1:3]
#> 2           0.125          FALSE              1            4  nuisance[1:4]
#> 3           0.000          FALSE              5            5  nuisance[5:5]
#> 4           0.000          FALSE              1            1       age[1:1]
#> 5           0.250          FALSE              1            1 treatment[1:1]
```

## Benchmarking on simulated FDA designs

The validation layer can be used to compare FDA-aware `SelectBoost` with
a plain `SelectBoost` baseline on the same simulated design and mapped
truth. When you pass `seed=`, the package uses a local seeded scope and
does not leave the global RNG state changed after the call returns.

``` r
sim <- simulate_fda_scenario(
  n = 30,
  grid_length = 20,
  representation = "grid",
  seed = 1
)

bench <- benchmark_selection_methods(
  sim,
  methods = c("selectboost", "plain_selectboost"),
  levels = c("feature", "group"),
  selectboost_args = list(B = 3, steps.seq = 0.5, c0lim = FALSE),
  plain_selectboost_args = list(B = 3, steps.seq = 0.5, c0lim = FALSE)
)

head(bench$metrics)
#>     level n_universe n_truth n_selected tp fp fn tn precision recall specificity        f1
#> 1 feature         42       9         35  9 26  0  7 0.2571429      1   0.2121212 0.4090909
#> 2 feature         42       9         36  9 27  0  6 0.2500000      1   0.1818182 0.4000000
#> 3   group          4       3          4  3  1  0  0 0.7500000      1   0.0000000 0.8571429
#> 4   group          4       3          4  3  1  0  0 0.7500000      1   0.0000000 0.8571429
#>     jaccard selection_rate       c0            method        scenario representation
#> 1 0.2571429      0.8333333 c0 = 0.5       selectboost localized_dense           grid
#> 2 0.2500000      0.8571429 c0 = 0.5 plain_selectboost localized_dense           grid
#> 3 0.7500000      1.0000000 c0 = 0.5       selectboost localized_dense           grid
#> 4 0.7500000      1.0000000 c0 = 0.5 plain_selectboost localized_dense           grid
#>     family
#> 1 gaussian
#> 2 gaussian
#> 3 gaussian
#> 4 gaussian
```

The package also ships a larger saved sensitivity study under
`inst/extdata/benchmarks/`, generated by
`tools/run_selectboost_sensitivity_study.R`. That script writes to an
explicit `--output-dir=...` path when supplied, and otherwise defaults
to a subdirectory of
[`tempdir()`](https://rdrr.io/r/base/tempfile.html), so it does not
write into the package directory by default. The committed files under
`inst/extdata/benchmarks/` are a saved copy of one benchmark run. The
top-setting table keeps the FDA benchmark settings together with the
mean `F1` score of both algorithms.

``` r
benchmark_dir <- system.file("extdata", "benchmarks", package = "SelectBoost.FDA")
top_settings <- utils::read.csv(
  file.path(benchmark_dir, "selectboost_sensitivity_top_settings.csv"),
  stringsAsFactors = FALSE
)

utils::head(
  top_settings[
    ,
    c(
      "scenario",
      "confounding_strength",
      "active_region_scale",
      "local_correlation",
      "association_method",
      "bandwidth",
      "selectboost_f1_mean",
      "plain_selectboost_f1_mean",
      "delta_mean",
      "win_rate"
    )
  ],
  5
)
#>            scenario confounding_strength active_region_scale local_correlation
#> 1 confounded_blocks                  0.6                 0.5                 2
#> 2 confounded_blocks                  1.0                 0.8                 2
#> 3 confounded_blocks                  0.6                 0.8                 2
#> 4   localized_dense                  0.6                 0.5                 2
#> 5 confounded_blocks                  0.6                 0.5                 2
#>   association_method bandwidth selectboost_f1_mean plain_selectboost_f1_mean delta_mean
#> 1           interval         8           0.5362319                 0.4087266 0.12750533
#> 2             hybrid         4           0.5885135                 0.4826750 0.10583853
#> 3             hybrid         4           0.5833671                 0.4944862 0.08888092
#> 4       neighborhood         4           0.4972542                 0.4144859 0.08276831
#> 5             hybrid         4           0.5429293                 0.4657088 0.07722048
#>    win_rate
#> 1 1.0000000
#> 2 1.0000000
#> 3 1.0000000
#> 4 0.6666667
#> 5 0.6666667
```

In the shipped benchmark, the strongest gains appear in the
high-correlation, narrow-region settings. For example, in the
`confounded_blocks` scenario with `active_region_scale = 0.5`,
`local_correlation = 2`, and interval grouping at `bandwidth = 8`, the
saved mean `F1` values are approximately `0.536` for FDA-aware
`SelectBoost` versus `0.409` for plain `SelectBoost`.

## Further documentation

The package vignettes cover the main workflow families:

- discretized curves
- spectra and interval-aware `SelectBoost`
- basis and FPCA workflows
- methods, calibration, and formula interfaces
- simulation and benchmark workflows

## References

- Bertrand F., Aouadi I., Jung N., Carapito R., Vallat L., Bahram S.,
  and Maumy-Bertrand M. SelectBoost: a general algorithm to enhance the
  performance of variable selection methods in correlated datasets.
  *Bioinformatics*. <doi:10.1093/bioinformatics/btaa855>
- Hofner B., Boccuto L., and Göker M. Stability selection and related
  subsampling-based selection procedures.
- Brockhaus S., Melcher M., Leisch F., and Greven S. FDboost: boosting
  functional regression models.
