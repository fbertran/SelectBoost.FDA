## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)
has_glmnet <- requireNamespace("glmnet", quietly = TRUE)
has_sgl <- requireNamespace("SGL", quietly = TRUE)

## -----------------------------------------------------------------------------
library(SelectBoost.FDA)
data("spectra_example", package = "SelectBoost.FDA")

formula_data <- list(
  y = spectra_example$response,
  signal = fda_grid(
    spectra_example$predictors$signal,
    argvals = spectra_example$grid,
    name = "signal",
    unit = "nm"
  ),
  nuisance = fda_grid(
    spectra_example$predictors$nuisance,
    argvals = spectra_example$grid,
    name = "nuisance",
    unit = "nm"
  ),
  age = spectra_example$scalar_covariates$age,
  treatment = factor(spectra_example$scalar_covariates$treatment)
)

design <- fda_design_formula(
  y ~ signal + nuisance + age + treatment,
  data = formula_data,
  transforms = list(
    signal = fda_fpca(n_components = 3),
    nuisance = fda_bspline(df = 5)
  ),
  scalar_transform = fda_standardize(),
  family = "gaussian"
)

design
selection_map(design, level = "basis")

## ----eval = has_glmnet--------------------------------------------------------
cal_stability <- calibrate_stability_selection(
  design,
  selector = "lasso",
  sample_fraction_grid = c(0.5, 0.7),
  cutoff_grid = c(0.5, 0.7),
  B = 8,
  seed = 1
)

cal_width <- calibrate_interval_width(
  design,
  widths = c(4, 6),
  selector = "lasso",
  B = 8,
  cutoff = 0.5,
  seed = 2
)

cal_selectboost <- calibrate_selectboost(
  design,
  selector = "lasso",
  c0_grid = c(0.7, 0.4),
  B = 4
)

cal_stability
cal_stability$grid
cal_width$grid
cal_selectboost$grid

## ----eval = has_glmnet--------------------------------------------------------
comparison <- compare_selection_methods(
  design,
  methods = c("stability", "interval", "selectboost"),
  stability_args = list(selector = "lasso", B = 8, cutoff = 0.5, seed = 3),
  interval_args = list(selector = "lasso", width = 5, B = 8, cutoff = 0.5, seed = 4),
  selectboost_args = list(selector = "lasso", B = 4, steps.seq = c(0.7, 0.4), c0lim = FALSE)
)

comparison
summary(comparison)
head(selection_map(comparison, level = "group"))

## ----eval = has_sgl-----------------------------------------------------------
fit_stability(
  design,
  selector = "sparse_group_lasso",
  B = 8,
  cutoff = 0.5,
  seed = 5
)

