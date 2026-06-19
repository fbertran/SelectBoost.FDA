# Association Diagnostics for Functional Predictors

FDA-aware SelectBoost depends on an association structure between
flattened functional coefficients. The package exposes these structures
as ordinary matrices and diagnostic tables.

``` r

library(SelectBoost.FDA)

sim <- simulate_fda_scenario(
  n = 24,
  grid_length = 12,
  include_scalar = FALSE,
  seed = 1
)

diagnostics <- diagnose_functional_association(
  sim$design,
  methods = c("correlation", "neighborhood", "hybrid", "interval"),
  bandwidth = 2,
  width = 3
)

diagnostics[, c("method", "sparsity", "within_block_mass", "cross_block_mass", "local_mass")]
#>         method  sparsity within_block_mass cross_block_mass local_mass
#> 1  correlation 0.8478261                 1                0          1
#> 2 neighborhood 0.8478261                 1                0          1
#> 3       hybrid 0.8478261                 1                0          1
#> 4     interval 0.9130435                 1                0          1
```

The heatmap extractor returns long-form data and feature metadata. It
does not require any plotting backend.

``` r

heatmap_data <- as_association_heatmap_data(
  sim$design,
  method = "hybrid",
  within_blocks = TRUE,
  bandwidth = 2
)

head(heatmap_data)
#>   feature_i feature_j predictor_i predictor_j position_i position_j
#> 1  signal_1  signal_1      signal      signal          1          1
#> 2  signal_2  signal_1      signal      signal          2          1
#> 3  signal_3  signal_1      signal      signal          3          1
#> 4  signal_4  signal_1      signal      signal          4          1
#> 5  signal_5  signal_1      signal      signal          5          1
#> 6  signal_6  signal_1      signal      signal          6          1
#>             argval_i argval_j association same_block within_bandwidth method
#> 1                  0        0  1.00000000       TRUE             TRUE hybrid
#> 2 0.0909090909090909        0  0.11152741       TRUE             TRUE hybrid
#> 3  0.181818181818182        0  0.09626719       TRUE             TRUE hybrid
#> 4  0.272727272727273        0  0.00000000       TRUE            FALSE hybrid
#> 5  0.363636363636364        0  0.00000000       TRUE            FALSE hybrid
#> 6  0.454545454545455        0  0.00000000       TRUE            FALSE hybrid
```

The same diagnostics can be computed for a user-supplied association
matrix:

``` r

assoc <- functional_association(sim$design, method = "neighborhood", bandwidth = 2)
summarise_association_structure(assoc, x = sim$design, bandwidth = 2)
#>   method mean_association median_association  sparsity within_block_mass
#> 1   <NA>       0.06400966                  0 0.8478261                 1
#>   cross_block_mass local_mass nonlocal_mass effective_degree_mean
#> 1                0          1             0                   3.5
#>   effective_degree_sd diag_is_one
#> 1           0.7801895        TRUE
```
