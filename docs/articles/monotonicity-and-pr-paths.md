# Monotonicity and Precision-Recall Paths

The extraction helpers make path diagnostics independent of any plotting
backend. A selection surface can be checked directly for monotonicity
over `c0` or `q`.

``` r
library(SelectBoost.FDA)

surface <- data.frame(
  feature = c("a", "a", "b", "b"),
  predictor = "signal",
  level = "feature",
  c0 = c(0.2, 0.6, 0.2, 0.6),
  selection = c(0.8, 0.9, 0.4, 0.2),
  stringsAsFactors = FALSE
)

paths <- as_monotonicity_path_data(surface, axis = "c0", level = "feature")
diagnostic <- check_selection_monotonicity(
  surface,
  axis = "c0",
  direction = "nonincreasing",
  level = "feature"
)

paths
#>                           id   level axis axis_value value delta violation
#> a...NA...feature...NA...1  a feature   c0        0.2   0.8    NA     FALSE
#> a...NA...feature...NA...2  a feature   c0        0.6   0.9   0.1      TRUE
#> b...NA...feature...NA...3  b feature   c0        0.2   0.4    NA     FALSE
#> b...NA...feature...NA...4  b feature   c0        0.6   0.2  -0.2     FALSE
#>                           violation_size method  q  c0
#> a...NA...feature...NA...1            0.0   <NA> NA 0.2
#> a...NA...feature...NA...2            0.1   <NA> NA 0.6
#> b...NA...feature...NA...3            0.0   <NA> NA 0.2
#> b...NA...feature...NA...4            0.0   <NA> NA 0.6
diagnostic
#>                         id   level axis n_steps n_violations max_violation
#> a.feature...NA.....NA..  a feature   c0       2            1           0.1
#> b.feature...NA.....NA..  b feature   c0       2            0           0.0
#>                         total_violation is_monotone
#> a.feature...NA.....NA..             0.1       FALSE
#> b.feature...NA.....NA..             0.0        TRUE
summarise_monotonicity(diagnostic)
#>              level axis n_paths n_monotone fraction_monotone
#> feature.c0 feature   c0       2          1               0.5
#>            mean_total_violation max_violation
#> feature.c0                 0.05           0.1
```

Monotone post-processing returns data, not a modified fit object:

``` r
enforce_monotone_selection(
  surface,
  axis = "c0",
  direction = "nonincreasing",
  method = "cummin",
  level = "feature"
)
#>                                                   id   level axis axis_value
#> a.feature...NA.....NA...a...NA...feature...NA...1  a feature   c0        0.2
#> a.feature...NA.....NA...a...NA...feature...NA...2  a feature   c0        0.6
#> b.feature...NA.....NA...b...NA...feature...NA...3  b feature   c0        0.2
#> b.feature...NA.....NA...b...NA...feature...NA...4  b feature   c0        0.6
#>                                                   value delta violation
#> a.feature...NA.....NA...a...NA...feature...NA...1   0.8    NA     FALSE
#> a.feature...NA.....NA...a...NA...feature...NA...2   0.9   0.0     FALSE
#> b.feature...NA.....NA...b...NA...feature...NA...3   0.4    NA     FALSE
#> b.feature...NA.....NA...b...NA...feature...NA...4   0.2  -0.2     FALSE
#>                                                   violation_size method  q  c0
#> a.feature...NA.....NA...a...NA...feature...NA...1              0   <NA> NA 0.2
#> a.feature...NA.....NA...a...NA...feature...NA...2              0   <NA> NA 0.6
#> b.feature...NA.....NA...b...NA...feature...NA...3              0   <NA> NA 0.2
#> b.feature...NA.....NA...b...NA...feature...NA...4              0   <NA> NA 0.6
#>                                                   adjusted_value
#> a.feature...NA.....NA...a...NA...feature...NA...1            0.8
#> a.feature...NA.....NA...a...NA...feature...NA...2            0.8
#> b.feature...NA.....NA...b...NA...feature...NA...3            0.4
#> b.feature...NA.....NA...b...NA...feature...NA...4            0.2
```

Precision-recall paths use the same surface data and a mapped truth
object.

``` r
truth <- list(
  active_features = "a",
  feature_universe = c("a", "b")
)

pr <- precision_recall_curve_fda(
  surface,
  truth = truth,
  level = "feature",
  threshold_grid = c(0, 0.5, 0.75)
)

pr
#>      level n_universe n_truth n_selected tp fp fn tn precision recall
#> 1  feature          2       1          2  1  1  0  0       0.5      1
#> 2  feature          2       1          1  1  0  0  1       1.0      1
#> 3  feature          2       1          1  1  0  0  1       1.0      1
#> 21 feature          2       1          2  1  1  0  0       0.5      1
#> 22 feature          2       1          1  1  0  0  1       1.0      1
#> 23 feature          2       1          1  1  0  0  1       1.0      1
#>    specificity        f1 jaccard selection_rate threshold method  q  c0
#> 1            0 0.6666667     0.5            1.0      0.00   <NA> NA 0.2
#> 2            1 1.0000000     1.0            0.5      0.50   <NA> NA 0.2
#> 3            1 1.0000000     1.0            0.5      0.75   <NA> NA 0.2
#> 21           0 0.6666667     0.5            1.0      0.00   <NA> NA 0.6
#> 22           1 1.0000000     1.0            0.5      0.50   <NA> NA 0.6
#> 23           1 1.0000000     1.0            0.5      0.75   <NA> NA 0.6
best_threshold_fda(pr, metric = "f1")
#> data frame with 0 columns and 0 rows
summarise_precision_recall_fda(pr)
#> [1] method         level          best_threshold precision      recall        
#> [6] f1             jaccard        selection_rate
#> <0 rows> (or 0-length row.names)
```
