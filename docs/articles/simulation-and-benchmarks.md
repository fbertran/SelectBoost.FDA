# Simulation and Benchmark Workflows

`SelectBoost.FDA` now includes a validation layer for repeated
simulations, method benchmarks, plain-SelectBoost baselines, and direct
advantage summaries for FDA-aware `SelectBoost`.

## Simulate a benchmark scenario

``` r
library(SelectBoost.FDA)

sim_grid <- simulate_fda_scenario(
  n = 60,
  grid_length = 30,
  scenario = "localized_dense",
  representation = "grid",
  seed = 1
)

sim_grid
#> FDA simulation data
#>   observations: 60 
#>   features: 62 
#>   active features: 13 
#>   scenario: localized_dense 
#>   confounding strength: 0 
#>   active region scale: 1 
#>   local correlation: 0 
#>   active predictors: signal, age, treatment
head(selection_map(sim_grid$design))
#>           feature predictor  block position             argval representation
#> signal.1 signal_1    signal signal        1                  0           grid
#> signal.2 signal_2    signal signal        2 0.0344827586206897           grid
#> signal.3 signal_3    signal signal        3 0.0689655172413793           grid
#> signal.4 signal_4    signal signal        4  0.103448275862069           grid
#> signal.5 signal_5    signal signal        5  0.137931034482759           grid
#> signal.6 signal_6    signal signal        6  0.172413793103448           grid
#>          basis_type transform source_predictor source_representation
#> signal.1       <NA>  identity           signal                  grid
#> signal.2       <NA>  identity           signal                  grid
#> signal.3       <NA>  identity           signal                  grid
#> signal.4       <NA>  identity           signal                  grid
#> signal.5       <NA>  identity           signal                  grid
#> signal.6       <NA>  identity           signal                  grid
#>          source_position_start source_position_end source_argval_start
#> signal.1                     1                   1                   0
#> signal.2                     2                   2  0.0344827586206897
#> signal.3                     3                   3  0.0689655172413793
#> signal.4                     4                   4   0.103448275862069
#> signal.5                     5                   5   0.137931034482759
#> signal.6                     6                   6   0.172413793103448
#>           source_argval_end       domain_start         domain_end component
#> signal.1                  0                  0                  0      <NA>
#> signal.2 0.0344827586206897 0.0344827586206897 0.0344827586206897      <NA>
#> signal.3 0.0689655172413793 0.0689655172413793 0.0689655172413793      <NA>
#> signal.4  0.103448275862069  0.103448275862069  0.103448275862069      <NA>
#> signal.5  0.137931034482759  0.137931034482759  0.137931034482759      <NA>
#> signal.6  0.172413793103448  0.172413793103448  0.172413793103448      <NA>
#>          unit feature_index basis_component       domain_label
#> signal.1 <NA>             1            <NA>                  0
#> signal.2 <NA>             2            <NA> 0.0344827586206897
#> signal.3 <NA>             3            <NA> 0.0689655172413793
#> signal.4 <NA>             4            <NA>  0.103448275862069
#> signal.5 <NA>             5            <NA>  0.137931034482759
#> signal.6 <NA>             6            <NA>  0.172413793103448
sim_grid$truth$active_predictors
#> [1] "signal"    "age"       "treatment"
```

The returned object keeps both the fitted `fda_design` and the mapped
truth for the transformed feature space.

## Benchmark multiple methods on shared truth

