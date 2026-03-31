# Methods, Calibration, and Formula Workflows

`SelectBoost.FDA` now exposes a broader modeling layer on top of the
FDA-native design object:

- formula-based design construction
- multiple selector backends behind one API
- calibration helpers for stability selection and SelectBoost
- method-comparison utilities

## Build a design from a formula

``` r
library(SelectBoost.FDA)
data("spectra_example", package = "SelectBoost.FDA")

formula_data <- list(
  y = spectra_example$response,
  signal = fda_grid(
    spectra_example$predictors$signal,
    argvals = spectra_example$grid,
    name = "signal",
    unit = "nm"
  ),
  nuisance = fda_grid(
    spectra_example$predictors$nuisance,
    argvals = spectra_example$grid,
    name = "nuisance",
    unit = "nm"
  ),
  age = spectra_example$scalar_covariates$age,
  treatment = factor(spectra_example$scalar_covariates$treatment)
)

design <- fda_design_formula(
  y ~ signal + nuisance + age + treatment,
  data = formula_data,
  transforms = list(
    signal = fda_fpca(n_components = 3),
    nuisance = fda_bspline(df = 5)
  ),
  scalar_transform = fda_standardize(),
  family = "gaussian"
)

design
#> FDA design
#>   observations: 80 
#>   features: 11 
#>   functional predictors: 2 
#>   scalar covariates: 3 
#>   family: gaussian 
#>   response available: TRUE
selection_map(design, level = "basis")
#>                 predictor representation basis_type source_representation
#> nuisance.spline  nuisance          basis     spline                  grid
#> signal.fpca        signal          basis       fpca                  grid
#>                 n_components first_component last_component         components
#> nuisance.spline            5              B1             B5 B1, B2, B3, B4, B5
#> signal.fpca                3             PC1            PC3      PC1, PC2, PC3
#>                 domain_start domain_end
#> nuisance.spline         1100       2500
#> signal.fpca             1100       2500
```

## Calibrate modeling choices

These helpers run actual fits over user-defined grids and summarize the
result.

``` r
cal_stability <- calibrate_stability_selection(
  design,
  selector = "lasso",
  sample_fraction_grid = c(0.5, 0.7),
  cutoff_grid = c(0.5, 0.7),
  B = 8,
  seed = 1
)

cal_width <- calibrate_interval_width(
  design,
  widths = c(4, 6),
  selector = "lasso",
  B = 8,
  cutoff = 0.5,
  seed = 2
)

cal_selectboost <- calibrate_selectboost(
  design,
  selector = "lasso",
  c0_grid = c(0.7, 0.4),
  B = 4
)

cal_stability
#> FDA calibration grid
#>   type: stability_selection 
#>   rows: 4
cal_stability$grid
#>   sample_fraction cutoff n_selected_features n_selected_groups
#> 1             0.5    0.5                   5                 4
#> 2             0.7    0.5                   6                 4
#> 3             0.5    0.7                   4                 3
#> 4             0.7    0.7                   5                 4
#>   mean_feature_frequency max_feature_frequency mean_group_frequency
#> 1              0.5227273                     1                0.750
#> 2              0.6136364                     1                0.800
#> 3              0.4886364                     1                0.725
#> 4              0.5795455                     1                0.825
#>   max_group_frequency
#> 1                   1
#> 2                   1
#> 3                   1
#> 4                   1
cal_width$grid
#>   width step overlap n_selected_features n_selected_groups
#> 1     4    4   FALSE                   6                 4
#> 2     6    6   FALSE                   5                 4
#>   mean_feature_frequency max_feature_frequency mean_group_frequency
#> 1              0.5340909                     1            0.6666667
#> 2              0.4886364                     1            0.7250000
#>   max_group_frequency
#> 1                   1
#> 2                   1
cal_selectboost$grid
#>                c0 n_selected_features n_selected_groups mean_feature_selection
#> c0 = 0.4 c0 = 0.4                   9                 5              0.5681818
#> c0 = 0.7 c0 = 0.7                   9                 5              0.7045455
#>          max_feature_selection mean_group_selection max_group_selection
#> c0 = 0.4                     1                 0.69                   1
#> c0 = 0.7                     1                 0.87                   1
```

