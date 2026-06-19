# Perturbation Grids for FDA Selection

[`fit_perturbation_grid()`](https://fbertran.github.io/SelectBoost.FDA/reference/fit_perturbation_grid.md)
estimates the two-parameter selection surface indexed by a subject
subsampling rate `q` and a SelectBoost perturbation strength `c0`.

``` r

library(SelectBoost.FDA)

sim <- simulate_fda_scenario(
  n = 18,
  grid_length = 10,
  include_scalar = FALSE,
  seed = 1
)

grid_fit <- fit_perturbation_grid(
  sim$design,
  q_grid = c(0.6, 0.8),
  c0_grid = c(0.7, 0.4),
  B = 1,
  selectboost_B = 1,
  selector = "msgps",
  association_method = "hybrid",
  bandwidth = 3,
  levels = c("feature", "group"),
  seed = 2
)

grid_fit
#> FDA perturbation grid
#>   q values: 2 
#>   c0 values: 2 
#>   row replicates: 1 
#>   surface rows: 88 
#>   warnings: 0
head(selection_surface(grid_fit))
#>                                           feature predictor    group   level
#> nuisance.group.0.6.0.4.selectboost       nuisance  nuisance nuisance   group
#> nuisance.group.0.6.0.7.selectboost       nuisance  nuisance nuisance   group
#> nuisance.group.0.8.0.4.selectboost       nuisance  nuisance nuisance   group
#> nuisance.group.0.8.0.7.selectboost       nuisance  nuisance nuisance   group
#> nuisance_1.feature.0.6.0.4.selectboost nuisance_1  nuisance nuisance feature
#> nuisance_1.feature.0.6.0.7.selectboost nuisance_1  nuisance nuisance feature
#>                                          q  c0 selection mean_selection
#> nuisance.group.0.6.0.4.selectboost     0.6 0.4       0.3            0.3
#> nuisance.group.0.6.0.7.selectboost     0.6 0.7       0.5            0.5
#> nuisance.group.0.8.0.4.selectboost     0.8 0.4       0.1            0.1
#> nuisance.group.0.8.0.7.selectboost     0.8 0.7       0.1            0.1
#> nuisance_1.feature.0.6.0.4.selectboost 0.6 0.4       0.0            0.0
#> nuisance_1.feature.0.6.0.7.selectboost 0.6 0.7       1.0            1.0
#>                                        max_selection selected representation
#> nuisance.group.0.6.0.4.selectboost                 1     TRUE           grid
#> nuisance.group.0.6.0.7.selectboost                 1     TRUE           grid
#> nuisance.group.0.8.0.4.selectboost                 1     TRUE           grid
#> nuisance.group.0.8.0.7.selectboost                 1     TRUE           grid
#> nuisance_1.feature.0.6.0.4.selectboost             0    FALSE           grid
#> nuisance_1.feature.0.6.0.7.selectboost             1     TRUE           grid
#>                                        basis_type source_representation
#> nuisance.group.0.6.0.4.selectboost                                 grid
#> nuisance.group.0.6.0.7.selectboost                                 grid
#> nuisance.group.0.8.0.4.selectboost                                 grid
#> nuisance.group.0.8.0.7.selectboost                                 grid
#> nuisance_1.feature.0.6.0.4.selectboost       <NA>                  grid
#> nuisance_1.feature.0.6.0.7.selectboost       <NA>                  grid
#>                                        start_position end_position start_argval
#> nuisance.group.0.6.0.4.selectboost                  1           10            0
#> nuisance.group.0.6.0.7.selectboost                  1           10            0
#> nuisance.group.0.8.0.4.selectboost                  1           10            0
#> nuisance.group.0.8.0.7.selectboost                  1           10            0
#> nuisance_1.feature.0.6.0.4.selectboost              1            1            0
#> nuisance_1.feature.0.6.0.7.selectboost              1            1            0
#>                                        end_argval domain_start domain_end
#> nuisance.group.0.6.0.4.selectboost              1            0          1
#> nuisance.group.0.6.0.7.selectboost              1            0          1
#> nuisance.group.0.8.0.4.selectboost              1            0          1
#> nuisance.group.0.8.0.7.selectboost              1            0          1
#> nuisance_1.feature.0.6.0.4.selectboost          0            0          0
#> nuisance_1.feature.0.6.0.7.selectboost          0            0          0
#>                                             method    block position argval
#> nuisance.group.0.6.0.4.selectboost     selectboost     <NA>       NA   <NA>
#> nuisance.group.0.6.0.7.selectboost     selectboost     <NA>       NA   <NA>
#> nuisance.group.0.8.0.4.selectboost     selectboost     <NA>       NA   <NA>
#> nuisance.group.0.8.0.7.selectboost     selectboost     <NA>       NA   <NA>
#> nuisance_1.feature.0.6.0.4.selectboost selectboost nuisance        1      0
#> nuisance_1.feature.0.6.0.7.selectboost selectboost nuisance        1      0
#>                                        transform source_predictor
#> nuisance.group.0.6.0.4.selectboost          <NA>             <NA>
#> nuisance.group.0.6.0.7.selectboost          <NA>             <NA>
#> nuisance.group.0.8.0.4.selectboost          <NA>             <NA>
#> nuisance.group.0.8.0.7.selectboost          <NA>             <NA>
#> nuisance_1.feature.0.6.0.4.selectboost  identity         nuisance
#> nuisance_1.feature.0.6.0.7.selectboost  identity         nuisance
#>                                        source_position_start
#> nuisance.group.0.6.0.4.selectboost                        NA
#> nuisance.group.0.6.0.7.selectboost                        NA
#> nuisance.group.0.8.0.4.selectboost                        NA
#> nuisance.group.0.8.0.7.selectboost                        NA
#> nuisance_1.feature.0.6.0.4.selectboost                     1
#> nuisance_1.feature.0.6.0.7.selectboost                     1
#>                                        source_position_end source_argval_start
#> nuisance.group.0.6.0.4.selectboost                      NA                <NA>
#> nuisance.group.0.6.0.7.selectboost                      NA                <NA>
#> nuisance.group.0.8.0.4.selectboost                      NA                <NA>
#> nuisance.group.0.8.0.7.selectboost                      NA                <NA>
#> nuisance_1.feature.0.6.0.4.selectboost                   1                   0
#> nuisance_1.feature.0.6.0.7.selectboost                   1                   0
#>                                        source_argval_end component unit
#> nuisance.group.0.6.0.4.selectboost                  <NA>      <NA> <NA>
#> nuisance.group.0.6.0.7.selectboost                  <NA>      <NA> <NA>
#> nuisance.group.0.8.0.4.selectboost                  <NA>      <NA> <NA>
#> nuisance.group.0.8.0.7.selectboost                  <NA>      <NA> <NA>
#> nuisance_1.feature.0.6.0.4.selectboost                 0      <NA> <NA>
#> nuisance_1.feature.0.6.0.7.selectboost                 0      <NA> <NA>
#>                                        feature_index basis_component
#> nuisance.group.0.6.0.4.selectboost                NA            <NA>
#> nuisance.group.0.6.0.7.selectboost                NA            <NA>
#> nuisance.group.0.8.0.4.selectboost                NA            <NA>
#> nuisance.group.0.8.0.7.selectboost                NA            <NA>
#> nuisance_1.feature.0.6.0.4.selectboost            11            <NA>
#> nuisance_1.feature.0.6.0.7.selectboost            11            <NA>
#>                                        domain_label group_id n_features
#> nuisance.group.0.6.0.4.selectboost             <NA>        2         10
#> nuisance.group.0.6.0.7.selectboost             <NA>        2         10
#> nuisance.group.0.8.0.4.selectboost             <NA>        2         10
#> nuisance.group.0.8.0.7.selectboost             <NA>        2         10
#> nuisance_1.feature.0.6.0.4.selectboost            0        2         NA
#> nuisance_1.feature.0.6.0.7.selectboost            0        2         NA
#>                                        selected_features replicate
#> nuisance.group.0.6.0.4.selectboost                     3        NA
#> nuisance.group.0.6.0.7.selectboost                     5        NA
#> nuisance.group.0.8.0.4.selectboost                     1        NA
#> nuisance.group.0.8.0.7.selectboost                     1        NA
#> nuisance_1.feature.0.6.0.4.selectboost                NA        NA
#> nuisance_1.feature.0.6.0.7.selectboost                NA        NA
#>                                        association_method group_method
#> nuisance.group.0.6.0.4.selectboost                 hybrid    threshold
#> nuisance.group.0.6.0.7.selectboost                 hybrid    threshold
#> nuisance.group.0.8.0.4.selectboost                 hybrid    threshold
#> nuisance.group.0.8.0.7.selectboost                 hybrid    threshold
#> nuisance_1.feature.0.6.0.4.selectboost             hybrid    threshold
#> nuisance_1.feature.0.6.0.7.selectboost             hybrid    threshold
#>                                        within_blocks bandwidth width
#> nuisance.group.0.6.0.4.selectboost              TRUE         3    NA
#> nuisance.group.0.6.0.7.selectboost              TRUE         3    NA
#> nuisance.group.0.8.0.4.selectboost              TRUE         3    NA
#> nuisance.group.0.8.0.7.selectboost              TRUE         3    NA
#> nuisance_1.feature.0.6.0.4.selectboost          TRUE         3    NA
#> nuisance_1.feature.0.6.0.7.selectboost          TRUE         3    NA
#>                                        n_replicates
#> nuisance.group.0.6.0.4.selectboost                1
#> nuisance.group.0.6.0.7.selectboost                1
#> nuisance.group.0.8.0.4.selectboost                1
#> nuisance.group.0.8.0.7.selectboost                1
#> nuisance_1.feature.0.6.0.4.selectboost            1
#> nuisance_1.feature.0.6.0.7.selectboost            1
summarise_perturbation_grid(grid_fit)
#>                   level   q  c0 n_items n_selected mean_selection max_selection
#> feature.0.6.0.4 feature 0.6 0.4      20         11           0.55             1
#> feature.0.6.0.7 feature 0.6 0.7      20         13           0.65             1
#> feature.0.8.0.4 feature 0.8 0.4      20          7           0.35             1
#> feature.0.8.0.7 feature 0.8 0.7      20          7           0.35             1
#> group.0.6.0.4     group 0.6 0.4       2          2           0.55             1
#> group.0.6.0.7     group 0.6 0.7       2          2           0.65             1
#> group.0.8.0.4     group 0.8 0.4       2          2           0.35             1
#> group.0.8.0.7     group 0.8 0.7       2          2           0.35             1
```

The returned object keeps the statistical result as ordinary data
frames:

``` r

feature_surface <- selection_map(grid_fit, level = "feature")
group_surface <- selection_map(grid_fit, level = "group")

head(feature_surface[, c("feature", "q", "c0", "selection", "selected")])
#>                                             feature   q  c0 selection selected
#> nuisance_1.feature.0.6.0.4.selectboost   nuisance_1 0.6 0.4         0    FALSE
#> nuisance_1.feature.0.6.0.7.selectboost   nuisance_1 0.6 0.7         1     TRUE
#> nuisance_1.feature.0.8.0.4.selectboost   nuisance_1 0.8 0.4         0    FALSE
#> nuisance_1.feature.0.8.0.7.selectboost   nuisance_1 0.8 0.7         0    FALSE
#> nuisance_10.feature.0.6.0.4.selectboost nuisance_10 0.6 0.4         0    FALSE
#> nuisance_10.feature.0.6.0.7.selectboost nuisance_10 0.6 0.7         0    FALSE
head(group_surface[, c("group", "q", "c0", "mean_selection", "max_selection")])
#>                                       group   q  c0 mean_selection
#> nuisance.group.0.6.0.4.selectboost nuisance 0.6 0.4            0.3
#> nuisance.group.0.6.0.7.selectboost nuisance 0.6 0.7            0.5
#> nuisance.group.0.8.0.4.selectboost nuisance 0.8 0.4            0.1
#> nuisance.group.0.8.0.7.selectboost nuisance 0.8 0.7            0.1
#> signal.group.0.6.0.4.selectboost     signal 0.6 0.4            0.8
#> signal.group.0.6.0.7.selectboost     signal 0.6 0.7            0.8
#>                                    max_selection
#> nuisance.group.0.6.0.4.selectboost             1
#> nuisance.group.0.6.0.7.selectboost             1
#> nuisance.group.0.8.0.4.selectboost             1
#> nuisance.group.0.8.0.7.selectboost             1
#> signal.group.0.6.0.4.selectboost               1
#> signal.group.0.6.0.7.selectboost               1
```

The same data can be filtered before plotting or reporting:

``` r

head(selected_surface(grid_fit, threshold = 0.5, level = "feature"))
#>                                             feature predictor    group   level
#> nuisance_1.feature.0.6.0.7.selectboost   nuisance_1  nuisance nuisance feature
#> nuisance_10.feature.0.8.0.4.selectboost nuisance_10  nuisance nuisance feature
#> nuisance_2.feature.0.6.0.4.selectboost   nuisance_2  nuisance nuisance feature
#> nuisance_3.feature.0.6.0.4.selectboost   nuisance_3  nuisance nuisance feature
#> nuisance_3.feature.0.6.0.7.selectboost   nuisance_3  nuisance nuisance feature
#> nuisance_5.feature.0.6.0.7.selectboost   nuisance_5  nuisance nuisance feature
#>                                           q  c0 selection mean_selection
#> nuisance_1.feature.0.6.0.7.selectboost  0.6 0.7         1              1
#> nuisance_10.feature.0.8.0.4.selectboost 0.8 0.4         1              1
#> nuisance_2.feature.0.6.0.4.selectboost  0.6 0.4         1              1
#> nuisance_3.feature.0.6.0.4.selectboost  0.6 0.4         1              1
#> nuisance_3.feature.0.6.0.7.selectboost  0.6 0.7         1              1
#> nuisance_5.feature.0.6.0.7.selectboost  0.6 0.7         1              1
#>                                         max_selection selected representation
#> nuisance_1.feature.0.6.0.7.selectboost              1     TRUE           grid
#> nuisance_10.feature.0.8.0.4.selectboost             1     TRUE           grid
#> nuisance_2.feature.0.6.0.4.selectboost              1     TRUE           grid
#> nuisance_3.feature.0.6.0.4.selectboost              1     TRUE           grid
#> nuisance_3.feature.0.6.0.7.selectboost              1     TRUE           grid
#> nuisance_5.feature.0.6.0.7.selectboost              1     TRUE           grid
#>                                         basis_type source_representation
#> nuisance_1.feature.0.6.0.7.selectboost        <NA>                  grid
#> nuisance_10.feature.0.8.0.4.selectboost       <NA>                  grid
#> nuisance_2.feature.0.6.0.4.selectboost        <NA>                  grid
#> nuisance_3.feature.0.6.0.4.selectboost        <NA>                  grid
#> nuisance_3.feature.0.6.0.7.selectboost        <NA>                  grid
#> nuisance_5.feature.0.6.0.7.selectboost        <NA>                  grid
#>                                         start_position end_position
#> nuisance_1.feature.0.6.0.7.selectboost               1            1
#> nuisance_10.feature.0.8.0.4.selectboost             10           10
#> nuisance_2.feature.0.6.0.4.selectboost               2            2
#> nuisance_3.feature.0.6.0.4.selectboost               3            3
#> nuisance_3.feature.0.6.0.7.selectboost               3            3
#> nuisance_5.feature.0.6.0.7.selectboost               5            5
#>                                              start_argval        end_argval
#> nuisance_1.feature.0.6.0.7.selectboost                  0                 0
#> nuisance_10.feature.0.8.0.4.selectboost                 1                 1
#> nuisance_2.feature.0.6.0.4.selectboost  0.111111111111111 0.111111111111111
#> nuisance_3.feature.0.6.0.4.selectboost  0.222222222222222 0.222222222222222
#> nuisance_3.feature.0.6.0.7.selectboost  0.222222222222222 0.222222222222222
#> nuisance_5.feature.0.6.0.7.selectboost  0.444444444444444 0.444444444444444
#>                                              domain_start        domain_end
#> nuisance_1.feature.0.6.0.7.selectboost                  0                 0
#> nuisance_10.feature.0.8.0.4.selectboost                 1                 1
#> nuisance_2.feature.0.6.0.4.selectboost  0.111111111111111 0.111111111111111
#> nuisance_3.feature.0.6.0.4.selectboost  0.222222222222222 0.222222222222222
#> nuisance_3.feature.0.6.0.7.selectboost  0.222222222222222 0.222222222222222
#> nuisance_5.feature.0.6.0.7.selectboost  0.444444444444444 0.444444444444444
#>                                              method    block position
#> nuisance_1.feature.0.6.0.7.selectboost  selectboost nuisance        1
#> nuisance_10.feature.0.8.0.4.selectboost selectboost nuisance       10
#> nuisance_2.feature.0.6.0.4.selectboost  selectboost nuisance        2
#> nuisance_3.feature.0.6.0.4.selectboost  selectboost nuisance        3
#> nuisance_3.feature.0.6.0.7.selectboost  selectboost nuisance        3
#> nuisance_5.feature.0.6.0.7.selectboost  selectboost nuisance        5
#>                                                    argval transform
#> nuisance_1.feature.0.6.0.7.selectboost                  0  identity
#> nuisance_10.feature.0.8.0.4.selectboost                 1  identity
#> nuisance_2.feature.0.6.0.4.selectboost  0.111111111111111  identity
#> nuisance_3.feature.0.6.0.4.selectboost  0.222222222222222  identity
#> nuisance_3.feature.0.6.0.7.selectboost  0.222222222222222  identity
#> nuisance_5.feature.0.6.0.7.selectboost  0.444444444444444  identity
#>                                         source_predictor source_position_start
#> nuisance_1.feature.0.6.0.7.selectboost          nuisance                     1
#> nuisance_10.feature.0.8.0.4.selectboost         nuisance                    10
#> nuisance_2.feature.0.6.0.4.selectboost          nuisance                     2
#> nuisance_3.feature.0.6.0.4.selectboost          nuisance                     3
#> nuisance_3.feature.0.6.0.7.selectboost          nuisance                     3
#> nuisance_5.feature.0.6.0.7.selectboost          nuisance                     5
#>                                         source_position_end source_argval_start
#> nuisance_1.feature.0.6.0.7.selectboost                    1                   0
#> nuisance_10.feature.0.8.0.4.selectboost                  10                   1
#> nuisance_2.feature.0.6.0.4.selectboost                    2   0.111111111111111
#> nuisance_3.feature.0.6.0.4.selectboost                    3   0.222222222222222
#> nuisance_3.feature.0.6.0.7.selectboost                    3   0.222222222222222
#> nuisance_5.feature.0.6.0.7.selectboost                    5   0.444444444444444
#>                                         source_argval_end component unit
#> nuisance_1.feature.0.6.0.7.selectboost                  0      <NA> <NA>
#> nuisance_10.feature.0.8.0.4.selectboost                 1      <NA> <NA>
#> nuisance_2.feature.0.6.0.4.selectboost  0.111111111111111      <NA> <NA>
#> nuisance_3.feature.0.6.0.4.selectboost  0.222222222222222      <NA> <NA>
#> nuisance_3.feature.0.6.0.7.selectboost  0.222222222222222      <NA> <NA>
#> nuisance_5.feature.0.6.0.7.selectboost  0.444444444444444      <NA> <NA>
#>                                         feature_index basis_component
#> nuisance_1.feature.0.6.0.7.selectboost             11            <NA>
#> nuisance_10.feature.0.8.0.4.selectboost            20            <NA>
#> nuisance_2.feature.0.6.0.4.selectboost             12            <NA>
#> nuisance_3.feature.0.6.0.4.selectboost             13            <NA>
#> nuisance_3.feature.0.6.0.7.selectboost             13            <NA>
#> nuisance_5.feature.0.6.0.7.selectboost             15            <NA>
#>                                              domain_label group_id n_features
#> nuisance_1.feature.0.6.0.7.selectboost                  0        2         NA
#> nuisance_10.feature.0.8.0.4.selectboost                 1        2         NA
#> nuisance_2.feature.0.6.0.4.selectboost  0.111111111111111        2         NA
#> nuisance_3.feature.0.6.0.4.selectboost  0.222222222222222        2         NA
#> nuisance_3.feature.0.6.0.7.selectboost  0.222222222222222        2         NA
#> nuisance_5.feature.0.6.0.7.selectboost  0.444444444444444        2         NA
#>                                         selected_features replicate
#> nuisance_1.feature.0.6.0.7.selectboost                 NA        NA
#> nuisance_10.feature.0.8.0.4.selectboost                NA        NA
#> nuisance_2.feature.0.6.0.4.selectboost                 NA        NA
#> nuisance_3.feature.0.6.0.4.selectboost                 NA        NA
#> nuisance_3.feature.0.6.0.7.selectboost                 NA        NA
#> nuisance_5.feature.0.6.0.7.selectboost                 NA        NA
#>                                         association_method group_method
#> nuisance_1.feature.0.6.0.7.selectboost              hybrid    threshold
#> nuisance_10.feature.0.8.0.4.selectboost             hybrid    threshold
#> nuisance_2.feature.0.6.0.4.selectboost              hybrid    threshold
#> nuisance_3.feature.0.6.0.4.selectboost              hybrid    threshold
#> nuisance_3.feature.0.6.0.7.selectboost              hybrid    threshold
#> nuisance_5.feature.0.6.0.7.selectboost              hybrid    threshold
#>                                         within_blocks bandwidth width
#> nuisance_1.feature.0.6.0.7.selectboost           TRUE         3    NA
#> nuisance_10.feature.0.8.0.4.selectboost          TRUE         3    NA
#> nuisance_2.feature.0.6.0.4.selectboost           TRUE         3    NA
#> nuisance_3.feature.0.6.0.4.selectboost           TRUE         3    NA
#> nuisance_3.feature.0.6.0.7.selectboost           TRUE         3    NA
#> nuisance_5.feature.0.6.0.7.selectboost           TRUE         3    NA
#>                                         n_replicates
#> nuisance_1.feature.0.6.0.7.selectboost             1
#> nuisance_10.feature.0.8.0.4.selectboost            1
#> nuisance_2.feature.0.6.0.4.selectboost             1
#> nuisance_3.feature.0.6.0.4.selectboost             1
#> nuisance_3.feature.0.6.0.7.selectboost             1
#> nuisance_5.feature.0.6.0.7.selectboost             1
```
