## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(collapse = TRUE, comment = "#>")

## -----------------------------------------------------------------------------
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
head(selection_surface(grid_fit))
summarise_perturbation_grid(grid_fit)

## -----------------------------------------------------------------------------
feature_surface <- selection_map(grid_fit, level = "feature")
group_surface <- selection_map(grid_fit, level = "group")

head(feature_surface[, c("feature", "q", "c0", "selection", "selected")])
head(group_surface[, c("group", "q", "c0", "mean_selection", "max_selection")])

## -----------------------------------------------------------------------------
head(selected_surface(grid_fit, threshold = 0.5, level = "feature"))

