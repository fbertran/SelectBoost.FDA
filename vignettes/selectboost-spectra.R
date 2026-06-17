## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)
has_glmnet <- requireNamespace("glmnet", quietly = TRUE)

## -----------------------------------------------------------------------------
library(SelectBoost.FDA)
data("spectra_example", package = "SelectBoost.FDA")

spectra <- fda_grid(
  spectra_example$predictors$signal,
  argvals = spectra_example$grid,
  name = "signal",
  unit = "nm"
)
nuisance <- fda_grid(
  spectra_example$predictors$nuisance,
  argvals = spectra_example$grid,
  name = "nuisance",
  unit = "nm"
)

design <- fda_design(
  response = spectra_example$response,
  predictors = list(signal = spectra, nuisance = nuisance),
  scalar_covariates = spectra_example$scalar_covariates,
  scalar_transform = fda_standardize(),
  family = "gaussian"
)

head(selection_map(design))

## ----eval = has_glmnet--------------------------------------------------------
sb_fit <- fit_selectboost(
  design,
  selector = "glmnet",
  selector_args = list(lambda_rule = "lambda.min"),
  mode = "fast",
  group_method = "threshold",
  bandwidth = 3,
  steps.seq = c(0.6, 0.2),
  B = 10,
  seed = 1
)

sb_fit
summary(sb_fit)
head(selection_map(sb_fit, c0 = colnames(sb_fit$feature_selection)[1]))
selected(sb_fit, level = "group", c0 = colnames(sb_fit$feature_selection)[1])
plot(
  sb_fit,
  type = "group",
  value = "mean",
  legend_title = "Mean selection",
  palette = grDevices::terrain.colors(24)
)

