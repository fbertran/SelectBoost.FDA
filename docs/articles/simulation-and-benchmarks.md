# Simulation and Benchmark Workflows

`SelectBoost.FDA` now includes a validation layer for repeated
simulations, method benchmarks, and plain-SelectBoost baselines.

## Simulate a benchmark scenario

``` r
library(SelectBoost.FDA)

sim_grid <- simulate_fda_scenario(
  n = 60,
  grid_length = 30,
  representation = "grid",
  seed = 1
)

sim_grid
#> FDA simulation data
#>   observations: 60 
#>   features: 62 
#>   active features: 13 
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
#> 1  feature         62      13          6  5  1  8 48 0.8333333 0.3846154
#> 2  feature         62      13         10  7  3  6 46 0.7000000 0.5384615
#> 3  feature         62      13         20  9 11  4 38 0.4500000 0.6923077
#> 4  feature         62      13         26 10 16  3 33 0.3846154 0.7692308
#> 5  feature         62      13         18  9  9  4 40 0.5000000 0.6923077
#> 6  feature         62      13         28 12 16  1 33 0.4285714 0.9230769
#> 7    group          4       3          3  3  0  0  1 1.0000000 1.0000000
#> 8    group         14       6          6  6  0  0  8 1.0000000 1.0000000
#> 9    group          4       3          4  3  1  0  0 0.7500000 1.0000000
#> 10   group          4       3          4  3  1  0  0 0.7500000 1.0000000
#> 11   group          4       3          3  3  0  0  1 1.0000000 1.0000000
#> 12   group          4       3          4  3  1  0  0 0.7500000 1.0000000
#>    specificity        f1   jaccard selection_rate            method       c0
#> 1    0.9795918 0.5263158 0.3571429     0.09677419         stability     <NA>
#> 2    0.9387755 0.6086957 0.4375000     0.16129032          interval     <NA>
#> 3    0.7755102 0.5454545 0.3750000     0.32258065       selectboost c0 = 0.7
#> 4    0.6734694 0.5128205 0.3448276     0.41935484       selectboost c0 = 0.4
#> 5    0.8163265 0.5806452 0.4090909     0.29032258 plain_selectboost c0 = 0.7
#> 6    0.6734694 0.5853659 0.4137931     0.45161290 plain_selectboost c0 = 0.4
#> 7    1.0000000 1.0000000 1.0000000     0.75000000         stability     <NA>
#> 8    1.0000000 1.0000000 1.0000000     0.42857143          interval     <NA>
#> 9    0.0000000 0.8571429 0.7500000     1.00000000       selectboost c0 = 0.7
#> 10   0.0000000 0.8571429 0.7500000     1.00000000       selectboost c0 = 0.4
#> 11   1.0000000 1.0000000 1.0000000     0.75000000 plain_selectboost c0 = 0.7
#> 12   0.0000000 0.8571429 0.7500000     1.00000000 plain_selectboost c0 = 0.4
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
#> 1                 0.2125                 0.875                 4
#> 2                 0.0125                 0.125                 0
#> 3                 1.0000                 1.000                 1
#> 4                 0.7500                 0.750                 1
#> 5                 0.1750                 0.250                 0
#> 6                 0.4000                 0.875                 3
#>   group_frequency group_selected    method interval_start interval_end
#> 1           1.000           TRUE stability             NA           NA
#> 2           0.375          FALSE stability             NA           NA
#> 3           1.000           TRUE stability             NA           NA
#> 4           0.750           TRUE stability             NA           NA
#> 5           0.625           TRUE  interval              1            5
#> 6           1.000           TRUE  interval              6           10
#>   interval_label   c0 mean_selection max_selection
#> 1           <NA> <NA>             NA            NA
#> 2           <NA> <NA>             NA            NA
#> 3           <NA> <NA>             NA            NA
#> 4           <NA> <NA>             NA            NA
#> 5    signal[1:5] <NA>             NA            NA
#> 6   signal[6:10] <NA>             NA            NA
```

