## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)
has_grpreg <- requireNamespace("grpreg", quietly = TRUE)

## -----------------------------------------------------------------------------
library(SelectBoost.FDA)
data("spectra_example", package = "SelectBoost.FDA")

signal <- fda_grid(
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
  predictors = list(signal = signal, nuisance = nuisance),
  scalar_covariates = spectra_example$scalar_covariates,
  scalar_transform = fda_standardize(),
  family = "gaussian"
)

design
summary(design)
head(selection_map(design))

## -----------------------------------------------------------------------------
design$preprocessor
summary(design$preprocessor)

## ----eval = has_grpreg--------------------------------------------------------
fit <- fit_stability(
  design,
  selector = "grpreg",
  B = 30,
  sample_fraction = 0.5,
  cutoff = 0.7,
  seed = 1
)

fit
summary(fit)
head(selection_map(fit))
plot(fit, type = "group")
selected(fit, level = "group")

## ----eval = has_grpreg--------------------------------------------------------
interval_fit <- interval_stability_selection(
  design,
  width = 5,
  selector = "grpreg",
  B = 20,
  cutoff = 0.6,
  seed = 2
)

head(interval_fit$interval_table)
plot(
  interval_fit,
  type = "interval",
  value = "mean",
  facet = "predictor",
  legend_title = "Mean frequency",
  palette = grDevices::heat.colors(24)
)
selected(interval_fit, level = "group")

