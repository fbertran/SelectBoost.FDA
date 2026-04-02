# SelectBoost.FDA

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
#>                 predictor representation basis_type
#> nuisance.spline  nuisance          basis     spline
#> signal.fpca        signal          basis       fpca
#>                 source_representation n_components
#> nuisance.spline                  grid            5
#> signal.fpca                      grid            3
#>                 first_component last_component
#> nuisance.spline              B1             B5
#> signal.fpca                 PC1            PC3
#>                         components domain_start
#> nuisance.spline B1, B2, B3, B4, B5         1100
#> signal.fpca          PC1, PC2, PC3         1100
#>                 domain_end
#> nuisance.spline       2500
#> signal.fpca           2500
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
#>   predictor group_id     group representation
#> 1    signal        1    signal          basis
#> 2  nuisance        2  nuisance          basis
#> 3       age        3       age         scalar
#> 4 treatment        4 treatment         scalar
#>   basis_type source_representation n_features
#> 1       fpca                  grid          3
#> 2     spline                  grid          5
#> 3                           scalar          1
#> 4                           scalar          1
#>   start_position end_position start_argval end_argval
#> 1              1            3          PC1        PC3
#> 2              1            5           B1         B5
#> 3              1            1          age        age
#> 4              1            1    treatment  treatment
#>   domain_start domain_end       c0 mean_selection
#> 1         1100       2500 c0 = 0.6      0.6666667
#> 2         1100       2500 c0 = 0.6      0.3500000
#> 3          age        age c0 = 0.6      0.2500000
#> 4    treatment  treatment c0 = 0.6      1.0000000
#>   max_selection selected_features
#> 1          1.00                 2
#> 2          1.00                 4
#> 3          0.25                 1
#> 4          1.00                 1
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
#>   predictor group_id     group representation
#> 1    signal        1    signal          basis
#> 2  nuisance        2  nuisance          basis
#> 3       age        3       age         scalar
#> 4 treatment        4 treatment         scalar
#>   basis_type source_representation n_features
#> 1       fpca                  grid          3
#> 2     spline                  grid          5
#> 3                           scalar          1
#> 4                           scalar          1
#>   start_position end_position start_argval end_argval
#> 1              1            3          PC1        PC3
#> 2              1            5           B1         B5
#> 3              1            1          age        age
#> 4              1            1    treatment  treatment
#>   domain_start domain_end mean_feature_frequency
#> 1         1100       2500              0.4166667
#> 2         1100       2500              0.0500000
#> 3          age        age              0.0000000
#> 4    treatment  treatment              0.2500000
#>   max_feature_frequency selected_features
#> 1                 0.750                 2
#> 2                 0.125                 0
#> 3                 0.000                 0
#> 4                 0.250                 0
#>   group_frequency group_selected
#> 1           0.750           TRUE
#> 2           0.125          FALSE
#> 3           0.000          FALSE
#> 4           0.250          FALSE
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
#>   predictor group_id          group representation
#> 1    signal        1    signal[1:3]          basis
#> 2  nuisance        2  nuisance[1:4]          basis
#> 3  nuisance        3  nuisance[5:5]          basis
#> 4       age        4       age[1:1]         scalar
#> 5 treatment        5 treatment[1:1]         scalar
#>   basis_type source_representation n_features
#> 1       fpca                  grid          3
#> 2     spline                  grid          4
#> 3     spline                  grid          1
#> 4                           scalar          1
#> 5                           scalar          1
#>   start_position end_position start_argval end_argval
#> 1              1            3          PC1        PC3
#> 2              1            4           B1         B4
#> 3              5            5           B5         B5
#> 4              1            1          age        age
#> 5              1            1    treatment  treatment
#>       domain_start       domain_end
#> 1             1100             2500
#> 2             1100 2464.10256410256
#> 3 1817.94871794872             2500
#> 4              age              age
#> 5        treatment        treatment
#>   mean_feature_frequency max_feature_frequency
#> 1              0.4166667                 0.750
#> 2              0.0625000                 0.125
#> 3              0.0000000                 0.000
#> 4              0.0000000                 0.000
#> 5              0.2500000                 0.250
#>   selected_features group_frequency group_selected
#> 1                 2           0.750           TRUE
#> 2                 0           0.125          FALSE
#> 3                 0           0.000          FALSE
#> 4                 0           0.000          FALSE
#> 5                 0           0.250          FALSE
#>   interval_start interval_end interval_label
#> 1              1            3    signal[1:3]
#> 2              1            4  nuisance[1:4]
#> 3              5            5  nuisance[5:5]
#> 4              1            1       age[1:1]
#> 5              1            1 treatment[1:1]
```

## Benchmarking on simulated FDA designs

The validation layer can be used to compare FDA-aware `SelectBoost` with
a plain `SelectBoost` baseline on the same simulated design and mapped
truth.

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
#>     level n_universe n_truth n_selected tp fp fn tn
#> 1 feature         42       9         33  8 25  1  8
#> 2 feature         42       9         29  8 21  1 12
#> 3   group          4       3          4  3  1  0  0
#> 4   group          4       3          4  3  1  0  0
#>   precision    recall specificity        f1   jaccard
#> 1 0.2424242 0.8888889   0.2424242 0.3809524 0.2352941
#> 2 0.2758621 0.8888889   0.3636364 0.4210526 0.2666667
#> 3 0.7500000 1.0000000   0.0000000 0.8571429 0.7500000
#> 4 0.7500000 1.0000000   0.0000000 0.8571429 0.7500000
#>   selection_rate       c0            method
#> 1      0.7857143 c0 = 0.5       selectboost
#> 2      0.6904762 c0 = 0.5 plain_selectboost
#> 3      1.0000000 c0 = 0.5       selectboost
#> 4      1.0000000 c0 = 0.5 plain_selectboost
#>          scenario representation   family
#> 1 localized_dense           grid gaussian
#> 2 localized_dense           grid gaussian
#> 3 localized_dense           grid gaussian
#> 4 localized_dense           grid gaussian
```

The package also ships a larger saved sensitivity study under
`inst/extdata/benchmarks/`, generated by
`tools/run_selectboost_sensitivity_study.R`. The saved top-setting table
keeps the FDA benchmark settings together with the mean `F1` score of
both algorithms.

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
#>            scenario confounding_strength
#> 1 confounded_blocks                  0.6
#> 2 confounded_blocks                  1.0
#> 3 confounded_blocks                  0.6
#> 4   localized_dense                  0.6
#> 5 confounded_blocks                  0.6
#>   active_region_scale local_correlation
#> 1                 0.5                 2
#> 2                 0.8                 2
#> 3                 0.8                 2
#> 4                 0.5                 2
#> 5                 0.5                 2
#>   association_method bandwidth selectboost_f1_mean
#> 1           interval         8           0.5362319
#> 2             hybrid         4           0.5885135
#> 3             hybrid         4           0.5833671
#> 4       neighborhood         4           0.4972542
#> 5             hybrid         4           0.5429293
#>   plain_selectboost_f1_mean delta_mean  win_rate
#> 1                 0.4087266 0.12750533 1.0000000
#> 2                 0.4826750 0.10583853 1.0000000
#> 3                 0.4944862 0.08888092 1.0000000
#> 4                 0.4144859 0.08276831 0.6666667
#> 5                 0.4657088 0.07722048 0.6666667
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