``` r
bench <- benchmark_selection_methods(
  sim_grid,
  methods = c("stability", "interval", "selectboost", "plain_selectboost"),
  levels = c("feature", "group"),
  stability_args = list(selector = "lasso", B = 8, cutoff = 0.5, seed = 2),
  interval_args = list(selector = "lasso", width = 5, B = 8, cutoff = 0.5, seed = 3),
  selectboost_args = list(selector = "lasso", B = 4, steps.seq = c(0.7, 0.4), c0lim = FALSE),
  plain_selectboost_args = list(selector = "lasso", B = 4, steps.seq = c(0.7, 0.4), c0lim = FALSE)
)

bench
#> FDA benchmark
#>   methods: stability, interval, selectboost, plain_selectboost 
#>   rows: 12
bench$metrics
#>      level n_universe n_truth n_selected tp fp fn tn precision    recall
#> 1  feature         62      13          9  5  4  8 45 0.5555556 0.3846154
#> 2  feature         62      13         10  7  3  6 46 0.7000000 0.5384615
#> 3  feature         62      13         20  9 11  4 38 0.4500000 0.6923077
#> 4  feature         62      13         26 12 14  1 35 0.4615385 0.9230769
#> 5  feature         62      13         24 10 14  3 35 0.4166667 0.7692308
#> 6  feature         62      13         24 10 14  3 35 0.4166667 0.7692308
#> 7    group          4       3          4  3  1  0  0 0.7500000 1.0000000
#> 8    group         14       6          5  4  1  2  7 0.8000000 0.6666667
#> 9    group          4       3          4  3  1  0  0 0.7500000 1.0000000
#> 10   group          4       3          4  3  1  0  0 0.7500000 1.0000000
#> 11   group          4       3          4  3  1  0  0 0.7500000 1.0000000
#> 12   group          4       3          4  3  1  0  0 0.7500000 1.0000000
#>    specificity        f1   jaccard selection_rate            method       c0
#> 1    0.9183673 0.4545455 0.2941176      0.1451613         stability     <NA>
#> 2    0.9387755 0.6086957 0.4375000      0.1612903          interval     <NA>
#> 3    0.7755102 0.5454545 0.3750000      0.3225806       selectboost c0 = 0.7
#> 4    0.7142857 0.6153846 0.4444444      0.4193548       selectboost c0 = 0.4
#> 5    0.7142857 0.5405405 0.3703704      0.3870968 plain_selectboost c0 = 0.7
#> 6    0.7142857 0.5405405 0.3703704      0.3870968 plain_selectboost c0 = 0.4
#> 7    0.0000000 0.8571429 0.7500000      1.0000000         stability     <NA>
#> 8    0.8750000 0.7272727 0.5714286      0.3571429          interval     <NA>
#> 9    0.0000000 0.8571429 0.7500000      1.0000000       selectboost c0 = 0.7
#> 10   0.0000000 0.8571429 0.7500000      1.0000000       selectboost c0 = 0.4
#> 11   0.0000000 0.8571429 0.7500000      1.0000000 plain_selectboost c0 = 0.7
#> 12   0.0000000 0.8571429 0.7500000      1.0000000 plain_selectboost c0 = 0.4
#>           scenario representation   family
#> 1  localized_dense           grid gaussian
#> 2  localized_dense           grid gaussian
#> 3  localized_dense           grid gaussian
#> 4  localized_dense           grid gaussian
#> 5  localized_dense           grid gaussian
#> 6  localized_dense           grid gaussian
#> 7  localized_dense           grid gaussian
#> 8  localized_dense           grid gaussian
#> 9  localized_dense           grid gaussian
#> 10 localized_dense           grid gaussian
#> 11 localized_dense           grid gaussian
#> 12 localized_dense           grid gaussian
head(selection_map(bench, level = "group"))
#>   predictor group_id        group representation basis_type
#> 1    signal        1       signal           grid           
#> 2  nuisance        2     nuisance           grid           
#> 3       age        3          age         scalar           
#> 4 treatment        4    treatment         scalar           
#> 5    signal        1  signal[1:5]           grid           
#> 6    signal        2 signal[6:10]           grid           
#>   source_representation n_features start_position end_position
#> 1                  grid         30              1           30
#> 2                  grid         30              1           30
#> 3                scalar          1              1            1
#> 4                scalar          1              1            1
#> 5                  grid          5              1            5
#> 6                  grid          5              6           10
#>        start_argval        end_argval      domain_start        domain_end
#> 1                 0                 1                 0                 1
#> 2                 0                 1                 0                 1
#> 3               age               age               age               age
#> 4         treatment         treatment         treatment         treatment
#> 5                 0 0.137931034482759                 0 0.137931034482759
#> 6 0.172413793103448 0.310344827586207 0.172413793103448 0.310344827586207
#>   mean_feature_frequency max_feature_frequency selected_features
#> 1                  0.250                 1.000                 7
#> 2                  0.025                 0.250                 0
#> 3                  1.000                 1.000                 1
#> 4                  0.625                 0.625                 1
#> 5                  0.100                 0.250                 0
#> 6                  0.375                 0.750                 2
#>   group_frequency group_selected    method interval_start interval_end
#> 1           1.000           TRUE stability             NA           NA
#> 2           0.500           TRUE stability             NA           NA
#> 3           1.000           TRUE stability             NA           NA
#> 4           0.625           TRUE stability             NA           NA
#> 5           0.375          FALSE  interval              1            5
#> 6           1.000           TRUE  interval              6           10
#>   interval_label   c0 mean_selection max_selection
#> 1           <NA> <NA>             NA            NA
#> 2           <NA> <NA>             NA            NA
#> 3           <NA> <NA>             NA            NA
#> 4           <NA> <NA>             NA            NA
#> 5    signal[1:5] <NA>             NA            NA
#> 6   signal[6:10] <NA>             NA            NA
summarise_benchmark_performance(bench, level = "feature", metric = "f1")
#>                                                                scenario
#> localized_dense.grid.gaussian.interval.feature          localized_dense
#> localized_dense.grid.gaussian.plain_selectboost.feature localized_dense
#> localized_dense.grid.gaussian.selectboost.feature       localized_dense
#> localized_dense.grid.gaussian.stability.feature         localized_dense
#>                                                         representation   family
#> localized_dense.grid.gaussian.interval.feature                    grid gaussian
#> localized_dense.grid.gaussian.plain_selectboost.feature           grid gaussian
#> localized_dense.grid.gaussian.selectboost.feature                 grid gaussian
#> localized_dense.grid.gaussian.stability.feature                   grid gaussian
#>                                                                    method
#> localized_dense.grid.gaussian.interval.feature                   interval
#> localized_dense.grid.gaussian.plain_selectboost.feature plain_selectboost
#> localized_dense.grid.gaussian.selectboost.feature             selectboost
#> localized_dense.grid.gaussian.stability.feature                 stability
#>                                                           level n_rep
#> localized_dense.grid.gaussian.interval.feature          feature     1
#> localized_dense.grid.gaussian.plain_selectboost.feature feature     1
#> localized_dense.grid.gaussian.selectboost.feature       feature     1
#> localized_dense.grid.gaussian.stability.feature         feature     1
#>                                                         n_truth_mean n_truth_sd
#> localized_dense.grid.gaussian.interval.feature                    13          0
#> localized_dense.grid.gaussian.plain_selectboost.feature           13          0
#> localized_dense.grid.gaussian.selectboost.feature                 13          0
#> localized_dense.grid.gaussian.stability.feature                   13          0
#>                                                         n_selected_mean
#> localized_dense.grid.gaussian.interval.feature                       10
#> localized_dense.grid.gaussian.plain_selectboost.feature              24
#> localized_dense.grid.gaussian.selectboost.feature                    26
#> localized_dense.grid.gaussian.stability.feature                       9
#>                                                         n_selected_sd tp_mean
#> localized_dense.grid.gaussian.interval.feature                      0       7
#> localized_dense.grid.gaussian.plain_selectboost.feature             0      10
#> localized_dense.grid.gaussian.selectboost.feature                   0      12
#> localized_dense.grid.gaussian.stability.feature                     0       5
#>                                                         tp_sd fp_mean fp_sd
#> localized_dense.grid.gaussian.interval.feature              0       3     0
#> localized_dense.grid.gaussian.plain_selectboost.feature     0      14     0
#> localized_dense.grid.gaussian.selectboost.feature           0      14     0
#> localized_dense.grid.gaussian.stability.feature             0       4     0
#>                                                         fn_mean fn_sd tn_mean
#> localized_dense.grid.gaussian.interval.feature                6     0      46
#> localized_dense.grid.gaussian.plain_selectboost.feature       3     0      35
#> localized_dense.grid.gaussian.selectboost.feature             1     0      35
#> localized_dense.grid.gaussian.stability.feature               8     0      45
#>                                                         tn_sd precision_mean
#> localized_dense.grid.gaussian.interval.feature              0      0.7000000
#> localized_dense.grid.gaussian.plain_selectboost.feature     0      0.4166667
#> localized_dense.grid.gaussian.selectboost.feature           0      0.4615385
#> localized_dense.grid.gaussian.stability.feature             0      0.5555556
#>                                                         precision_sd
#> localized_dense.grid.gaussian.interval.feature                     0
#> localized_dense.grid.gaussian.plain_selectboost.feature            0
#> localized_dense.grid.gaussian.selectboost.feature                  0
#> localized_dense.grid.gaussian.stability.feature                    0
#>                                                         recall_mean recall_sd
#> localized_dense.grid.gaussian.interval.feature            0.5384615         0
#> localized_dense.grid.gaussian.plain_selectboost.feature   0.7692308         0
#> localized_dense.grid.gaussian.selectboost.feature         0.9230769         0
#> localized_dense.grid.gaussian.stability.feature           0.3846154         0
#>                                                         specificity_mean
#> localized_dense.grid.gaussian.interval.feature                 0.9387755
#> localized_dense.grid.gaussian.plain_selectboost.feature        0.7142857
#> localized_dense.grid.gaussian.selectboost.feature              0.7142857
#> localized_dense.grid.gaussian.stability.feature                0.9183673
#>                                                         specificity_sd
#> localized_dense.grid.gaussian.interval.feature                       0
#> localized_dense.grid.gaussian.plain_selectboost.feature              0
#> localized_dense.grid.gaussian.selectboost.feature                    0
#> localized_dense.grid.gaussian.stability.feature                      0
#>                                                           f1_mean f1_sd
#> localized_dense.grid.gaussian.interval.feature          0.6086957     0
#> localized_dense.grid.gaussian.plain_selectboost.feature 0.5405405     0
#> localized_dense.grid.gaussian.selectboost.feature       0.6153846     0
#> localized_dense.grid.gaussian.stability.feature         0.4545455     0
#>                                                         jaccard_mean jaccard_sd
#> localized_dense.grid.gaussian.interval.feature             0.4375000          0
#> localized_dense.grid.gaussian.plain_selectboost.feature    0.3703704          0
#> localized_dense.grid.gaussian.selectboost.feature          0.4444444          0
#> localized_dense.grid.gaussian.stability.feature            0.2941176          0
#>                                                         selection_rate_mean
#> localized_dense.grid.gaussian.interval.feature                    0.1612903
#> localized_dense.grid.gaussian.plain_selectboost.feature           0.3870968
#> localized_dense.grid.gaussian.selectboost.feature                 0.4193548
#> localized_dense.grid.gaussian.stability.feature                   0.1451613
#>                                                         selection_rate_sd
#> localized_dense.grid.gaussian.interval.feature                          0
#> localized_dense.grid.gaussian.plain_selectboost.feature                 0
#> localized_dense.grid.gaussian.selectboost.feature                       0
#> localized_dense.grid.gaussian.stability.feature                         0
summarise_benchmark_advantage(
  bench,
  target = "selectboost",
  reference = c("plain_selectboost", "stability"),
  level = "feature",
  metric = "f1"
)
#>                                                                               scenario
#> localized_dense.grid.gaussian.feature.selectboost.plain_selectboost.f1 localized_dense
#> localized_dense.grid.gaussian.feature.selectboost.stability.f1         localized_dense
#>                                                                        representation
#> localized_dense.grid.gaussian.feature.selectboost.plain_selectboost.f1           grid
#> localized_dense.grid.gaussian.feature.selectboost.stability.f1                   grid
#>                                                                          family
#> localized_dense.grid.gaussian.feature.selectboost.plain_selectboost.f1 gaussian
#> localized_dense.grid.gaussian.feature.selectboost.stability.f1         gaussian
#>                                                                          level
#> localized_dense.grid.gaussian.feature.selectboost.plain_selectboost.f1 feature
#> localized_dense.grid.gaussian.feature.selectboost.stability.f1         feature
#>                                                                             target
#> localized_dense.grid.gaussian.feature.selectboost.plain_selectboost.f1 selectboost
#> localized_dense.grid.gaussian.feature.selectboost.stability.f1         selectboost
#>                                                                                reference
#> localized_dense.grid.gaussian.feature.selectboost.plain_selectboost.f1 plain_selectboost
#> localized_dense.grid.gaussian.feature.selectboost.stability.f1                 stability
#>                                                                        metric
#> localized_dense.grid.gaussian.feature.selectboost.plain_selectboost.f1     f1
#> localized_dense.grid.gaussian.feature.selectboost.stability.f1             f1
#>                                                                        n_rep
#> localized_dense.grid.gaussian.feature.selectboost.plain_selectboost.f1     1
#> localized_dense.grid.gaussian.feature.selectboost.stability.f1             1
#>                                                                        target_value_mean
#> localized_dense.grid.gaussian.feature.selectboost.plain_selectboost.f1         0.6153846
#> localized_dense.grid.gaussian.feature.selectboost.stability.f1                 0.6153846
#>                                                                        reference_value_mean
#> localized_dense.grid.gaussian.feature.selectboost.plain_selectboost.f1            0.5405405
#> localized_dense.grid.gaussian.feature.selectboost.stability.f1                    0.4545455
#>                                                                        delta_mean
#> localized_dense.grid.gaussian.feature.selectboost.plain_selectboost.f1 0.07484407
#> localized_dense.grid.gaussian.feature.selectboost.stability.f1         0.16083916
#>                                                                        delta_sd
#> localized_dense.grid.gaussian.feature.selectboost.plain_selectboost.f1        0
#> localized_dense.grid.gaussian.feature.selectboost.stability.f1                0
#>                                                                        win_rate
#> localized_dense.grid.gaussian.feature.selectboost.plain_selectboost.f1        1
#> localized_dense.grid.gaussian.feature.selectboost.stability.f1                1
```

