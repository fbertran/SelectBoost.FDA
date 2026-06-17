## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)
has_glmnet <- requireNamespace("glmnet", quietly = TRUE)

## -----------------------------------------------------------------------------
library(SelectBoost.FDA)
data("motion_example", package = "SelectBoost.FDA")

predictors <- list(
  signal = fda_grid(
    motion_example$predictors$signal,
    argvals = motion_example$grid,
    name = "signal",
    unit = "time"
  ),
  nuisance = fda_grid(
    motion_example$predictors$nuisance,
    argvals = motion_example$grid,
    name = "nuisance",
    unit = "time"
  )
)

prep <- fit_fda_preprocessor(
  predictors = predictors,
  scalar_covariates = motion_example$scalar_covariates,
  transforms = list(
    signal = fda_fpca(n_components = 3),
    nuisance = fda_bspline(df = 5, center = TRUE)
  ),
  scalar_transform = fda_standardize()
)

prep
summary(prep)

## -----------------------------------------------------------------------------
design <- fda_design(
  response = motion_example$response,
  predictors = predictors,
  scalar_covariates = motion_example$scalar_covariates,
  preprocessor = prep,
  family = "gaussian"
)

head(selection_map(design))
selection_map(design, level = "basis")

## ----eval = has_glmnet--------------------------------------------------------
fit <- fit_stability(
  design,
  selector = "glmnet",
  B = 30,
  sample_fraction = 0.5,
  cutoff = 0.6,
  seed = 7
)

fit
summary(fit)
selection_map(fit)
selection_map(fit, level = "basis")
selected(fit, level = "basis")
plot(fit, type = "basis", value = "mean")

