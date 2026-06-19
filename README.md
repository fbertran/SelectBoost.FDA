---
output: github_document
---

<!-- README.md is generated from README.Rmd. Please edit that file -->




# SelectBoost.FDA <img src="man/figures/logo_selectboost_FDA.png" align="right" width="200" alt="SelectBoost.FDA logo"/>
## Frédéric Bertrand

<https://doi.org/10.32614/CRAN.package.SelectBoost.FDA>

<!-- badges: start -->
[![R-CMD-check](https://github.com/fbertran/SelectBoost.FDA/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/fbertran/SelectBoost.FDA/actions/workflows/R-CMD-check.yaml)
[![R-hub](https://github.com/fbertran/SelectBoost.FDA/actions/workflows/rhub.yaml/badge.svg)](https://github.com/fbertran/SelectBoost.FDA/actions/workflows/rhub.yaml)
<!-- badges: end -->


`SelectBoost.FDA` is an R package for variable selection in functional data
analysis. It combines FDA-native preprocessing and design objects with grouped
stability selection, interval summaries, FDA-aware `SelectBoost`, and a small
validation layer for simulation and benchmarking.

The package is designed for workflows where functional predictors are observed
on a grid, represented through basis expansions, or reduced to FPCA scores, and
where strong local or block-wise correlation makes ordinary variable selection
unstable.

## Main features

- FDA-native design objects built directly from raw curves, basis
  representations, FPCA scores, and scalar covariates.
- Train/test-safe preprocessing with identity transforms, standardization,
  spline-basis expansion, and FPCA.
- Grouped stability selection for functional blocks and interval summaries.
- FDA-aware `SelectBoost` wrappers plus a plain `SelectBoost` baseline.
- Simulation, benchmark, and evaluation helpers with mapped ground truth.
- Two-parameter perturbation grids over subsampling rate `q` and SelectBoost
  strength `c0`.
- Renderer-neutral extraction functions for selection surfaces, monotonicity
  paths, precision-recall paths, association heatmaps, interval maps, and
  benchmark summaries.
- Association diagnostics and report table helpers for scientific reporting
  material.
- Shipped sensitivity-study benchmark summaries for direct mean `F1`
  comparisons between `selectboost_fda()` and plain `SelectBoost`.
- Seeded simulation and stability-selection workflows that keep RNG changes
  local to the function call.

## Installation

You can install the development version from GitHub with:

```r
# install.packages("remotes")
remotes::install_github("bertran7/SelectBoost.FDA")
```

Some workflows rely on optional backends:

- `glmnet` for lasso-based grouped stability selection.
- `grpreg` for group lasso.
- `SGL` for sparse-group lasso.
- `FDboost` and `stabs` for the native `FDboost` stability-selection route.

## A first FDA-native workflow

The package ships with small example datasets so the full workflow can start
from raw functional inputs.


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
#>                 source_representation n_components first_component
#> nuisance.spline                  grid            5              B1
#> signal.fpca                      grid            3             PC1
#>                 last_component         components
#> nuisance.spline             B5 B1, B2, B3, B4, B5
#> signal.fpca                PC3      PC1, PC2, PC3
#>                                                                                                               component_keys
#> nuisance.spline nuisance::spline::B1, nuisance::spline::B2, nuisance::spline::B3, nuisance::spline::B4, nuisance::spline::B5
#> signal.fpca                                                          signal::fpca::PC1, signal::fpca::PC2, signal::fpca::PC3
#>                 domain_start domain_end
#> nuisance.spline         1100       2500
#> signal.fpca             1100       2500
```

## FDA-aware SelectBoost

`SelectBoost.FDA` extends `SelectBoost` with block-aware and region-aware
grouping while keeping the original perturbation engine.


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
#>   predictor group_id     group representation basis_type
#> 1    signal        1    signal          basis       fpca
#> 2  nuisance        2  nuisance          basis     spline
#> 3       age        3       age         scalar           
#> 4 treatment        4 treatment         scalar           
#>   source_representation n_features start_position end_position
#> 1                  grid          3              1            3
#> 2                  grid          5              1            5
#> 3                scalar          1              1            1
#> 4                scalar          1              1            1
#>   start_argval end_argval domain_start domain_end       c0
#> 1          PC1        PC3         1100       2500 c0 = 0.6
#> 2           B1         B5         1100       2500 c0 = 0.6
#> 3          age        age          age        age c0 = 0.6
#> 4    treatment  treatment    treatment  treatment c0 = 0.6
#>   mean_selection max_selection selected_features
#> 1      0.6666667          1.00                 2
#> 2      0.4000000          1.00                 4
#> 3      0.2500000          0.25                 1
#> 4      1.0000000          1.00                 1
```

## Grouped stability selection

Grouped stability selection is available through a common FDA interface. The
lasso route below requires the optional `glmnet` package.


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
#>   predictor group_id     group representation basis_type
#> 1    signal        1    signal          basis       fpca
#> 2  nuisance        2  nuisance          basis     spline
#> 3       age        3       age         scalar           
#> 4 treatment        4 treatment         scalar           
#>   source_representation n_features start_position end_position
#> 1                  grid          3              1            3
#> 2                  grid          5              1            5
#> 3                scalar          1              1            1
#> 4                scalar          1              1            1
#>   start_argval end_argval domain_start domain_end
#> 1          PC1        PC3         1100       2500
#> 2           B1         B5         1100       2500
#> 3          age        age          age        age
#> 4    treatment  treatment    treatment  treatment
#>   mean_feature_frequency max_feature_frequency selected_features
#> 1              0.4166667                 0.750                 2
#> 2              0.0500000                 0.125                 0
#> 3              0.0000000                 0.000                 0
#> 4              0.2500000                 0.250                 0
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
#>   predictor group_id          group representation basis_type
#> 1    signal        1    signal[1:3]          basis       fpca
#> 2  nuisance        2  nuisance[1:4]          basis     spline
#> 3  nuisance        3  nuisance[5:5]          basis     spline
#> 4       age        4       age[1:1]         scalar           
#> 5 treatment        5 treatment[1:1]         scalar           
#>   source_representation n_features start_position end_position
#> 1                  grid          3              1            3
#> 2                  grid          4              1            4
#> 3                  grid          1              5            5
#> 4                scalar          1              1            1
#> 5                scalar          1              1            1
#>   start_argval end_argval     domain_start       domain_end
#> 1          PC1        PC3             1100             2500
#> 2           B1         B4             1100 2464.10256410256
#> 3           B5         B5 1817.94871794872             2500
#> 4          age        age              age              age
#> 5    treatment  treatment        treatment        treatment
#>   mean_feature_frequency max_feature_frequency selected_features
#> 1              0.4166667                 0.750                 2
#> 2              0.0625000                 0.125                 0
#> 3              0.0000000                 0.000                 0
#> 4              0.0000000                 0.000                 0
#> 5              0.2500000                 0.250                 0
#>   group_frequency group_selected interval_start interval_end
#> 1           0.750           TRUE              1            3
#> 2           0.125          FALSE              1            4
#> 3           0.000          FALSE              5            5
#> 4           0.000          FALSE              1            1
#> 5           0.250          FALSE              1            1
#>   interval_label
#> 1    signal[1:3]
#> 2  nuisance[1:4]
#> 3  nuisance[5:5]
#> 4       age[1:1]
#> 5 treatment[1:1]
```

## Two-parameter perturbation surfaces

For focused benchmark workflows, `fit_perturbation_grid()` combines subject-level
subsampling with FDA-aware SelectBoost perturbations and returns ordinary data
frames for downstream plotting or reporting.


``` r
grid_fit <- fit_perturbation_grid(
  design,
  q_grid = c(0.6, 0.8),
  c0_grid = c(0.7, 0.4),
  B = 1,
  selectboost_B = 1,
  selector = "msgps",
  association_method = "hybrid",
  bandwidth = 4,
  levels = c("feature", "group"),
  seed = 2
)

head(selection_surface(grid_fit))
#>                                 feature predictor group   level   q
#> age.feature.0.6.0.4.selectboost     age       age   age feature 0.6
#> age.feature.0.6.0.7.selectboost     age       age   age feature 0.6
#> age.feature.0.8.0.4.selectboost     age       age   age feature 0.8
#> age.feature.0.8.0.7.selectboost     age       age   age feature 0.8
#> age.group.0.6.0.4.selectboost       age       age   age   group 0.6
#> age.group.0.6.0.7.selectboost       age       age   age   group 0.6
#>                                  c0 selection mean_selection
#> age.feature.0.6.0.4.selectboost 0.4         1              1
#> age.feature.0.6.0.7.selectboost 0.7         1              1
#> age.feature.0.8.0.4.selectboost 0.4         0              0
#> age.feature.0.8.0.7.selectboost 0.7         0              0
#> age.group.0.6.0.4.selectboost   0.4         1              1
#> age.group.0.6.0.7.selectboost   0.7         1              1
#>                                 max_selection selected
#> age.feature.0.6.0.4.selectboost             1     TRUE
#> age.feature.0.6.0.7.selectboost             1     TRUE
#> age.feature.0.8.0.4.selectboost             0    FALSE
#> age.feature.0.8.0.7.selectboost             0    FALSE
#> age.group.0.6.0.4.selectboost               1     TRUE
#> age.group.0.6.0.7.selectboost               1     TRUE
#>                                 representation basis_type
#> age.feature.0.6.0.4.selectboost         scalar       <NA>
#> age.feature.0.6.0.7.selectboost         scalar       <NA>
#> age.feature.0.8.0.4.selectboost         scalar       <NA>
#> age.feature.0.8.0.7.selectboost         scalar       <NA>
#> age.group.0.6.0.4.selectboost           scalar           
#> age.group.0.6.0.7.selectboost           scalar           
#>                                 source_representation
#> age.feature.0.6.0.4.selectboost                scalar
#> age.feature.0.6.0.7.selectboost                scalar
#> age.feature.0.8.0.4.selectboost                scalar
#> age.feature.0.8.0.7.selectboost                scalar
#> age.group.0.6.0.4.selectboost                  scalar
#> age.group.0.6.0.7.selectboost                  scalar
#>                                 start_position end_position
#> age.feature.0.6.0.4.selectboost              1            1
#> age.feature.0.6.0.7.selectboost              1            1
#> age.feature.0.8.0.4.selectboost              1            1
#> age.feature.0.8.0.7.selectboost              1            1
#> age.group.0.6.0.4.selectboost                1            1
#> age.group.0.6.0.7.selectboost                1            1
#>                                 start_argval end_argval
#> age.feature.0.6.0.4.selectboost          age        age
#> age.feature.0.6.0.7.selectboost          age        age
#> age.feature.0.8.0.4.selectboost          age        age
#> age.feature.0.8.0.7.selectboost          age        age
#> age.group.0.6.0.4.selectboost            age        age
#> age.group.0.6.0.7.selectboost            age        age
#>                                 domain_start domain_end      method
#> age.feature.0.6.0.4.selectboost          age        age selectboost
#> age.feature.0.6.0.7.selectboost          age        age selectboost
#> age.feature.0.8.0.4.selectboost          age        age selectboost
#> age.feature.0.8.0.7.selectboost          age        age selectboost
#> age.group.0.6.0.4.selectboost            age        age selectboost
#> age.group.0.6.0.7.selectboost            age        age selectboost
#>                                 block position argval   transform
#> age.feature.0.6.0.4.selectboost   age        1    age standardize
#> age.feature.0.6.0.7.selectboost   age        1    age standardize
#> age.feature.0.8.0.4.selectboost   age        1    age standardize
#> age.feature.0.8.0.7.selectboost   age        1    age standardize
#> age.group.0.6.0.4.selectboost    <NA>       NA   <NA>        <NA>
#> age.group.0.6.0.7.selectboost    <NA>       NA   <NA>        <NA>
#>                                 source_predictor
#> age.feature.0.6.0.4.selectboost              age
#> age.feature.0.6.0.7.selectboost              age
#> age.feature.0.8.0.4.selectboost              age
#> age.feature.0.8.0.7.selectboost              age
#> age.group.0.6.0.4.selectboost               <NA>
#> age.group.0.6.0.7.selectboost               <NA>
#>                                 source_position_start
#> age.feature.0.6.0.4.selectboost                     1
#> age.feature.0.6.0.7.selectboost                     1
#> age.feature.0.8.0.4.selectboost                     1
#> age.feature.0.8.0.7.selectboost                     1
#> age.group.0.6.0.4.selectboost                      NA
#> age.group.0.6.0.7.selectboost                      NA
#>                                 source_position_end
#> age.feature.0.6.0.4.selectboost                   1
#> age.feature.0.6.0.7.selectboost                   1
#> age.feature.0.8.0.4.selectboost                   1
#> age.feature.0.8.0.7.selectboost                   1
#> age.group.0.6.0.4.selectboost                    NA
#> age.group.0.6.0.7.selectboost                    NA
#>                                 source_argval_start
#> age.feature.0.6.0.4.selectboost                 age
#> age.feature.0.6.0.7.selectboost                 age
#> age.feature.0.8.0.4.selectboost                 age
#> age.feature.0.8.0.7.selectboost                 age
#> age.group.0.6.0.4.selectboost                  <NA>
#> age.group.0.6.0.7.selectboost                  <NA>
#>                                 source_argval_end component unit
#> age.feature.0.6.0.4.selectboost               age      <NA> <NA>
#> age.feature.0.6.0.7.selectboost               age      <NA> <NA>
#> age.feature.0.8.0.4.selectboost               age      <NA> <NA>
#> age.feature.0.8.0.7.selectboost               age      <NA> <NA>
#> age.group.0.6.0.4.selectboost                <NA>      <NA> <NA>
#> age.group.0.6.0.7.selectboost                <NA>      <NA> <NA>
#>                                 feature_index basis_component
#> age.feature.0.6.0.4.selectboost             9            <NA>
#> age.feature.0.6.0.7.selectboost             9            <NA>
#> age.feature.0.8.0.4.selectboost             9            <NA>
#> age.feature.0.8.0.7.selectboost             9            <NA>
#> age.group.0.6.0.4.selectboost              NA            <NA>
#> age.group.0.6.0.7.selectboost              NA            <NA>
#>                                 domain_label group_id n_features
#> age.feature.0.6.0.4.selectboost          age        3         NA
#> age.feature.0.6.0.7.selectboost          age        3         NA
#> age.feature.0.8.0.4.selectboost          age        3         NA
#> age.feature.0.8.0.7.selectboost          age        3         NA
#> age.group.0.6.0.4.selectboost           <NA>        3          1
#> age.group.0.6.0.7.selectboost           <NA>        3          1
#>                                 selected_features replicate
#> age.feature.0.6.0.4.selectboost                NA        NA
#> age.feature.0.6.0.7.selectboost                NA        NA
#> age.feature.0.8.0.4.selectboost                NA        NA
#> age.feature.0.8.0.7.selectboost                NA        NA
#> age.group.0.6.0.4.selectboost                   1        NA
#> age.group.0.6.0.7.selectboost                   1        NA
#>                                 association_method group_method
#> age.feature.0.6.0.4.selectboost             hybrid    threshold
#> age.feature.0.6.0.7.selectboost             hybrid    threshold
#> age.feature.0.8.0.4.selectboost             hybrid    threshold
#> age.feature.0.8.0.7.selectboost             hybrid    threshold
#> age.group.0.6.0.4.selectboost               hybrid    threshold
#> age.group.0.6.0.7.selectboost               hybrid    threshold
#>                                 within_blocks bandwidth width
#> age.feature.0.6.0.4.selectboost          TRUE         4    NA
#> age.feature.0.6.0.7.selectboost          TRUE         4    NA
#> age.feature.0.8.0.4.selectboost          TRUE         4    NA
#> age.feature.0.8.0.7.selectboost          TRUE         4    NA
#> age.group.0.6.0.4.selectboost            TRUE         4    NA
#> age.group.0.6.0.7.selectboost            TRUE         4    NA
#>                                 n_replicates
#> age.feature.0.6.0.4.selectboost            1
#> age.feature.0.6.0.7.selectboost            1
#> age.feature.0.8.0.4.selectboost            1
#> age.feature.0.8.0.7.selectboost            1
#> age.group.0.6.0.4.selectboost              1
#> age.group.0.6.0.7.selectboost              1
summarise_perturbation_grid(grid_fit)
#>                   level   q  c0 n_items n_selected mean_selection
#> feature.0.6.0.4 feature 0.6 0.4      10          5      0.5000000
#> feature.0.6.0.7 feature 0.6 0.7      10          4      0.4000000
#> feature.0.8.0.4 feature 0.8 0.4      10          7      0.7000000
#> feature.0.8.0.7 feature 0.8 0.7      10          4      0.4000000
#> group.0.6.0.4     group 0.6 0.4       4          4      0.7166667
#> group.0.6.0.7     group 0.6 0.7       4          3      0.6666667
#> group.0.8.0.4     group 0.8 0.4       4          3      0.6166667
#> group.0.8.0.7     group 0.8 0.7       4          3      0.4666667
#>                 max_selection
#> feature.0.6.0.4             1
#> feature.0.6.0.7             1
#> feature.0.8.0.4             1
#> feature.0.8.0.7             1
#> group.0.6.0.4               1
#> group.0.6.0.7               1
#> group.0.8.0.4               1
#> group.0.8.0.7               1
```

The data layer is independent of plotting backends:


``` r
head(as_monotonicity_path_data(grid_fit, axis = "c0", level = "feature"))
#>                                                                                             id
#> age.selectboost...NA...feature.0.6.age.feature.0.6.0.4.selectboost                         age
#> age.selectboost...NA...feature.0.6.age.feature.0.6.0.7.selectboost                         age
#> age.selectboost...NA...feature.0.8.age.feature.0.8.0.4.selectboost                         age
#> age.selectboost...NA...feature.0.8.age.feature.0.8.0.7.selectboost                         age
#> nuisance_B1.selectboost...NA...feature.0.6.nuisance_B1.feature.0.6.0.4.selectboost nuisance_B1
#> nuisance_B1.selectboost...NA...feature.0.6.nuisance_B1.feature.0.6.0.7.selectboost nuisance_B1
#>                                                                                      level
#> age.selectboost...NA...feature.0.6.age.feature.0.6.0.4.selectboost                 feature
#> age.selectboost...NA...feature.0.6.age.feature.0.6.0.7.selectboost                 feature
#> age.selectboost...NA...feature.0.8.age.feature.0.8.0.4.selectboost                 feature
#> age.selectboost...NA...feature.0.8.age.feature.0.8.0.7.selectboost                 feature
#> nuisance_B1.selectboost...NA...feature.0.6.nuisance_B1.feature.0.6.0.4.selectboost feature
#> nuisance_B1.selectboost...NA...feature.0.6.nuisance_B1.feature.0.6.0.7.selectboost feature
#>                                                                                    axis
#> age.selectboost...NA...feature.0.6.age.feature.0.6.0.4.selectboost                   c0
#> age.selectboost...NA...feature.0.6.age.feature.0.6.0.7.selectboost                   c0
#> age.selectboost...NA...feature.0.8.age.feature.0.8.0.4.selectboost                   c0
#> age.selectboost...NA...feature.0.8.age.feature.0.8.0.7.selectboost                   c0
#> nuisance_B1.selectboost...NA...feature.0.6.nuisance_B1.feature.0.6.0.4.selectboost   c0
#> nuisance_B1.selectboost...NA...feature.0.6.nuisance_B1.feature.0.6.0.7.selectboost   c0
#>                                                                                    axis_value
#> age.selectboost...NA...feature.0.6.age.feature.0.6.0.4.selectboost                        0.4
#> age.selectboost...NA...feature.0.6.age.feature.0.6.0.7.selectboost                        0.7
#> age.selectboost...NA...feature.0.8.age.feature.0.8.0.4.selectboost                        0.4
#> age.selectboost...NA...feature.0.8.age.feature.0.8.0.7.selectboost                        0.7
#> nuisance_B1.selectboost...NA...feature.0.6.nuisance_B1.feature.0.6.0.4.selectboost        0.4
#> nuisance_B1.selectboost...NA...feature.0.6.nuisance_B1.feature.0.6.0.7.selectboost        0.7
#>                                                                                    value
#> age.selectboost...NA...feature.0.6.age.feature.0.6.0.4.selectboost                     1
#> age.selectboost...NA...feature.0.6.age.feature.0.6.0.7.selectboost                     1
#> age.selectboost...NA...feature.0.8.age.feature.0.8.0.4.selectboost                     0
#> age.selectboost...NA...feature.0.8.age.feature.0.8.0.7.selectboost                     0
#> nuisance_B1.selectboost...NA...feature.0.6.nuisance_B1.feature.0.6.0.4.selectboost     0
#> nuisance_B1.selectboost...NA...feature.0.6.nuisance_B1.feature.0.6.0.7.selectboost     0
#>                                                                                    delta
#> age.selectboost...NA...feature.0.6.age.feature.0.6.0.4.selectboost                    NA
#> age.selectboost...NA...feature.0.6.age.feature.0.6.0.7.selectboost                     0
#> age.selectboost...NA...feature.0.8.age.feature.0.8.0.4.selectboost                    NA
#> age.selectboost...NA...feature.0.8.age.feature.0.8.0.7.selectboost                     0
#> nuisance_B1.selectboost...NA...feature.0.6.nuisance_B1.feature.0.6.0.4.selectboost    NA
#> nuisance_B1.selectboost...NA...feature.0.6.nuisance_B1.feature.0.6.0.7.selectboost     0
#>                                                                                    violation
#> age.selectboost...NA...feature.0.6.age.feature.0.6.0.4.selectboost                     FALSE
#> age.selectboost...NA...feature.0.6.age.feature.0.6.0.7.selectboost                     FALSE
#> age.selectboost...NA...feature.0.8.age.feature.0.8.0.4.selectboost                     FALSE
#> age.selectboost...NA...feature.0.8.age.feature.0.8.0.7.selectboost                     FALSE
#> nuisance_B1.selectboost...NA...feature.0.6.nuisance_B1.feature.0.6.0.4.selectboost     FALSE
#> nuisance_B1.selectboost...NA...feature.0.6.nuisance_B1.feature.0.6.0.7.selectboost     FALSE
#>                                                                                    violation_size
#> age.selectboost...NA...feature.0.6.age.feature.0.6.0.4.selectboost                              0
#> age.selectboost...NA...feature.0.6.age.feature.0.6.0.7.selectboost                              0
#> age.selectboost...NA...feature.0.8.age.feature.0.8.0.4.selectboost                              0
#> age.selectboost...NA...feature.0.8.age.feature.0.8.0.7.selectboost                              0
#> nuisance_B1.selectboost...NA...feature.0.6.nuisance_B1.feature.0.6.0.4.selectboost              0
#> nuisance_B1.selectboost...NA...feature.0.6.nuisance_B1.feature.0.6.0.7.selectboost              0
#>                                                                                         method
#> age.selectboost...NA...feature.0.6.age.feature.0.6.0.4.selectboost                 selectboost
#> age.selectboost...NA...feature.0.6.age.feature.0.6.0.7.selectboost                 selectboost
#> age.selectboost...NA...feature.0.8.age.feature.0.8.0.4.selectboost                 selectboost
#> age.selectboost...NA...feature.0.8.age.feature.0.8.0.7.selectboost                 selectboost
#> nuisance_B1.selectboost...NA...feature.0.6.nuisance_B1.feature.0.6.0.4.selectboost selectboost
#> nuisance_B1.selectboost...NA...feature.0.6.nuisance_B1.feature.0.6.0.7.selectboost selectboost
#>                                                                                    replicate
#> age.selectboost...NA...feature.0.6.age.feature.0.6.0.4.selectboost                        NA
#> age.selectboost...NA...feature.0.6.age.feature.0.6.0.7.selectboost                        NA
#> age.selectboost...NA...feature.0.8.age.feature.0.8.0.4.selectboost                        NA
#> age.selectboost...NA...feature.0.8.age.feature.0.8.0.7.selectboost                        NA
#> nuisance_B1.selectboost...NA...feature.0.6.nuisance_B1.feature.0.6.0.4.selectboost        NA
#> nuisance_B1.selectboost...NA...feature.0.6.nuisance_B1.feature.0.6.0.7.selectboost        NA
#>                                                                                      q
#> age.selectboost...NA...feature.0.6.age.feature.0.6.0.4.selectboost                 0.6
#> age.selectboost...NA...feature.0.6.age.feature.0.6.0.7.selectboost                 0.6
#> age.selectboost...NA...feature.0.8.age.feature.0.8.0.4.selectboost                 0.8
#> age.selectboost...NA...feature.0.8.age.feature.0.8.0.7.selectboost                 0.8
#> nuisance_B1.selectboost...NA...feature.0.6.nuisance_B1.feature.0.6.0.4.selectboost 0.6
#> nuisance_B1.selectboost...NA...feature.0.6.nuisance_B1.feature.0.6.0.7.selectboost 0.6
#>                                                                                     c0
#> age.selectboost...NA...feature.0.6.age.feature.0.6.0.4.selectboost                 0.4
#> age.selectboost...NA...feature.0.6.age.feature.0.6.0.7.selectboost                 0.7
#> age.selectboost...NA...feature.0.8.age.feature.0.8.0.4.selectboost                 0.4
#> age.selectboost...NA...feature.0.8.age.feature.0.8.0.7.selectboost                 0.7
#> nuisance_B1.selectboost...NA...feature.0.6.nuisance_B1.feature.0.6.0.4.selectboost 0.4
#> nuisance_B1.selectboost...NA...feature.0.6.nuisance_B1.feature.0.6.0.7.selectboost 0.7
summarise_monotonicity(grid_fit, axis = "c0", level = "feature")
#>              level axis n_paths n_monotone fraction_monotone
#> feature.c0 feature   c0      20         20                 1
#>            mean_total_violation max_violation
#> feature.c0                    0             0
head(as_association_heatmap_data(design, method = "hybrid", bandwidth = 4))
#>     feature_i  feature_j predictor_i predictor_j position_i
#> 1  signal_PC1 signal_PC1      signal      signal          1
#> 2  signal_PC2 signal_PC1      signal      signal          2
#> 3  signal_PC3 signal_PC1      signal      signal          3
#> 4 nuisance_B1 signal_PC1    nuisance      signal          1
#> 5 nuisance_B2 signal_PC1    nuisance      signal          2
#> 6 nuisance_B3 signal_PC1    nuisance      signal          3
#>   position_j argval_i argval_j  association same_block
#> 1          1      PC1      PC1 1.000000e+00       TRUE
#> 2          1      PC2      PC1 2.998446e-16       TRUE
#> 3          1      PC3      PC1 2.368387e-16       TRUE
#> 4          1       B1      PC1 0.000000e+00      FALSE
#> 5          1       B2      PC1 0.000000e+00      FALSE
#> 6          1       B3      PC1 0.000000e+00      FALSE
#>   within_bandwidth method
#> 1             TRUE hybrid
#> 2             TRUE hybrid
#> 3             TRUE hybrid
#> 4             TRUE hybrid
#> 5             TRUE hybrid
#> 6             TRUE hybrid
```

## Benchmarking on simulated FDA designs

The validation layer can be used to compare FDA-aware `SelectBoost` with a
plain `SelectBoost` baseline on the same simulated design and mapped truth.
When you pass `seed=`, the package uses a local seeded scope and does not leave
the global RNG state changed after the call returns.


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
#>     level n_universe n_truth n_selected tp fp fn tn precision
#> 1 feature         42       9         36  9 27  0  6 0.2500000
#> 2 feature         42       9         35  9 26  0  7 0.2571429
#> 3   group          4       3          4  3  1  0  0 0.7500000
#> 4   group          4       3          4  3  1  0  0 0.7500000
#>   recall specificity        f1   jaccard selection_rate       c0
#> 1      1   0.1818182 0.4000000 0.2500000      0.8571429 c0 = 0.5
#> 2      1   0.2121212 0.4090909 0.2571429      0.8333333 c0 = 0.5
#> 3      1   0.0000000 0.8571429 0.7500000      1.0000000 c0 = 0.5
#> 4      1   0.0000000 0.8571429 0.7500000      1.0000000 c0 = 0.5
#>              method        scenario representation   family
#> 1       selectboost localized_dense           grid gaussian
#> 2 plain_selectboost localized_dense           grid gaussian
#> 3       selectboost localized_dense           grid gaussian
#> 4 plain_selectboost localized_dense           grid gaussian
#>   noise_axis snr noise_sd effective_noise_sd effective_snr
#> 1   noise_sd  NA      0.4                0.4      2.213897
#> 2   noise_sd  NA      0.4                0.4      2.213897
#> 3   noise_sd  NA      0.4                0.4      2.213897
#> 4   noise_sd  NA      0.4                0.4      2.213897
```

The simulator exposes a scenario catalog for different FDA signal structures:
`localized_dense`, `confounded_blocks`, `smooth_sparse`,
`basis_block_signal`, `fpca_low_rank_signal`, `null_signal`, and
`mislocalized_signal`. The null scenario has no active functional or scalar
truth and is intended to summarize false-positive behavior through `fp`,
`n_selected`, specificity, and selection rate. The mislocalized scenario uses
fragmented active regions to document failure modes for locality-driven
grouping rules.

The package also ships a larger saved sensitivity study under
`inst/extdata/benchmarks/`, generated by
`tools/run_selectboost_sensitivity_study.R`. That script writes to an explicit
`--output-dir=...` path when supplied, and otherwise defaults to a subdirectory
of `tempdir()`, so it does not write into the package directory by default. The
committed files under `inst/extdata/benchmarks/` are a
saved copy of one benchmark run. The top-setting table keeps the FDA benchmark
settings together with the mean `F1` score of both algorithms.


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
#>            scenario confounding_strength active_region_scale
#> 1 confounded_blocks                  0.6                 0.5
#> 2 confounded_blocks                  1.0                 0.8
#> 3 confounded_blocks                  0.6                 0.8
#> 4   localized_dense                  0.6                 0.5
#> 5 confounded_blocks                  0.6                 0.5
#>   local_correlation association_method bandwidth
#> 1                 2           interval         8
#> 2                 2             hybrid         4
#> 3                 2             hybrid         4
#> 4                 2       neighborhood         4
#> 5                 2             hybrid         4
#>   selectboost_f1_mean plain_selectboost_f1_mean delta_mean
#> 1           0.5362319                 0.4087266 0.12750533
#> 2           0.5885135                 0.4826750 0.10583853
#> 3           0.5833671                 0.4944862 0.08888092
#> 4           0.4972542                 0.4144859 0.08276831
#> 5           0.5429293                 0.4657088 0.07722048
#>    win_rate
#> 1 1.0000000
#> 2 1.0000000
#> 3 1.0000000
#> 4 0.6666667
#> 5 0.6666667
```

In the shipped benchmark, the strongest gains appear in the high-correlation,
narrow-region settings. For example, in the `confounded_blocks` scenario with
`active_region_scale = 0.5`, `local_correlation = 2`, and interval grouping at
`bandwidth = 8`, the saved mean `F1` values are approximately `0.536` for
FDA-aware `SelectBoost` versus `0.409` for plain `SelectBoost`.

The focused benchmark driver is available at `tools/run_focused_benchmark.R`.
It writes to `--output-dir=...` when provided and otherwise uses `tempdir()`.
The current named baseline is `baseline_focused_benchmark_2026`; its grid is
stored in `inst/extdata/benchmarks/config_focused_baseline.yml`, and each run
writes `benchmark_config_baseline.yml` beside the benchmark CSV outputs.
Use `--quick --n-replicates=1` for smoke tests, `--medium` for the n = 30
benchmark, and `--final` for the n = 50 benchmark. The driver writes
`benchmark_summary_n30.csv`, `benchmark_summary_n50_or_n100.csv` for final
runs, `paired_gain_summary.csv` with paired FDA-aware versus plain SelectBoost
`F1` gains, and `paired_gain_bootstrap_ci.csv` with deterministic percentile
bootstrap confidence intervals from the replicate-level paired differences.
The paired-gain tables also report win rate, valid paired replicate count, and
method-failure flags. Assessment-oriented summaries are written as
`assessment_top_positive_settings.csv`, `assessment_negative_gain_settings.csv`,
`assessment_all_setting_summary.csv`, and `assessment_failure_modes.csv`; the
best-settings table should be interpreted only together with the all-setting
summary so negative-gain settings remain visible. The same driver now also
writes two-parameter perturbation-surface artifacts for representative
scenario types: `assessment_surface_summary.csv` for `(q, c0)` selection surfaces,
`assessment_monotonicity_summary.csv` for monotonicity across `q` and `c0`,
`assessment_precision_recall_paths.csv` for thresholded precision-recall paths,
and `assessment_best_thresholds.csv` for best-`F1` and fixed-threshold summaries at
`0.5`, `0.75`, and `0.9`. Association-geometry diagnostics are written as
`association_diagnostics.csv`, `association_group_size_summary.csv`, and
`assessment_association_comparison_table.csv`; these report association sparsity,
association mass, effective degree, induced group counts, and group-size
summaries at each `c0`, with setting keys retained for joins to benchmark
metrics. Method-comparison outputs are written as
`method_comparison_summary.csv`, `method_comparison_runtime.csv`, and
`assessment_method_comparison_table.csv`. These compare plain SelectBoost,
FDA-aware SelectBoost, and stability selection while separating perturbation
type from the base selector (`lasso`, `group_lasso`, or
`sparse_group_lasso`). Optional backends from `glmnet`, `grpreg`, and `SGL`
are skipped and labeled in the runtime table when unavailable, instead of
failing the benchmark. Runtime and computational reporting is written as
`runtime_by_setting.csv` and `runtime_by_method.csv`; these tables include
elapsed, user, and system time, warning and failure counts, selected-feature
summaries, and fitted-object memory size where available. Failed settings are
kept as failed runtime rows rather than being silently dropped. The driver also
writes
`benchmark_scenario_summary.csv`, which aggregates mean, standard deviation,
and standard error by scenario, method, and evaluation level. During long runs,
`progress.tsv` is updated as settings complete,
`benchmark_raw_metrics_checkpoint.csv` is appended after each replicate, and
`checkpoints/benchmark_raw_metrics_repNNN.csv` stores the replicate-level raw
metrics. To check stability across sample size and functional resolution, pass for example
`--n-grid=50,100,200 --grid-length-grid=30,75,150`; the driver then writes
`benchmark_size_resolution_summary.csv` and
`benchmark_runtime_by_size_resolution.csv`. To check robustness to signal
strength and noise, use `--snr-grid=0.5,1,2,4` for fixed-SNR comparisons or
`--noise-sd-grid=0.5,1,2` for fixed-noise stress tests; runs with these options
write `benchmark_noise_summary.csv` and `benchmark_noise_f1_gain_panel.csv`.
For the main scientific comparison, the fixed-SNR grid is usually the fairer
axis because it keeps relative difficulty comparable across scenarios and
representations. To make reruns reproducible, the benchmark driver uses a
recorded deterministic SelectBoost perturbation backend by default; pass
`--upstream-rfast-rvmf` only when you specifically want the upstream `Rfast`
perturbation generator.

The driver interface is campaign-configurable. Use comma-separated values to
restrict or expand scenarios, representations, sample sizes, grid resolutions,
SNR/noise axes, perturbation grids, and association structures. For example,
this command targets the high-correlation settings most relevant to the
FDA-aware grouping comparison while keeping all outputs under `tempdir()`:

```r
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
    "--assessment-summary",
    "--save-surfaces",
    "--save-association-diagnostics",
    "--bootstrap-reps=2000",
    paste0("--output-dir=", file.path(tempdir(), "selectboost_fda_focused_n30"))
  )
)
```

For a lighter local run, use `--no-save-surfaces` or
`--no-save-association-diagnostics` to skip the heavier optional diagnostics.
The broader `--no-assessment-summary` shortcut disables both of those optional
diagnostic families while keeping the core benchmark and paired-gain tables.

## Further documentation

The package vignettes cover the main workflow families:

- discretized curves
- spectra and interval-aware `SelectBoost`
- basis and FPCA workflows
- methods, calibration, and formula interfaces
- simulation and benchmark workflows
- perturbation grids
- monotonicity and precision-recall paths
- association diagnostics
- focused benchmark workflow

## References

- Bertrand F., Aouadi I., Jung N., Carapito R., Vallat L., Bahram S., and
  Maumy-Bertrand M. SelectBoost: a general algorithm to enhance the performance
  of variable selection methods in correlated datasets. *Bioinformatics*.
  doi:10.1093/bioinformatics/btaa855
- Hofner B., Boccuto L., and Göker M. Stability selection and related
  subsampling-based selection procedures.
- Brockhaus S., Melcher M., Leisch F., and Greven S. FDboost:
  boosting functional regression models.
