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
#>   noise axis: noise_sd 
#>   noise sd: 0.4 
#>   effective signal-to-noise SD ratio: 2.418105 
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

The simulator covers seven primary signal structures:

- `localized_dense`: dense local active regions.
- `confounded_blocks`: active regions near correlated nuisance blocks.
- `smooth_sparse`: smooth coefficient structure on sparse active
  domains.
- `basis_block_signal`: signal aligned with spline-like basis blocks.
- `fpca_low_rank_signal`: response driven by the first FPCA components.
- `null_signal`: no active functional or scalar truth, useful for
  false-positive summaries.
- `mislocalized_signal`: fragmented active regions that are
  intentionally hard for locality rules.

The older `distributed_smooth` label remains available for backwards
compatibility. In the null scenario, recovery tables should be read
through `fp`, `n_selected`, specificity, and selection rate rather than
`F1`, because there is no positive support to recover.

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
#> 3  feature         62      13         23  8 15  5 34 0.3478261 0.6153846
#> 4  feature         62      13         28 12 16  1 33 0.4285714 0.9230769
#> 5  feature         62      13         25  9 16  4 33 0.3600000 0.6923077
#> 6  feature         62      13         24 11 13  2 36 0.4583333 0.8461538
#> 7    group          4       3          4  3  1  0  0 0.7500000 1.0000000
#> 8    group         14       6          5  4  1  2  7 0.8000000 0.6666667
#> 9    group          4       3          4  3  1  0  0 0.7500000 1.0000000
#> 10   group          4       3          4  3  1  0  0 0.7500000 1.0000000
#> 11   group          4       3          4  3  1  0  0 0.7500000 1.0000000
#> 12   group          4       3          4  3  1  0  0 0.7500000 1.0000000
#>    specificity        f1   jaccard selection_rate            method       c0
#> 1    0.9183673 0.4545455 0.2941176      0.1451613         stability     <NA>
#> 2    0.9387755 0.6086957 0.4375000      0.1612903          interval     <NA>
#> 3    0.6938776 0.4444444 0.2857143      0.3709677       selectboost c0 = 0.7
#> 4    0.6734694 0.5853659 0.4137931      0.4516129       selectboost c0 = 0.4
#> 5    0.6734694 0.4736842 0.3103448      0.4032258 plain_selectboost c0 = 0.7
#> 6    0.7346939 0.5945946 0.4230769      0.3870968 plain_selectboost c0 = 0.4
#> 7    0.0000000 0.8571429 0.7500000      1.0000000         stability     <NA>
#> 8    0.8750000 0.7272727 0.5714286      0.3571429          interval     <NA>
#> 9    0.0000000 0.8571429 0.7500000      1.0000000       selectboost c0 = 0.7
#> 10   0.0000000 0.8571429 0.7500000      1.0000000       selectboost c0 = 0.4
#> 11   0.0000000 0.8571429 0.7500000      1.0000000 plain_selectboost c0 = 0.7
#> 12   0.0000000 0.8571429 0.7500000      1.0000000 plain_selectboost c0 = 0.4
#>           scenario representation   family noise_axis snr noise_sd
#> 1  localized_dense           grid gaussian   noise_sd  NA      0.4
#> 2  localized_dense           grid gaussian   noise_sd  NA      0.4
#> 3  localized_dense           grid gaussian   noise_sd  NA      0.4
#> 4  localized_dense           grid gaussian   noise_sd  NA      0.4
#> 5  localized_dense           grid gaussian   noise_sd  NA      0.4
#> 6  localized_dense           grid gaussian   noise_sd  NA      0.4
#> 7  localized_dense           grid gaussian   noise_sd  NA      0.4
#> 8  localized_dense           grid gaussian   noise_sd  NA      0.4
#> 9  localized_dense           grid gaussian   noise_sd  NA      0.4
#> 10 localized_dense           grid gaussian   noise_sd  NA      0.4
#> 11 localized_dense           grid gaussian   noise_sd  NA      0.4
#> 12 localized_dense           grid gaussian   noise_sd  NA      0.4
#>    effective_noise_sd effective_snr effective_variance_snr
#> 1                 0.4      2.418105                5.84723
#> 2                 0.4      2.418105                5.84723
#> 3                 0.4      2.418105                5.84723
#> 4                 0.4      2.418105                5.84723
#> 5                 0.4      2.418105                5.84723
#> 6                 0.4      2.418105                5.84723
#> 7                 0.4      2.418105                5.84723
#> 8                 0.4      2.418105                5.84723
#> 9                 0.4      2.418105                5.84723
#> 10                0.4      2.418105                5.84723
#> 11                0.4      2.418105                5.84723
#> 12                0.4      2.418105                5.84723
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
#>                                                                                  scenario
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.interval.feature          localized_dense
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.plain_selectboost.feature localized_dense
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.selectboost.feature       localized_dense
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.stability.feature         localized_dense
#>                                                                           representation
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.interval.feature                    grid
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.plain_selectboost.feature           grid
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.selectboost.feature                 grid
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.stability.feature                   grid
#>                                                                             family
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.interval.feature          gaussian
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.plain_selectboost.feature gaussian
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.selectboost.feature       gaussian
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.stability.feature         gaussian
#>                                                                           noise_axis
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.interval.feature            noise_sd
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.plain_selectboost.feature   noise_sd
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.selectboost.feature         noise_sd
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.stability.feature           noise_sd
#>                                                                           snr
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.interval.feature           NA
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.plain_selectboost.feature  NA
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.selectboost.feature        NA
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.stability.feature          NA
#>                                                                           noise_sd
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.interval.feature               0.4
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.plain_selectboost.feature      0.4
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.selectboost.feature            0.4
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.stability.feature              0.4
#>                                                                                      method
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.interval.feature                   interval
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.plain_selectboost.feature plain_selectboost
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.selectboost.feature             selectboost
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.stability.feature                 stability
#>                                                                             level
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.interval.feature          feature
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.plain_selectboost.feature feature
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.selectboost.feature       feature
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.stability.feature         feature
#>                                                                           n_rep
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.interval.feature              1
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.plain_selectboost.feature     1
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.selectboost.feature           1
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.stability.feature             1
#>                                                                           n_truth_mean
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.interval.feature                    13
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.plain_selectboost.feature           13
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.selectboost.feature                 13
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.stability.feature                   13
#>                                                                           n_truth_sd
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.interval.feature                   0
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.plain_selectboost.feature          0
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.selectboost.feature                0
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.stability.feature                  0
#>                                                                           n_selected_mean
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.interval.feature                       10
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.plain_selectboost.feature              24
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.selectboost.feature                    28
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.stability.feature                       9
#>                                                                           n_selected_sd
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.interval.feature                      0
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.plain_selectboost.feature             0
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.selectboost.feature                   0
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.stability.feature                     0
#>                                                                           tp_mean
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.interval.feature                7
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.plain_selectboost.feature      11
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.selectboost.feature            12
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.stability.feature               5
#>                                                                           tp_sd
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.interval.feature              0
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.plain_selectboost.feature     0
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.selectboost.feature           0
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.stability.feature             0
#>                                                                           fp_mean
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.interval.feature                3
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.plain_selectboost.feature      13
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.selectboost.feature            16
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.stability.feature               4
#>                                                                           fp_sd
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.interval.feature              0
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.plain_selectboost.feature     0
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.selectboost.feature           0
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.stability.feature             0
#>                                                                           fn_mean
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.interval.feature                6
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.plain_selectboost.feature       2
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.selectboost.feature             1
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.stability.feature               8
#>                                                                           fn_sd
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.interval.feature              0
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.plain_selectboost.feature     0
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.selectboost.feature           0
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.stability.feature             0
#>                                                                           tn_mean
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.interval.feature               46
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.plain_selectboost.feature      36
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.selectboost.feature            33
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.stability.feature              45
#>                                                                           tn_sd
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.interval.feature              0
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.plain_selectboost.feature     0
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.selectboost.feature           0
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.stability.feature             0
#>                                                                           precision_mean
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.interval.feature               0.7000000
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.plain_selectboost.feature      0.4583333
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.selectboost.feature            0.4285714
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.stability.feature              0.5555556
#>                                                                           precision_sd
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.interval.feature                     0
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.plain_selectboost.feature            0
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.selectboost.feature                  0
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.stability.feature                    0
#>                                                                           recall_mean
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.interval.feature            0.5384615
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.plain_selectboost.feature   0.8461538
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.selectboost.feature         0.9230769
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.stability.feature           0.3846154
#>                                                                           recall_sd
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.interval.feature                  0
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.plain_selectboost.feature         0
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.selectboost.feature               0
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.stability.feature                 0
#>                                                                           specificity_mean
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.interval.feature                 0.9387755
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.plain_selectboost.feature        0.7346939
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.selectboost.feature              0.6734694
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.stability.feature                0.9183673
#>                                                                           specificity_sd
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.interval.feature                       0
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.plain_selectboost.feature              0
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.selectboost.feature                    0
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.stability.feature                      0
#>                                                                             f1_mean
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.interval.feature          0.6086957
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.plain_selectboost.feature 0.5945946
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.selectboost.feature       0.5853659
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.stability.feature         0.4545455
#>                                                                           f1_sd
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.interval.feature              0
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.plain_selectboost.feature     0
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.selectboost.feature           0
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.stability.feature             0
#>                                                                           jaccard_mean
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.interval.feature             0.4375000
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.plain_selectboost.feature    0.4230769
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.selectboost.feature          0.4137931
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.stability.feature            0.2941176
#>                                                                           jaccard_sd
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.interval.feature                   0
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.plain_selectboost.feature          0
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.selectboost.feature                0
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.stability.feature                  0
#>                                                                           selection_rate_mean
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.interval.feature                    0.1612903
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.plain_selectboost.feature           0.3870968
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.selectboost.feature                 0.4516129
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.stability.feature                   0.1451613
#>                                                                           selection_rate_sd
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.interval.feature                          0
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.plain_selectboost.feature                 0
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.selectboost.feature                       0
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.stability.feature                         0
#>                                                                           effective_snr_mean
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.interval.feature                    2.418105
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.plain_selectboost.feature           2.418105
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.selectboost.feature                 2.418105
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.stability.feature                   2.418105
#>                                                                           effective_snr_sd
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.interval.feature                         0
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.plain_selectboost.feature                0
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.selectboost.feature                      0
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.stability.feature                        0
#>                                                                           effective_variance_snr_mean
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.interval.feature                              5.84723
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.plain_selectboost.feature                     5.84723
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.selectboost.feature                           5.84723
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.stability.feature                             5.84723
#>                                                                           effective_variance_snr_sd
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.interval.feature                                  0
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.plain_selectboost.feature                         0
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.selectboost.feature                               0
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.stability.feature                                 0
summarise_benchmark_advantage(
  bench,
  target = "selectboost",
  reference = c("plain_selectboost", "stability"),
  level = "feature",
  metric = "f1"
)
#>                                                                                                 scenario
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.feature.selectboost.plain_selectboost.f1 localized_dense
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.feature.selectboost.stability.f1         localized_dense
#>                                                                                          representation
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.feature.selectboost.plain_selectboost.f1           grid
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.feature.selectboost.stability.f1                   grid
#>                                                                                            family
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.feature.selectboost.plain_selectboost.f1 gaussian
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.feature.selectboost.stability.f1         gaussian
#>                                                                                          noise_axis
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.feature.selectboost.plain_selectboost.f1   noise_sd
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.feature.selectboost.stability.f1           noise_sd
#>                                                                                          snr
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.feature.selectboost.plain_selectboost.f1  NA
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.feature.selectboost.stability.f1          NA
#>                                                                                          noise_sd
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.feature.selectboost.plain_selectboost.f1      0.4
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.feature.selectboost.stability.f1              0.4
#>                                                                                            level
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.feature.selectboost.plain_selectboost.f1 feature
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.feature.selectboost.stability.f1         feature
#>                                                                                               target
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.feature.selectboost.plain_selectboost.f1 selectboost
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.feature.selectboost.stability.f1         selectboost
#>                                                                                                  reference
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.feature.selectboost.plain_selectboost.f1 plain_selectboost
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.feature.selectboost.stability.f1                 stability
#>                                                                                          metric
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.feature.selectboost.plain_selectboost.f1     f1
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.feature.selectboost.stability.f1             f1
#>                                                                                          n_rep
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.feature.selectboost.plain_selectboost.f1     1
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.feature.selectboost.stability.f1             1
#>                                                                                          target_value_mean
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.feature.selectboost.plain_selectboost.f1         0.5853659
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.feature.selectboost.stability.f1                 0.5853659
#>                                                                                          reference_value_mean
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.feature.selectboost.plain_selectboost.f1            0.5945946
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.feature.selectboost.stability.f1                    0.4545455
#>                                                                                            delta_mean
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.feature.selectboost.plain_selectboost.f1 -0.009228741
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.feature.selectboost.stability.f1          0.130820399
#>                                                                                          delta_sd
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.feature.selectboost.plain_selectboost.f1        0
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.feature.selectboost.stability.f1                0
#>                                                                                          win_rate
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.feature.selectboost.plain_selectboost.f1        0
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.feature.selectboost.stability.f1                1
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
    representation = "bspline"
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
    scenario = "smooth_sparse",
    representation = "bspline"
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
#>                                                                                                    scenario
#> localized_dense.bspline.gaussian.noise_sd.<NA>.0.4.feature.selectboost.plain_selectboost.f1 localized_dense
#> localized_dense.bspline.gaussian.noise_sd.<NA>.0.4.feature.selectboost.stability.f1         localized_dense
#>                                                                                             representation
#> localized_dense.bspline.gaussian.noise_sd.<NA>.0.4.feature.selectboost.plain_selectboost.f1        bspline
#> localized_dense.bspline.gaussian.noise_sd.<NA>.0.4.feature.selectboost.stability.f1                bspline
#>                                                                                               family
#> localized_dense.bspline.gaussian.noise_sd.<NA>.0.4.feature.selectboost.plain_selectboost.f1 gaussian
#> localized_dense.bspline.gaussian.noise_sd.<NA>.0.4.feature.selectboost.stability.f1         gaussian
#>                                                                                             noise_axis
#> localized_dense.bspline.gaussian.noise_sd.<NA>.0.4.feature.selectboost.plain_selectboost.f1   noise_sd
#> localized_dense.bspline.gaussian.noise_sd.<NA>.0.4.feature.selectboost.stability.f1           noise_sd
#>                                                                                             snr
#> localized_dense.bspline.gaussian.noise_sd.<NA>.0.4.feature.selectboost.plain_selectboost.f1  NA
#> localized_dense.bspline.gaussian.noise_sd.<NA>.0.4.feature.selectboost.stability.f1          NA
#>                                                                                             noise_sd
#> localized_dense.bspline.gaussian.noise_sd.<NA>.0.4.feature.selectboost.plain_selectboost.f1      0.4
#> localized_dense.bspline.gaussian.noise_sd.<NA>.0.4.feature.selectboost.stability.f1              0.4
#>                                                                                               level
#> localized_dense.bspline.gaussian.noise_sd.<NA>.0.4.feature.selectboost.plain_selectboost.f1 feature
#> localized_dense.bspline.gaussian.noise_sd.<NA>.0.4.feature.selectboost.stability.f1         feature
#>                                                                                                  target
#> localized_dense.bspline.gaussian.noise_sd.<NA>.0.4.feature.selectboost.plain_selectboost.f1 selectboost
#> localized_dense.bspline.gaussian.noise_sd.<NA>.0.4.feature.selectboost.stability.f1         selectboost
#>                                                                                                     reference
#> localized_dense.bspline.gaussian.noise_sd.<NA>.0.4.feature.selectboost.plain_selectboost.f1 plain_selectboost
#> localized_dense.bspline.gaussian.noise_sd.<NA>.0.4.feature.selectboost.stability.f1                 stability
#>                                                                                             metric
#> localized_dense.bspline.gaussian.noise_sd.<NA>.0.4.feature.selectboost.plain_selectboost.f1     f1
#> localized_dense.bspline.gaussian.noise_sd.<NA>.0.4.feature.selectboost.stability.f1             f1
#>                                                                                             n_rep
#> localized_dense.bspline.gaussian.noise_sd.<NA>.0.4.feature.selectboost.plain_selectboost.f1     2
#> localized_dense.bspline.gaussian.noise_sd.<NA>.0.4.feature.selectboost.stability.f1             2
#>                                                                                             target_value_mean
#> localized_dense.bspline.gaussian.noise_sd.<NA>.0.4.feature.selectboost.plain_selectboost.f1         0.7894737
#> localized_dense.bspline.gaussian.noise_sd.<NA>.0.4.feature.selectboost.stability.f1                 0.7894737
#>                                                                                             reference_value_mean
#> localized_dense.bspline.gaussian.noise_sd.<NA>.0.4.feature.selectboost.plain_selectboost.f1            0.6862745
#> localized_dense.bspline.gaussian.noise_sd.<NA>.0.4.feature.selectboost.stability.f1                    0.6923077
#>                                                                                             delta_mean
#> localized_dense.bspline.gaussian.noise_sd.<NA>.0.4.feature.selectboost.plain_selectboost.f1 0.10319917
#> localized_dense.bspline.gaussian.noise_sd.<NA>.0.4.feature.selectboost.stability.f1         0.09716599
#>                                                                                               delta_sd
#> localized_dense.bspline.gaussian.noise_sd.<NA>.0.4.feature.selectboost.plain_selectboost.f1 0.04670262
#> localized_dense.bspline.gaussian.noise_sd.<NA>.0.4.feature.selectboost.stability.f1         0.18321795
#>                                                                                             win_rate
#> localized_dense.bspline.gaussian.noise_sd.<NA>.0.4.feature.selectboost.plain_selectboost.f1      1.0
#> localized_dense.bspline.gaussian.noise_sd.<NA>.0.4.feature.selectboost.stability.f1              0.5

