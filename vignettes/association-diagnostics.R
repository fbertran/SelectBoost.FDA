## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(collapse = TRUE, comment = "#>")

## -----------------------------------------------------------------------------
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

## -----------------------------------------------------------------------------
heatmap_data <- as_association_heatmap_data(
  sim$design,
  method = "hybrid",
  within_blocks = TRUE,
  bandwidth = 2
)

head(heatmap_data)

## -----------------------------------------------------------------------------
assoc <- functional_association(sim$design, method = "neighborhood", bandwidth = 2)
summarise_association_structure(assoc, x = sim$design, bandwidth = 2)