## Compare methods on one design

``` r
comparison <- compare_selection_methods(
  design,
  methods = c("stability", "interval", "selectboost"),
  stability_args = list(selector = "lasso", B = 8, cutoff = 0.5, seed = 3),
  interval_args = list(selector = "lasso", width = 5, B = 8, cutoff = 0.5, seed = 4),
  selectboost_args = list(selector = "lasso", B = 4, steps.seq = c(0.7, 0.4), c0lim = FALSE)
)

comparison
#> FDA method comparison
#>   methods: stability, interval, selectboost 
#>   rows: 4
summary(comparison)
#> FDA method comparison summary
#>   methods: stability, interval, selectboost 
#>       method n_selected_features n_selected_groups mean_feature_frequency
#>    stability                   5                 4              0.4886364
#>     interval                   5                 4              0.5227273
#>  selectboost                  11                 5                     NA
#>  selectboost                   8                 5                     NA
#>  max_feature_frequency mean_group_frequency max_group_frequency width       c0
#>                      1                0.725                   1    NA     <NA>
#>                      1                0.725                   1     3     <NA>
#>                     NA                   NA                  NA    NA c0 = 0.4
#>                     NA                   NA                  NA    NA c0 = 0.7
#>  mean_feature_selection max_feature_selection mean_group_selection
#>                      NA                    NA                   NA
#>                      NA                    NA                   NA
#>               0.6590909                     1                 0.73
#>               0.6818182                     1                 0.86
#>  max_group_selection
#>                   NA
#>                   NA
#>                    1
#>                    1
head(selection_map(comparison, level = "group"))
#>    predictor group_id       group representation basis_type
#> 1     signal        1      signal          basis       fpca
#> 2   nuisance        2    nuisance          basis     spline
#> 3        age        3         age         scalar           
#> 4 treatment0        4  treatment0         scalar           
#> 5 treatment1        5  treatment1         scalar           
#> 6     signal        1 signal[1:3]          basis       fpca
#>   source_representation n_features start_position end_position start_argval
#> 1                  grid          3              1            3          PC1
#> 2                  grid          5              1            5           B1
#> 3                scalar          1              1            1          age
#> 4                scalar          1              1            1   treatment0
#> 5                scalar          1              1            1   treatment1
#> 6                  grid          3              1            3          PC1
#>   end_argval domain_start domain_end mean_feature_frequency
#> 1        PC3         1100       2500                  0.875
#> 2         B5         1100       2500                  0.150
#> 3        age          age        age                  0.875
#> 4 treatment0   treatment0 treatment0                  1.000
#> 5 treatment1   treatment1 treatment1                  0.125
#> 6        PC3         1100       2500                  0.875
#>   max_feature_frequency selected_features group_frequency group_selected
#> 1                 1.000                 3           1.000           TRUE
#> 2                 0.375                 0           0.625           TRUE
#> 3                 0.875                 1           0.875           TRUE
#> 4                 1.000                 1           1.000           TRUE
#> 5                 0.125                 0           0.125          FALSE
#> 6                 1.000                 3           1.000           TRUE
#>      method interval_start interval_end interval_label   c0 mean_selection
#> 1 stability             NA           NA           <NA> <NA>             NA
#> 2 stability             NA           NA           <NA> <NA>             NA
#> 3 stability             NA           NA           <NA> <NA>             NA
#> 4 stability             NA           NA           <NA> <NA>             NA
#> 5 stability             NA           NA           <NA> <NA>             NA
#> 6  interval              1            3    signal[1:3] <NA>             NA
#>   max_selection
#> 1            NA
#> 2            NA
#> 3            NA
#> 4            NA
#> 5            NA
#> 6            NA
```

## Switch selector backends

The selector argument now accepts common aliases such as `"lasso"`,
`"group_lasso"`, and `"sparse_group_lasso"`.

``` r
fit_stability(
  design,
  selector = "sparse_group_lasso",
  B = 8,
  cutoff = 0.5,
  seed = 5
)
#> FDA stability selection
#>   family: gaussian 
#>   features: 11 
#>   groups: 5 
#>   replicates: 8 
#>   cutoff: 0.5
```
