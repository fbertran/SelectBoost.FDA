## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(collapse = TRUE, comment = "#>")

## -----------------------------------------------------------------------------
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
diagnostic
summarise_monotonicity(diagnostic)

## -----------------------------------------------------------------------------
enforce_monotone_selection(
  surface,
  axis = "c0",
  direction = "nonincreasing",
  method = "cummin",
  level = "feature"
)

## -----------------------------------------------------------------------------
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
best_threshold_fda(pr, metric = "f1")
summarise_precision_recall_fda(pr)