This keeps the comparison object available, so the same
[`selection_map()`](https://fbertran.github.io/SelectBoost.FDA/reference/selection_map.md)
and
[`selected()`](https://fbertran.github.io/SelectBoost.FDA/reference/selected.md)
methods work on top of the benchmark output.

## Run a repeated study

``` r
study <- run_simulation_study(
  n_rep = 2,
  simulate_args = list(
    n = 50,
    grid_length = 28,
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

study
#> FDA simulation study
#>   replications: 2 
#>   rows: 30
summary(study)
#> FDA simulation study summary
#>             method   level       c0 n_rep n_truth_mean n_truth_sd
#>  plain_selectboost   basis c0 = 0.4     2            1          0
#>  plain_selectboost   basis c0 = 0.7     2            1          0
#>  plain_selectboost feature c0 = 0.4     2            8          0
#>  plain_selectboost feature c0 = 0.7     2            8          0
#>  plain_selectboost   group c0 = 0.4     2            3          0
#>  plain_selectboost   group c0 = 0.7     2            3          0
#>        selectboost   basis c0 = 0.4     2            1          0
#>        selectboost   basis c0 = 0.7     2            1          0
#>        selectboost feature c0 = 0.4     2            8          0
#>        selectboost feature c0 = 0.7     2            8          0
#>        selectboost   group c0 = 0.4     2            3          0
#>        selectboost   group c0 = 0.7     2            3          0
#>  n_selected_mean n_selected_sd tp_mean     tp_sd fp_mean     fp_sd fn_mean
#>              2.0     0.0000000     1.0 0.0000000     1.0 0.0000000     0.0
#>              2.0     0.0000000     1.0 0.0000000     1.0 0.0000000     0.0
#>             11.0     0.0000000     7.5 0.7071068     3.5 0.7071068     0.5
#>              9.5     2.1213203     7.5 0.7071068     2.0 1.4142136     0.5
#>              4.0     0.0000000     3.0 0.0000000     1.0 0.0000000     0.0
#>              4.0     0.0000000     3.0 0.0000000     1.0 0.0000000     0.0
#>              2.0     0.0000000     1.0 0.0000000     1.0 0.0000000     0.0
#>              2.0     0.0000000     1.0 0.0000000     1.0 0.0000000     0.0
#>              9.0     0.0000000     6.0 0.0000000     3.0 0.0000000     2.0
#>              9.5     0.7071068     6.5 0.7071068     3.0 0.0000000     1.5
#>              4.0     0.0000000     3.0 0.0000000     1.0 0.0000000     0.0
#>              4.0     0.0000000     3.0 0.0000000     1.0 0.0000000     0.0
#>      fn_sd tn_mean     tn_sd precision_mean precision_sd recall_mean  recall_sd
#>  0.0000000     0.0 0.0000000      0.5000000   0.00000000      1.0000 0.00000000
#>  0.0000000     0.0 0.0000000      0.5000000   0.00000000      1.0000 0.00000000
#>  0.7071068     3.5 0.7071068      0.6818182   0.06428243      0.9375 0.08838835
#>  0.7071068     5.0 1.4142136      0.8011364   0.10445896      0.9375 0.08838835
#>  0.0000000     0.0 0.0000000      0.7500000   0.00000000      1.0000 0.00000000
#>  0.0000000     0.0 0.0000000      0.7500000   0.00000000      1.0000 0.00000000
#>  0.0000000     0.0 0.0000000      0.5000000   0.00000000      1.0000 0.00000000
#>  0.0000000     0.0 0.0000000      0.5000000   0.00000000      1.0000 0.00000000
#>  0.0000000     4.0 0.0000000      0.6666667   0.00000000      0.7500 0.00000000
#>  0.7071068     4.0 0.0000000      0.6833333   0.02357023      0.8125 0.08838835
#>  0.0000000     0.0 0.0000000      0.7500000   0.00000000      1.0000 0.00000000
#>  0.0000000     0.0 0.0000000      0.7500000   0.00000000      1.0000 0.00000000
#>  specificity_mean specificity_sd   f1_mean      f1_sd jaccard_mean jaccard_sd
#>         0.0000000      0.0000000 0.6666667 0.00000000    0.5000000 0.00000000
#>         0.0000000      0.0000000 0.6666667 0.00000000    0.5000000 0.00000000
#>         0.5000000      0.1010153 0.7894737 0.07443229    0.6553030 0.10178052
#>         0.7142857      0.2020305 0.8585526 0.02326009    0.7525253 0.03571246
#>         0.0000000      0.0000000 0.8571429 0.00000000    0.7500000 0.00000000
#>         0.0000000      0.0000000 0.8571429 0.00000000    0.7500000 0.00000000
#>         0.0000000      0.0000000 0.6666667 0.00000000    0.5000000 0.00000000
#>         0.0000000      0.0000000 0.6666667 0.00000000    0.5000000 0.00000000
#>         0.5714286      0.0000000 0.7058824 0.00000000    0.5454545 0.00000000
#>         0.5714286      0.0000000 0.7418301 0.05083774    0.5909091 0.06428243
#>         0.0000000      0.0000000 0.8571429 0.00000000    0.7500000 0.00000000
#>         0.0000000      0.0000000 0.8571429 0.00000000    0.7500000 0.00000000
#>  selection_rate_mean selection_rate_sd
#>            1.0000000        0.00000000
#>            1.0000000        0.00000000
#>            0.7333333        0.00000000
#>            0.6333333        0.14142136
#>            1.0000000        0.00000000
#>            1.0000000        0.00000000
#>            1.0000000        0.00000000
#>            1.0000000        0.00000000
#>            0.6000000        0.00000000
#>            0.6333333        0.04714045
#>            1.0000000        0.00000000
#>            1.0000000        0.00000000
```

The repeated-study summary reports the mean and standard deviation of
recovery metrics by method, evaluation level, and `c0` when applicable.