This keeps the comparison object available, so the same
[`selection_map()`](https://fbertran.github.io/SelectBoost.FDA/reference/selection_map.md)
and
[`selected()`](https://fbertran.github.io/SelectBoost.FDA/reference/selected.md)
methods work on top of the benchmark output. The summary helpers make it
easier to answer the benchmark question directly: whether FDA-aware
`SelectBoost` improves feature recovery over the plain baseline and
grouped stability selection once each method is evaluated at its best
`c0`.

## Run a repeated study

``` r
study_dense <- run_simulation_study(
  n_rep = 2,
  simulate_args = list(
    n = 50,
    grid_length = 28,
    scenario = "localized_dense",
    representation = "basis"
  ),
  benchmark_args = list(
    methods = c("stability", "selectboost", "plain_selectboost"),
    levels = c("feature", "group", "basis"),
    stability_args = list(selector = "lasso", B = 6, cutoff = 0.5, seed = 4),
    selectboost_args = list(selector = "lasso", B = 4, steps.seq = c(0.7, 0.4), c0lim = FALSE),
    plain_selectboost_args = list(selector = "lasso", B = 4, steps.seq = c(0.7, 0.4), c0lim = FALSE)
  ),
  seed = 10
)

study_smooth <- run_simulation_study(
  n_rep = 2,
  simulate_args = list(
    n = 50,
    grid_length = 28,
    scenario = "distributed_smooth",
    representation = "basis"
  ),
  benchmark_args = list(
    methods = c("stability", "selectboost", "plain_selectboost"),
    levels = c("feature", "group", "basis"),
    stability_args = list(selector = "lasso", B = 6, cutoff = 0.5, seed = 14),
    selectboost_args = list(selector = "lasso", B = 4, steps.seq = c(0.7, 0.4), c0lim = FALSE),
    plain_selectboost_args = list(selector = "lasso", B = 4, steps.seq = c(0.7, 0.4), c0lim = FALSE)
  ),
  seed = 20
)

summarise_benchmark_advantage(
  study_dense,
  target = "selectboost",
  reference = c("plain_selectboost", "stability"),
  level = "feature",
  metric = "f1"
)
#>                                                                                scenario
#> localized_dense.basis.gaussian.feature.selectboost.plain_selectboost.f1 localized_dense
#> localized_dense.basis.gaussian.feature.selectboost.stability.f1         localized_dense
#>                                                                         representation
#> localized_dense.basis.gaussian.feature.selectboost.plain_selectboost.f1          basis
#> localized_dense.basis.gaussian.feature.selectboost.stability.f1                  basis
#>                                                                           family
#> localized_dense.basis.gaussian.feature.selectboost.plain_selectboost.f1 gaussian
#> localized_dense.basis.gaussian.feature.selectboost.stability.f1         gaussian
#>                                                                           level
#> localized_dense.basis.gaussian.feature.selectboost.plain_selectboost.f1 feature
#> localized_dense.basis.gaussian.feature.selectboost.stability.f1         feature
#>                                                                              target
#> localized_dense.basis.gaussian.feature.selectboost.plain_selectboost.f1 selectboost
#> localized_dense.basis.gaussian.feature.selectboost.stability.f1         selectboost
#>                                                                                 reference
#> localized_dense.basis.gaussian.feature.selectboost.plain_selectboost.f1 plain_selectboost
#> localized_dense.basis.gaussian.feature.selectboost.stability.f1                 stability
#>                                                                         metric
#> localized_dense.basis.gaussian.feature.selectboost.plain_selectboost.f1     f1
#> localized_dense.basis.gaussian.feature.selectboost.stability.f1             f1
#>                                                                         n_rep
#> localized_dense.basis.gaussian.feature.selectboost.plain_selectboost.f1     2
#> localized_dense.basis.gaussian.feature.selectboost.stability.f1             2
#>                                                                         target_value_mean
#> localized_dense.basis.gaussian.feature.selectboost.plain_selectboost.f1         0.8666667
#> localized_dense.basis.gaussian.feature.selectboost.stability.f1                 0.8666667
#>                                                                         reference_value_mean
#> localized_dense.basis.gaussian.feature.selectboost.plain_selectboost.f1            0.8444444
#> localized_dense.basis.gaussian.feature.selectboost.stability.f1                    0.6923077
#>                                                                         delta_mean
#> localized_dense.basis.gaussian.feature.selectboost.plain_selectboost.f1 0.02222222
#> localized_dense.basis.gaussian.feature.selectboost.stability.f1         0.17435897
#>                                                                           delta_sd
#> localized_dense.basis.gaussian.feature.selectboost.plain_selectboost.f1 0.15713484
#> localized_dense.basis.gaussian.feature.selectboost.stability.f1         0.01450475
#>                                                                         win_rate
#> localized_dense.basis.gaussian.feature.selectboost.plain_selectboost.f1      0.5
#> localized_dense.basis.gaussian.feature.selectboost.stability.f1              1.0

summarise_benchmark_advantage(
  study_smooth,
  target = "selectboost",
  reference = c("plain_selectboost", "stability"),
  level = "feature",
  metric = "f1"
)
#>                                                                                      scenario
#> distributed_smooth.basis.gaussian.feature.selectboost.plain_selectboost.f1 distributed_smooth
#> distributed_smooth.basis.gaussian.feature.selectboost.stability.f1         distributed_smooth
#>                                                                            representation
#> distributed_smooth.basis.gaussian.feature.selectboost.plain_selectboost.f1          basis
#> distributed_smooth.basis.gaussian.feature.selectboost.stability.f1                  basis
#>                                                                              family
#> distributed_smooth.basis.gaussian.feature.selectboost.plain_selectboost.f1 gaussian
#> distributed_smooth.basis.gaussian.feature.selectboost.stability.f1         gaussian
#>                                                                              level
#> distributed_smooth.basis.gaussian.feature.selectboost.plain_selectboost.f1 feature
#> distributed_smooth.basis.gaussian.feature.selectboost.stability.f1         feature
#>                                                                                 target
#> distributed_smooth.basis.gaussian.feature.selectboost.plain_selectboost.f1 selectboost
#> distributed_smooth.basis.gaussian.feature.selectboost.stability.f1         selectboost
#>                                                                                    reference
#> distributed_smooth.basis.gaussian.feature.selectboost.plain_selectboost.f1 plain_selectboost
#> distributed_smooth.basis.gaussian.feature.selectboost.stability.f1                 stability
#>                                                                            metric
#> distributed_smooth.basis.gaussian.feature.selectboost.plain_selectboost.f1     f1
#> distributed_smooth.basis.gaussian.feature.selectboost.stability.f1             f1
#>                                                                            n_rep
#> distributed_smooth.basis.gaussian.feature.selectboost.plain_selectboost.f1     2
#> distributed_smooth.basis.gaussian.feature.selectboost.stability.f1             2
#>                                                                            target_value_mean
#> distributed_smooth.basis.gaussian.feature.selectboost.plain_selectboost.f1         0.8128655
#> distributed_smooth.basis.gaussian.feature.selectboost.stability.f1                 0.8128655
#>                                                                            reference_value_mean
#> distributed_smooth.basis.gaussian.feature.selectboost.plain_selectboost.f1            0.7418301
#> distributed_smooth.basis.gaussian.feature.selectboost.stability.f1                    0.5000000
#>                                                                            delta_mean
#> distributed_smooth.basis.gaussian.feature.selectboost.plain_selectboost.f1 0.07103543
#> distributed_smooth.basis.gaussian.feature.selectboost.stability.f1         0.31286550
#>                                                                              delta_sd
#> distributed_smooth.basis.gaussian.feature.selectboost.plain_selectboost.f1 0.05667557
#> distributed_smooth.basis.gaussian.feature.selectboost.stability.f1         0.10751331
#>                                                                            win_rate
#> distributed_smooth.basis.gaussian.feature.selectboost.plain_selectboost.f1        1
#> distributed_smooth.basis.gaussian.feature.selectboost.stability.f1                1
```

The repeated-study summary reports the mean and standard deviation of
recovery metrics by method, evaluation level, scenario, and `c0` when
applicable. In practice, the `localized_dense` setting is the most
direct stress test for the FDA-aware grouping built into
[`selectboost_fda()`](https://fbertran.github.io/SelectBoost.FDA/reference/selectboost_fda.md).

## Run a targeted sensitivity study for FDA-aware SelectBoost

``` r
sensitivity <- run_selectboost_sensitivity_study(
  n_rep = 1,
  simulate_grid = data.frame(
    scenario = c("localized_dense", "confounded_blocks"),
    confounding_strength = c(0.4, 0.9),
    active_region_scale = c(0.8, 0.7),
    local_correlation = c(1, 2),
    stringsAsFactors = FALSE
  ),
  selectboost_grid = data.frame(
    association_method = c("correlation", "hybrid", "interval"),
    bandwidth = c(NA, 4, 4),
    stringsAsFactors = FALSE
  ),
  simulate_args = list(n = 50, grid_length = 28, representation = "grid"),
  benchmark_args = list(
    methods = c("stability", "selectboost", "plain_selectboost"),
    levels = c("feature", "group"),
    stability_args = list(selector = "lasso", B = 6, cutoff = 0.5, seed = 40),
    selectboost_args = list(selector = "lasso", B = 4, steps.seq = c(0.7, 0.4), c0lim = FALSE),
    plain_selectboost_args = list(selector = "lasso", B = 4, steps.seq = c(0.7, 0.4), c0lim = FALSE)
  ),
  seed = 50
)

summarise_benchmark_advantage(
  sensitivity,
  target = "selectboost",
  reference = "plain_selectboost",
  level = "feature",
  metric = "f1"
)
#>                                                                                                        scenario
#> confounded_blocks.grid.gaussian.hybrid.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1   confounded_blocks
#> confounded_blocks.grid.gaussian.interval.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1 confounded_blocks
#> localized_dense.grid.gaussian.hybrid.4.0.4.0.8.1.feature.selectboost.plain_selectboost.f1       localized_dense
#> localized_dense.grid.gaussian.interval.4.0.4.0.8.1.feature.selectboost.plain_selectboost.f1     localized_dense
#>                                                                                               representation
#> confounded_blocks.grid.gaussian.hybrid.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1             grid
#> confounded_blocks.grid.gaussian.interval.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1           grid
#> localized_dense.grid.gaussian.hybrid.4.0.4.0.8.1.feature.selectboost.plain_selectboost.f1               grid
#> localized_dense.grid.gaussian.interval.4.0.4.0.8.1.feature.selectboost.plain_selectboost.f1             grid
#>                                                                                                 family
#> confounded_blocks.grid.gaussian.hybrid.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1   gaussian
#> confounded_blocks.grid.gaussian.interval.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1 gaussian
#> localized_dense.grid.gaussian.hybrid.4.0.4.0.8.1.feature.selectboost.plain_selectboost.f1     gaussian
#> localized_dense.grid.gaussian.interval.4.0.4.0.8.1.feature.selectboost.plain_selectboost.f1   gaussian
#>                                                                                               association_method
#> confounded_blocks.grid.gaussian.hybrid.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1               hybrid
#> confounded_blocks.grid.gaussian.interval.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1           interval
#> localized_dense.grid.gaussian.hybrid.4.0.4.0.8.1.feature.selectboost.plain_selectboost.f1                 hybrid
#> localized_dense.grid.gaussian.interval.4.0.4.0.8.1.feature.selectboost.plain_selectboost.f1             interval
#>                                                                                               bandwidth
#> confounded_blocks.grid.gaussian.hybrid.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1           4
#> confounded_blocks.grid.gaussian.interval.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1         4
#> localized_dense.grid.gaussian.hybrid.4.0.4.0.8.1.feature.selectboost.plain_selectboost.f1             4
#> localized_dense.grid.gaussian.interval.4.0.4.0.8.1.feature.selectboost.plain_selectboost.f1           4
#>                                                                                               confounding_strength
#> confounded_blocks.grid.gaussian.hybrid.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1                    0.9
#> confounded_blocks.grid.gaussian.interval.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1                  0.9
#> localized_dense.grid.gaussian.hybrid.4.0.4.0.8.1.feature.selectboost.plain_selectboost.f1                      0.4
#> localized_dense.grid.gaussian.interval.4.0.4.0.8.1.feature.selectboost.plain_selectboost.f1                    0.4
#>                                                                                               active_region_scale
#> confounded_blocks.grid.gaussian.hybrid.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1                   0.7
#> confounded_blocks.grid.gaussian.interval.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1                 0.7
#> localized_dense.grid.gaussian.hybrid.4.0.4.0.8.1.feature.selectboost.plain_selectboost.f1                     0.8
#> localized_dense.grid.gaussian.interval.4.0.4.0.8.1.feature.selectboost.plain_selectboost.f1                   0.8
#>                                                                                               local_correlation
#> confounded_blocks.grid.gaussian.hybrid.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1                   2
#> confounded_blocks.grid.gaussian.interval.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1                 2
#> localized_dense.grid.gaussian.hybrid.4.0.4.0.8.1.feature.selectboost.plain_selectboost.f1                     1
#> localized_dense.grid.gaussian.interval.4.0.4.0.8.1.feature.selectboost.plain_selectboost.f1                   1
#>                                                                                                 level
#> confounded_blocks.grid.gaussian.hybrid.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1   feature
#> confounded_blocks.grid.gaussian.interval.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1 feature
#> localized_dense.grid.gaussian.hybrid.4.0.4.0.8.1.feature.selectboost.plain_selectboost.f1     feature
#> localized_dense.grid.gaussian.interval.4.0.4.0.8.1.feature.selectboost.plain_selectboost.f1   feature
#>                                                                                                    target
#> confounded_blocks.grid.gaussian.hybrid.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1   selectboost
#> confounded_blocks.grid.gaussian.interval.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1 selectboost
#> localized_dense.grid.gaussian.hybrid.4.0.4.0.8.1.feature.selectboost.plain_selectboost.f1     selectboost
#> localized_dense.grid.gaussian.interval.4.0.4.0.8.1.feature.selectboost.plain_selectboost.f1   selectboost
#>                                                                                                       reference
#> confounded_blocks.grid.gaussian.hybrid.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1   plain_selectboost
#> confounded_blocks.grid.gaussian.interval.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1 plain_selectboost
#> localized_dense.grid.gaussian.hybrid.4.0.4.0.8.1.feature.selectboost.plain_selectboost.f1     plain_selectboost
#> localized_dense.grid.gaussian.interval.4.0.4.0.8.1.feature.selectboost.plain_selectboost.f1   plain_selectboost
#>                                                                                               metric
#> confounded_blocks.grid.gaussian.hybrid.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1       f1
#> confounded_blocks.grid.gaussian.interval.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1     f1
#> localized_dense.grid.gaussian.hybrid.4.0.4.0.8.1.feature.selectboost.plain_selectboost.f1         f1
#> localized_dense.grid.gaussian.interval.4.0.4.0.8.1.feature.selectboost.plain_selectboost.f1       f1
#>                                                                                               n_rep
#> confounded_blocks.grid.gaussian.hybrid.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1       1
#> confounded_blocks.grid.gaussian.interval.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1     1
#> localized_dense.grid.gaussian.hybrid.4.0.4.0.8.1.feature.selectboost.plain_selectboost.f1         1
#> localized_dense.grid.gaussian.interval.4.0.4.0.8.1.feature.selectboost.plain_selectboost.f1       1
#>                                                                                               target_value_mean
#> confounded_blocks.grid.gaussian.hybrid.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1           0.5925926
#> confounded_blocks.grid.gaussian.interval.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1         0.6666667
#> localized_dense.grid.gaussian.hybrid.4.0.4.0.8.1.feature.selectboost.plain_selectboost.f1             0.5714286
#> localized_dense.grid.gaussian.interval.4.0.4.0.8.1.feature.selectboost.plain_selectboost.f1           0.5161290
#>                                                                                               reference_value_mean
#> confounded_blocks.grid.gaussian.hybrid.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1              0.4375000
#> confounded_blocks.grid.gaussian.interval.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1            0.5000000
#> localized_dense.grid.gaussian.hybrid.4.0.4.0.8.1.feature.selectboost.plain_selectboost.f1                0.4571429
#> localized_dense.grid.gaussian.interval.4.0.4.0.8.1.feature.selectboost.plain_selectboost.f1              0.4848485
#>                                                                                               delta_mean
#> confounded_blocks.grid.gaussian.hybrid.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1   0.15509259
#> confounded_blocks.grid.gaussian.interval.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1 0.16666667
#> localized_dense.grid.gaussian.hybrid.4.0.4.0.8.1.feature.selectboost.plain_selectboost.f1     0.11428571
#> localized_dense.grid.gaussian.interval.4.0.4.0.8.1.feature.selectboost.plain_selectboost.f1   0.03128055
#>                                                                                               delta_sd
#> confounded_blocks.grid.gaussian.hybrid.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1          0
#> confounded_blocks.grid.gaussian.interval.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1        0
#> localized_dense.grid.gaussian.hybrid.4.0.4.0.8.1.feature.selectboost.plain_selectboost.f1            0
#> localized_dense.grid.gaussian.interval.4.0.4.0.8.1.feature.selectboost.plain_selectboost.f1          0
#>                                                                                               win_rate
#> confounded_blocks.grid.gaussian.hybrid.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1          1
#> confounded_blocks.grid.gaussian.interval.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1        1
#> localized_dense.grid.gaussian.hybrid.4.0.4.0.8.1.feature.selectboost.plain_selectboost.f1            1
#> localized_dense.grid.gaussian.interval.4.0.4.0.8.1.feature.selectboost.plain_selectboost.f1          1
```

This is the intended benchmark workflow when the goal is to show when
FDA-aware grouping matters. The summary table keeps
`association_method`, `bandwidth`, `confounding_strength`,
`active_region_scale`, and `local_correlation` as explicit columns, so
it is straightforward to isolate the settings where
[`selectboost_fda()`](https://fbertran.github.io/SelectBoost.FDA/reference/selectboost_fda.md)
gains over the plain baseline.

## Inspect the saved larger study

The repository also ships a larger saved sensitivity study generated by
`tools/run_selectboost_sensitivity_study.R`. That script runs a broader
sweep, writes to an explicit `--output-dir=...` path when supplied, and
otherwise defaults to a subdirectory of
[`tempdir()`](https://rdrr.io/r/base/tempfile.html). The files under
`inst/extdata/benchmarks/` are the shipped saved results from one
benchmark run.

``` r
benchmark_dir <- system.file("extdata", "benchmarks", package = "SelectBoost.FDA")
top_feature_settings <- utils::read.csv(
  file.path(benchmark_dir, "selectboost_sensitivity_top_settings.csv"),
  stringsAsFactors = FALSE
)

utils::head(
  top_feature_settings[
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
  10
)
#>             scenario confounding_strength active_region_scale local_correlation
#> 1  confounded_blocks                  0.6                 0.5                 2
#> 2  confounded_blocks                  1.0                 0.8                 2
#> 3  confounded_blocks                  0.6                 0.8                 2
#> 4    localized_dense                  0.6                 0.5                 2
#> 5  confounded_blocks                  0.6                 0.5                 2
#> 6  confounded_blocks                  0.6                 0.5                 2
#> 7  confounded_blocks                  1.0                 0.5                 0
#> 8    localized_dense                  1.0                 0.8                 2
#> 9  confounded_blocks                  1.0                 0.5                 2
#> 10   localized_dense                  0.6                 0.8                 2
#>    association_method bandwidth selectboost_f1_mean plain_selectboost_f1_mean
#> 1            interval         8           0.5362319                 0.4087266
#> 2              hybrid         4           0.5885135                 0.4826750
#> 3              hybrid         4           0.5833671                 0.4944862
#> 4        neighborhood         4           0.4972542                 0.4144859
#> 5              hybrid         4           0.5429293                 0.4657088
#> 6        neighborhood         4           0.5072823                 0.4322990
#> 7            interval         8           0.5323457                 0.4575499
#> 8        neighborhood         4           0.5635386                 0.4924953
#> 9        neighborhood         4           0.4655172                 0.3983586
#> 10           interval         8           0.5392157                 0.4769314
#>    delta_mean  win_rate
#> 1  0.12750533 1.0000000
#> 2  0.10583853 1.0000000
#> 3  0.08888092 1.0000000
#> 4  0.08276831 0.6666667
#> 5  0.07722048 0.6666667
#> 6  0.07498337 1.0000000
#> 7  0.07479582 1.0000000
#> 8  0.07104330 0.6666667
#> 9  0.06715866 1.0000000
#> 10 0.06228427 0.6666667
```

The key comparison columns are `selectboost_f1_mean`,
`plain_selectboost_f1_mean`, and `delta_mean`. This makes the algorithm
comparison explicit at the feature-selection level while keeping the
FDA-specific settings attached to each row.