summarise_benchmark_advantage(
  study_smooth,
  target = "selectboost",
  reference = c("plain_selectboost", "stability"),
  level = "feature",
  metric = "f1"
)
#>                                                                                                scenario
#> smooth_sparse.bspline.gaussian.noise_sd.<NA>.0.4.feature.selectboost.plain_selectboost.f1 smooth_sparse
#> smooth_sparse.bspline.gaussian.noise_sd.<NA>.0.4.feature.selectboost.stability.f1         smooth_sparse
#>                                                                                           representation
#> smooth_sparse.bspline.gaussian.noise_sd.<NA>.0.4.feature.selectboost.plain_selectboost.f1        bspline
#> smooth_sparse.bspline.gaussian.noise_sd.<NA>.0.4.feature.selectboost.stability.f1                bspline
#>                                                                                             family
#> smooth_sparse.bspline.gaussian.noise_sd.<NA>.0.4.feature.selectboost.plain_selectboost.f1 gaussian
#> smooth_sparse.bspline.gaussian.noise_sd.<NA>.0.4.feature.selectboost.stability.f1         gaussian
#>                                                                                           noise_axis
#> smooth_sparse.bspline.gaussian.noise_sd.<NA>.0.4.feature.selectboost.plain_selectboost.f1   noise_sd
#> smooth_sparse.bspline.gaussian.noise_sd.<NA>.0.4.feature.selectboost.stability.f1           noise_sd
#>                                                                                           snr
#> smooth_sparse.bspline.gaussian.noise_sd.<NA>.0.4.feature.selectboost.plain_selectboost.f1  NA
#> smooth_sparse.bspline.gaussian.noise_sd.<NA>.0.4.feature.selectboost.stability.f1          NA
#>                                                                                           noise_sd
#> smooth_sparse.bspline.gaussian.noise_sd.<NA>.0.4.feature.selectboost.plain_selectboost.f1      0.4
#> smooth_sparse.bspline.gaussian.noise_sd.<NA>.0.4.feature.selectboost.stability.f1              0.4
#>                                                                                             level
#> smooth_sparse.bspline.gaussian.noise_sd.<NA>.0.4.feature.selectboost.plain_selectboost.f1 feature
#> smooth_sparse.bspline.gaussian.noise_sd.<NA>.0.4.feature.selectboost.stability.f1         feature
#>                                                                                                target
#> smooth_sparse.bspline.gaussian.noise_sd.<NA>.0.4.feature.selectboost.plain_selectboost.f1 selectboost
#> smooth_sparse.bspline.gaussian.noise_sd.<NA>.0.4.feature.selectboost.stability.f1         selectboost
#>                                                                                                   reference
#> smooth_sparse.bspline.gaussian.noise_sd.<NA>.0.4.feature.selectboost.plain_selectboost.f1 plain_selectboost
#> smooth_sparse.bspline.gaussian.noise_sd.<NA>.0.4.feature.selectboost.stability.f1                 stability
#>                                                                                           metric
#> smooth_sparse.bspline.gaussian.noise_sd.<NA>.0.4.feature.selectboost.plain_selectboost.f1     f1
#> smooth_sparse.bspline.gaussian.noise_sd.<NA>.0.4.feature.selectboost.stability.f1             f1
#>                                                                                           n_rep
#> smooth_sparse.bspline.gaussian.noise_sd.<NA>.0.4.feature.selectboost.plain_selectboost.f1     2
#> smooth_sparse.bspline.gaussian.noise_sd.<NA>.0.4.feature.selectboost.stability.f1             2
#>                                                                                           target_value_mean
#> smooth_sparse.bspline.gaussian.noise_sd.<NA>.0.4.feature.selectboost.plain_selectboost.f1         0.8136364
#> smooth_sparse.bspline.gaussian.noise_sd.<NA>.0.4.feature.selectboost.stability.f1                 0.8136364
#>                                                                                           reference_value_mean
#> smooth_sparse.bspline.gaussian.noise_sd.<NA>.0.4.feature.selectboost.plain_selectboost.f1            0.8099415
#> smooth_sparse.bspline.gaussian.noise_sd.<NA>.0.4.feature.selectboost.stability.f1                    0.7708333
#>                                                                                            delta_mean
#> smooth_sparse.bspline.gaussian.noise_sd.<NA>.0.4.feature.selectboost.plain_selectboost.f1 0.003694843
#> smooth_sparse.bspline.gaussian.noise_sd.<NA>.0.4.feature.selectboost.stability.f1         0.042803030
#>                                                                                             delta_sd
#> smooth_sparse.bspline.gaussian.noise_sd.<NA>.0.4.feature.selectboost.plain_selectboost.f1 0.07665022
#> smooth_sparse.bspline.gaussian.noise_sd.<NA>.0.4.feature.selectboost.stability.f1         0.02517729
#>                                                                                           win_rate
#> smooth_sparse.bspline.gaussian.noise_sd.<NA>.0.4.feature.selectboost.plain_selectboost.f1      0.5
#> smooth_sparse.bspline.gaussian.noise_sd.<NA>.0.4.feature.selectboost.stability.f1              1.0
```

The repeated-study summary reports the mean and standard deviation of
recovery metrics by method, evaluation level, scenario, and `c0` when
applicable. In practice, `localized_dense`, `smooth_sparse`, and
`confounded_blocks` are the main positive-signal stress tests, while
`null_signal` and `mislocalized_signal` are useful for describing false
positives and failure modes.

## Run a targeted sensitivity study for FDA-aware SelectBoost

``` r

