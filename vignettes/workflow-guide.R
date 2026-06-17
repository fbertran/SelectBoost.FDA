## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

## -----------------------------------------------------------------------------
library(SelectBoost.FDA)

sim <- simulate_fda_scenario(
  n = 18,
  grid_length = 10,
  include_scalar = FALSE,
  seed = 1
)

sim$design
head(selection_map(sim$design))