sensitivity <- run_selectboost_sensitivity_study(
  n_rep = 1,
  simulate_grid = data.frame(
    scenario = c("localized_dense", "confounded_blocks", "smooth_sparse", "null_signal"),
    confounding_strength = c(0.4, 0.9, 0.4, 0.0),
    active_region_scale = c(0.8, 0.7, 0.6, 1.0),
    local_correlation = c(1, 2, 2, 2),
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
#>                                                                                                                                scenario
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.9.0.7.2.feature.selectboost.plain_selectboost.f1 confounded_blocks
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1         confounded_blocks
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.interval.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1       confounded_blocks
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.4.0.8.1.feature.selectboost.plain_selectboost.f1     localized_dense
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.4.0.8.1.feature.selectboost.plain_selectboost.f1             localized_dense
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.interval.4.0.4.0.8.1.feature.selectboost.plain_selectboost.f1           localized_dense
#> null_signal.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.1.2.feature.selectboost.plain_selectboost.f1                 null_signal
#> null_signal.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.1.2.feature.selectboost.plain_selectboost.f1                         null_signal
#> null_signal.grid.gaussian.noise_sd.<NA>.0.4.interval.4.0.1.2.feature.selectboost.plain_selectboost.f1                       null_signal
#> smooth_sparse.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.4.0.6.2.feature.selectboost.plain_selectboost.f1         smooth_sparse
#> smooth_sparse.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.4.0.6.2.feature.selectboost.plain_selectboost.f1                 smooth_sparse
#> smooth_sparse.grid.gaussian.noise_sd.<NA>.0.4.interval.4.0.4.0.6.2.feature.selectboost.plain_selectboost.f1               smooth_sparse
#>                                                                                                                       representation
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.9.0.7.2.feature.selectboost.plain_selectboost.f1           grid
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1                   grid
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.interval.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1                 grid
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.4.0.8.1.feature.selectboost.plain_selectboost.f1             grid
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.4.0.8.1.feature.selectboost.plain_selectboost.f1                     grid
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.interval.4.0.4.0.8.1.feature.selectboost.plain_selectboost.f1                   grid
#> null_signal.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.1.2.feature.selectboost.plain_selectboost.f1                     grid
#> null_signal.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.1.2.feature.selectboost.plain_selectboost.f1                             grid
#> null_signal.grid.gaussian.noise_sd.<NA>.0.4.interval.4.0.1.2.feature.selectboost.plain_selectboost.f1                           grid
#> smooth_sparse.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.4.0.6.2.feature.selectboost.plain_selectboost.f1               grid
#> smooth_sparse.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.4.0.6.2.feature.selectboost.plain_selectboost.f1                       grid
#> smooth_sparse.grid.gaussian.noise_sd.<NA>.0.4.interval.4.0.4.0.6.2.feature.selectboost.plain_selectboost.f1                     grid
#>                                                                                                                         family
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.9.0.7.2.feature.selectboost.plain_selectboost.f1 gaussian
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1         gaussian
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.interval.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1       gaussian
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.4.0.8.1.feature.selectboost.plain_selectboost.f1   gaussian
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.4.0.8.1.feature.selectboost.plain_selectboost.f1           gaussian
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.interval.4.0.4.0.8.1.feature.selectboost.plain_selectboost.f1         gaussian
#> null_signal.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.1.2.feature.selectboost.plain_selectboost.f1           gaussian
#> null_signal.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.1.2.feature.selectboost.plain_selectboost.f1                   gaussian
#> null_signal.grid.gaussian.noise_sd.<NA>.0.4.interval.4.0.1.2.feature.selectboost.plain_selectboost.f1                 gaussian
#> smooth_sparse.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.4.0.6.2.feature.selectboost.plain_selectboost.f1     gaussian
#> smooth_sparse.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.4.0.6.2.feature.selectboost.plain_selectboost.f1             gaussian
#> smooth_sparse.grid.gaussian.noise_sd.<NA>.0.4.interval.4.0.4.0.6.2.feature.selectboost.plain_selectboost.f1           gaussian
#>                                                                                                                       noise_axis
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.9.0.7.2.feature.selectboost.plain_selectboost.f1   noise_sd
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1           noise_sd
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.interval.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1         noise_sd
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.4.0.8.1.feature.selectboost.plain_selectboost.f1     noise_sd
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.4.0.8.1.feature.selectboost.plain_selectboost.f1             noise_sd
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.interval.4.0.4.0.8.1.feature.selectboost.plain_selectboost.f1           noise_sd
#> null_signal.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.1.2.feature.selectboost.plain_selectboost.f1             noise_sd
#> null_signal.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.1.2.feature.selectboost.plain_selectboost.f1                     noise_sd
#> null_signal.grid.gaussian.noise_sd.<NA>.0.4.interval.4.0.1.2.feature.selectboost.plain_selectboost.f1                   noise_sd
#> smooth_sparse.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.4.0.6.2.feature.selectboost.plain_selectboost.f1       noise_sd
#> smooth_sparse.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.4.0.6.2.feature.selectboost.plain_selectboost.f1               noise_sd
#> smooth_sparse.grid.gaussian.noise_sd.<NA>.0.4.interval.4.0.4.0.6.2.feature.selectboost.plain_selectboost.f1             noise_sd
#>                                                                                                                       snr
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.9.0.7.2.feature.selectboost.plain_selectboost.f1  NA
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1          NA
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.interval.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1        NA
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.4.0.8.1.feature.selectboost.plain_selectboost.f1    NA
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.4.0.8.1.feature.selectboost.plain_selectboost.f1            NA
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.interval.4.0.4.0.8.1.feature.selectboost.plain_selectboost.f1          NA
#> null_signal.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.1.2.feature.selectboost.plain_selectboost.f1            NA
#> null_signal.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.1.2.feature.selectboost.plain_selectboost.f1                    NA
#> null_signal.grid.gaussian.noise_sd.<NA>.0.4.interval.4.0.1.2.feature.selectboost.plain_selectboost.f1                  NA
#> smooth_sparse.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.4.0.6.2.feature.selectboost.plain_selectboost.f1      NA
#> smooth_sparse.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.4.0.6.2.feature.selectboost.plain_selectboost.f1              NA
#> smooth_sparse.grid.gaussian.noise_sd.<NA>.0.4.interval.4.0.4.0.6.2.feature.selectboost.plain_selectboost.f1            NA
#>                                                                                                                       noise_sd
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.9.0.7.2.feature.selectboost.plain_selectboost.f1      0.4
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1              0.4
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.interval.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1            0.4
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.4.0.8.1.feature.selectboost.plain_selectboost.f1        0.4
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.4.0.8.1.feature.selectboost.plain_selectboost.f1                0.4
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.interval.4.0.4.0.8.1.feature.selectboost.plain_selectboost.f1              0.4
#> null_signal.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.1.2.feature.selectboost.plain_selectboost.f1                0.4
#> null_signal.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.1.2.feature.selectboost.plain_selectboost.f1                        0.4
#> null_signal.grid.gaussian.noise_sd.<NA>.0.4.interval.4.0.1.2.feature.selectboost.plain_selectboost.f1                      0.4
#> smooth_sparse.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.4.0.6.2.feature.selectboost.plain_selectboost.f1          0.4
#> smooth_sparse.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.4.0.6.2.feature.selectboost.plain_selectboost.f1                  0.4
#> smooth_sparse.grid.gaussian.noise_sd.<NA>.0.4.interval.4.0.4.0.6.2.feature.selectboost.plain_selectboost.f1                0.4
#>                                                                                                                       association_method
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.9.0.7.2.feature.selectboost.plain_selectboost.f1        correlation
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1                     hybrid
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.interval.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1                 interval
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.4.0.8.1.feature.selectboost.plain_selectboost.f1          correlation
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.4.0.8.1.feature.selectboost.plain_selectboost.f1                       hybrid
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.interval.4.0.4.0.8.1.feature.selectboost.plain_selectboost.f1                   interval
#> null_signal.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.1.2.feature.selectboost.plain_selectboost.f1                  correlation
#> null_signal.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.1.2.feature.selectboost.plain_selectboost.f1                               hybrid
#> null_signal.grid.gaussian.noise_sd.<NA>.0.4.interval.4.0.1.2.feature.selectboost.plain_selectboost.f1                           interval
#> smooth_sparse.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.4.0.6.2.feature.selectboost.plain_selectboost.f1            correlation
#> smooth_sparse.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.4.0.6.2.feature.selectboost.plain_selectboost.f1                         hybrid
#> smooth_sparse.grid.gaussian.noise_sd.<NA>.0.4.interval.4.0.4.0.6.2.feature.selectboost.plain_selectboost.f1                     interval
#>                                                                                                                       bandwidth
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.9.0.7.2.feature.selectboost.plain_selectboost.f1        NA
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1                 4
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.interval.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1               4
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.4.0.8.1.feature.selectboost.plain_selectboost.f1          NA
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.4.0.8.1.feature.selectboost.plain_selectboost.f1                   4
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.interval.4.0.4.0.8.1.feature.selectboost.plain_selectboost.f1                 4
#> null_signal.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.1.2.feature.selectboost.plain_selectboost.f1                  NA
#> null_signal.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.1.2.feature.selectboost.plain_selectboost.f1                           4
#> null_signal.grid.gaussian.noise_sd.<NA>.0.4.interval.4.0.1.2.feature.selectboost.plain_selectboost.f1                         4
#> smooth_sparse.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.4.0.6.2.feature.selectboost.plain_selectboost.f1            NA
#> smooth_sparse.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.4.0.6.2.feature.selectboost.plain_selectboost.f1                     4
#> smooth_sparse.grid.gaussian.noise_sd.<NA>.0.4.interval.4.0.4.0.6.2.feature.selectboost.plain_selectboost.f1                   4
#>                                                                                                                       confounding_strength
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.9.0.7.2.feature.selectboost.plain_selectboost.f1                  0.9
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1                          0.9
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.interval.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1                        0.9
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.4.0.8.1.feature.selectboost.plain_selectboost.f1                    0.4
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.4.0.8.1.feature.selectboost.plain_selectboost.f1                            0.4
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.interval.4.0.4.0.8.1.feature.selectboost.plain_selectboost.f1                          0.4
#> null_signal.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.1.2.feature.selectboost.plain_selectboost.f1                            0.0
#> null_signal.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.1.2.feature.selectboost.plain_selectboost.f1                                    0.0
#> null_signal.grid.gaussian.noise_sd.<NA>.0.4.interval.4.0.1.2.feature.selectboost.plain_selectboost.f1                                  0.0
#> smooth_sparse.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.4.0.6.2.feature.selectboost.plain_selectboost.f1                      0.4
#> smooth_sparse.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.4.0.6.2.feature.selectboost.plain_selectboost.f1                              0.4
#> smooth_sparse.grid.gaussian.noise_sd.<NA>.0.4.interval.4.0.4.0.6.2.feature.selectboost.plain_selectboost.f1                            0.4
#>                                                                                                                       active_region_scale
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.9.0.7.2.feature.selectboost.plain_selectboost.f1                 0.7
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1                         0.7
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.interval.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1                       0.7
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.4.0.8.1.feature.selectboost.plain_selectboost.f1                   0.8
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.4.0.8.1.feature.selectboost.plain_selectboost.f1                           0.8
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.interval.4.0.4.0.8.1.feature.selectboost.plain_selectboost.f1                         0.8
#> null_signal.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.1.2.feature.selectboost.plain_selectboost.f1                           1.0
#> null_signal.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.1.2.feature.selectboost.plain_selectboost.f1                                   1.0
#> null_signal.grid.gaussian.noise_sd.<NA>.0.4.interval.4.0.1.2.feature.selectboost.plain_selectboost.f1                                 1.0
#> smooth_sparse.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.4.0.6.2.feature.selectboost.plain_selectboost.f1                     0.6
#> smooth_sparse.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.4.0.6.2.feature.selectboost.plain_selectboost.f1                             0.6
#> smooth_sparse.grid.gaussian.noise_sd.<NA>.0.4.interval.4.0.4.0.6.2.feature.selectboost.plain_selectboost.f1                           0.6
#>                                                                                                                       local_correlation
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.9.0.7.2.feature.selectboost.plain_selectboost.f1                 2
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1                         2
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.interval.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1                       2
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.4.0.8.1.feature.selectboost.plain_selectboost.f1                   1
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.4.0.8.1.feature.selectboost.plain_selectboost.f1                           1
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.interval.4.0.4.0.8.1.feature.selectboost.plain_selectboost.f1                         1
#> null_signal.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.1.2.feature.selectboost.plain_selectboost.f1                           2
#> null_signal.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.1.2.feature.selectboost.plain_selectboost.f1                                   2
#> null_signal.grid.gaussian.noise_sd.<NA>.0.4.interval.4.0.1.2.feature.selectboost.plain_selectboost.f1                                 2
#> smooth_sparse.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.4.0.6.2.feature.selectboost.plain_selectboost.f1                     2
#> smooth_sparse.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.4.0.6.2.feature.selectboost.plain_selectboost.f1                             2
#> smooth_sparse.grid.gaussian.noise_sd.<NA>.0.4.interval.4.0.4.0.6.2.feature.selectboost.plain_selectboost.f1                           2
#>                                                                                                                         level
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.9.0.7.2.feature.selectboost.plain_selectboost.f1 feature
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1         feature
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.interval.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1       feature
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.4.0.8.1.feature.selectboost.plain_selectboost.f1   feature
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.4.0.8.1.feature.selectboost.plain_selectboost.f1           feature
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.interval.4.0.4.0.8.1.feature.selectboost.plain_selectboost.f1         feature
#> null_signal.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.1.2.feature.selectboost.plain_selectboost.f1           feature
#> null_signal.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.1.2.feature.selectboost.plain_selectboost.f1                   feature
#> null_signal.grid.gaussian.noise_sd.<NA>.0.4.interval.4.0.1.2.feature.selectboost.plain_selectboost.f1                 feature
#> smooth_sparse.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.4.0.6.2.feature.selectboost.plain_selectboost.f1     feature
#> smooth_sparse.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.4.0.6.2.feature.selectboost.plain_selectboost.f1             feature
#> smooth_sparse.grid.gaussian.noise_sd.<NA>.0.4.interval.4.0.4.0.6.2.feature.selectboost.plain_selectboost.f1           feature
#>                                                                                                                            target
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.9.0.7.2.feature.selectboost.plain_selectboost.f1 selectboost
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1         selectboost
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.interval.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1       selectboost
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.4.0.8.1.feature.selectboost.plain_selectboost.f1   selectboost
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.4.0.8.1.feature.selectboost.plain_selectboost.f1           selectboost
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.interval.4.0.4.0.8.1.feature.selectboost.plain_selectboost.f1         selectboost
#> null_signal.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.1.2.feature.selectboost.plain_selectboost.f1           selectboost
#> null_signal.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.1.2.feature.selectboost.plain_selectboost.f1                   selectboost
#> null_signal.grid.gaussian.noise_sd.<NA>.0.4.interval.4.0.1.2.feature.selectboost.plain_selectboost.f1                 selectboost
#> smooth_sparse.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.4.0.6.2.feature.selectboost.plain_selectboost.f1     selectboost
#> smooth_sparse.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.4.0.6.2.feature.selectboost.plain_selectboost.f1             selectboost
#> smooth_sparse.grid.gaussian.noise_sd.<NA>.0.4.interval.4.0.4.0.6.2.feature.selectboost.plain_selectboost.f1           selectboost
#>                                                                                                                               reference
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.9.0.7.2.feature.selectboost.plain_selectboost.f1 plain_selectboost
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1         plain_selectboost
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.interval.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1       plain_selectboost
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.4.0.8.1.feature.selectboost.plain_selectboost.f1   plain_selectboost
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.4.0.8.1.feature.selectboost.plain_selectboost.f1           plain_selectboost
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.interval.4.0.4.0.8.1.feature.selectboost.plain_selectboost.f1         plain_selectboost
#> null_signal.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.1.2.feature.selectboost.plain_selectboost.f1           plain_selectboost
#> null_signal.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.1.2.feature.selectboost.plain_selectboost.f1                   plain_selectboost
#> null_signal.grid.gaussian.noise_sd.<NA>.0.4.interval.4.0.1.2.feature.selectboost.plain_selectboost.f1                 plain_selectboost
#> smooth_sparse.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.4.0.6.2.feature.selectboost.plain_selectboost.f1     plain_selectboost
#> smooth_sparse.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.4.0.6.2.feature.selectboost.plain_selectboost.f1             plain_selectboost
#> smooth_sparse.grid.gaussian.noise_sd.<NA>.0.4.interval.4.0.4.0.6.2.feature.selectboost.plain_selectboost.f1           plain_selectboost
#>                                                                                                                       metric
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.9.0.7.2.feature.selectboost.plain_selectboost.f1     f1
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1             f1
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.interval.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1           f1
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.4.0.8.1.feature.selectboost.plain_selectboost.f1       f1
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.4.0.8.1.feature.selectboost.plain_selectboost.f1               f1
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.interval.4.0.4.0.8.1.feature.selectboost.plain_selectboost.f1             f1
#> null_signal.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.1.2.feature.selectboost.plain_selectboost.f1               f1
#> null_signal.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.1.2.feature.selectboost.plain_selectboost.f1                       f1
#> null_signal.grid.gaussian.noise_sd.<NA>.0.4.interval.4.0.1.2.feature.selectboost.plain_selectboost.f1                     f1
#> smooth_sparse.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.4.0.6.2.feature.selectboost.plain_selectboost.f1         f1
#> smooth_sparse.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.4.0.6.2.feature.selectboost.plain_selectboost.f1                 f1
#> smooth_sparse.grid.gaussian.noise_sd.<NA>.0.4.interval.4.0.4.0.6.2.feature.selectboost.plain_selectboost.f1               f1
#>                                                                                                                       n_rep
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.9.0.7.2.feature.selectboost.plain_selectboost.f1     1
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1             1
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.interval.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1           1
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.4.0.8.1.feature.selectboost.plain_selectboost.f1       1
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.4.0.8.1.feature.selectboost.plain_selectboost.f1               1
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.interval.4.0.4.0.8.1.feature.selectboost.plain_selectboost.f1             1
#> null_signal.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.1.2.feature.selectboost.plain_selectboost.f1               1
#> null_signal.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.1.2.feature.selectboost.plain_selectboost.f1                       1
#> null_signal.grid.gaussian.noise_sd.<NA>.0.4.interval.4.0.1.2.feature.selectboost.plain_selectboost.f1                     1
#> smooth_sparse.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.4.0.6.2.feature.selectboost.plain_selectboost.f1         1
#> smooth_sparse.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.4.0.6.2.feature.selectboost.plain_selectboost.f1                 1
#> smooth_sparse.grid.gaussian.noise_sd.<NA>.0.4.interval.4.0.4.0.6.2.feature.selectboost.plain_selectboost.f1               1
#>                                                                                                                       target_value_mean
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.9.0.7.2.feature.selectboost.plain_selectboost.f1         0.4705882
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1                 0.5000000
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.interval.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1               0.6000000
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.4.0.8.1.feature.selectboost.plain_selectboost.f1           0.5142857
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.4.0.8.1.feature.selectboost.plain_selectboost.f1                   0.5000000
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.interval.4.0.4.0.8.1.feature.selectboost.plain_selectboost.f1                 0.5161290
#> null_signal.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.1.2.feature.selectboost.plain_selectboost.f1                         NaN
#> null_signal.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.1.2.feature.selectboost.plain_selectboost.f1                                 NaN
#> null_signal.grid.gaussian.noise_sd.<NA>.0.4.interval.4.0.1.2.feature.selectboost.plain_selectboost.f1                               NaN
#> smooth_sparse.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.4.0.6.2.feature.selectboost.plain_selectboost.f1             0.5263158
#> smooth_sparse.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.4.0.6.2.feature.selectboost.plain_selectboost.f1                     0.2962963
#> smooth_sparse.grid.gaussian.noise_sd.<NA>.0.4.interval.4.0.4.0.6.2.feature.selectboost.plain_selectboost.f1                   0.4347826
#>                                                                                                                       reference_value_mean
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.9.0.7.2.feature.selectboost.plain_selectboost.f1            0.5142857
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1                    0.4864865
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.interval.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1                  0.5000000
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.4.0.8.1.feature.selectboost.plain_selectboost.f1              0.4516129
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.4.0.8.1.feature.selectboost.plain_selectboost.f1                      0.4242424
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.interval.4.0.4.0.8.1.feature.selectboost.plain_selectboost.f1                    0.4705882
#> null_signal.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.1.2.feature.selectboost.plain_selectboost.f1                            NaN
#> null_signal.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.1.2.feature.selectboost.plain_selectboost.f1                                    NaN
#> null_signal.grid.gaussian.noise_sd.<NA>.0.4.interval.4.0.1.2.feature.selectboost.plain_selectboost.f1                                  NaN
#> smooth_sparse.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.4.0.6.2.feature.selectboost.plain_selectboost.f1                0.5384615
#> smooth_sparse.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.4.0.6.2.feature.selectboost.plain_selectboost.f1                        0.4444444
#> smooth_sparse.grid.gaussian.noise_sd.<NA>.0.4.interval.4.0.4.0.6.2.feature.selectboost.plain_selectboost.f1                      0.4137931
#>                                                                                                                        delta_mean
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.9.0.7.2.feature.selectboost.plain_selectboost.f1 -0.04369748
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1          0.01351351
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.interval.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1        0.10000000
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.4.0.8.1.feature.selectboost.plain_selectboost.f1    0.06267281
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.4.0.8.1.feature.selectboost.plain_selectboost.f1            0.07575758
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.interval.4.0.4.0.8.1.feature.selectboost.plain_selectboost.f1          0.04554080
#> null_signal.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.1.2.feature.selectboost.plain_selectboost.f1                   NaN
#> null_signal.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.1.2.feature.selectboost.plain_selectboost.f1                           NaN
#> null_signal.grid.gaussian.noise_sd.<NA>.0.4.interval.4.0.1.2.feature.selectboost.plain_selectboost.f1                         NaN
#> smooth_sparse.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.4.0.6.2.feature.selectboost.plain_selectboost.f1     -0.01214575
#> smooth_sparse.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.4.0.6.2.feature.selectboost.plain_selectboost.f1             -0.14814815
#> smooth_sparse.grid.gaussian.noise_sd.<NA>.0.4.interval.4.0.4.0.6.2.feature.selectboost.plain_selectboost.f1            0.02098951
#>                                                                                                                       delta_sd
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.9.0.7.2.feature.selectboost.plain_selectboost.f1        0
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1                0
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.interval.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1              0
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.4.0.8.1.feature.selectboost.plain_selectboost.f1          0
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.4.0.8.1.feature.selectboost.plain_selectboost.f1                  0
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.interval.4.0.4.0.8.1.feature.selectboost.plain_selectboost.f1                0
#> null_signal.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.1.2.feature.selectboost.plain_selectboost.f1                  0
#> null_signal.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.1.2.feature.selectboost.plain_selectboost.f1                          0
#> null_signal.grid.gaussian.noise_sd.<NA>.0.4.interval.4.0.1.2.feature.selectboost.plain_selectboost.f1                        0
#> smooth_sparse.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.4.0.6.2.feature.selectboost.plain_selectboost.f1            0
#> smooth_sparse.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.4.0.6.2.feature.selectboost.plain_selectboost.f1                    0
#> smooth_sparse.grid.gaussian.noise_sd.<NA>.0.4.interval.4.0.4.0.6.2.feature.selectboost.plain_selectboost.f1                  0
#>                                                                                                                       win_rate
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.9.0.7.2.feature.selectboost.plain_selectboost.f1        0
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1                1
#> confounded_blocks.grid.gaussian.noise_sd.<NA>.0.4.interval.4.0.9.0.7.2.feature.selectboost.plain_selectboost.f1              1
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.4.0.8.1.feature.selectboost.plain_selectboost.f1          1
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.4.0.8.1.feature.selectboost.plain_selectboost.f1                  1
#> localized_dense.grid.gaussian.noise_sd.<NA>.0.4.interval.4.0.4.0.8.1.feature.selectboost.plain_selectboost.f1                1
#> null_signal.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.1.2.feature.selectboost.plain_selectboost.f1                NaN
#> null_signal.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.1.2.feature.selectboost.plain_selectboost.f1                        NaN
#> null_signal.grid.gaussian.noise_sd.<NA>.0.4.interval.4.0.1.2.feature.selectboost.plain_selectboost.f1                      NaN
#> smooth_sparse.grid.gaussian.noise_sd.<NA>.0.4.correlation.<NA>.0.4.0.6.2.feature.selectboost.plain_selectboost.f1            0
#> smooth_sparse.grid.gaussian.noise_sd.<NA>.0.4.hybrid.4.0.4.0.6.2.feature.selectboost.plain_selectboost.f1                    0
#> smooth_sparse.grid.gaussian.noise_sd.<NA>.0.4.interval.4.0.4.0.6.2.feature.selectboost.plain_selectboost.f1                  1
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
