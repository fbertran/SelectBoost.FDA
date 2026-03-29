test_that("fitted preprocessors can be reused on new data", {
  train <- make_preprocess_example(n = 50, seed = 1)
  test <- make_preprocess_example(n = 20, seed = 2)

  train_predictors <- list(
    signal = fda_grid(train$predictors$signal, argvals = train$grid, name = "signal", unit = "time"),
    nuisance = fda_grid(train$predictors$nuisance, argvals = train$grid, name = "nuisance", unit = "time")
  )
  test_predictors <- list(
    signal = fda_grid(test$predictors$signal, argvals = test$grid, name = "signal", unit = "time"),
    nuisance = fda_grid(test$predictors$nuisance, argvals = test$grid, name = "nuisance", unit = "time")
  )

  prep <- fit_fda_preprocessor(
    predictors = train_predictors,
    scalar_covariates = train$scalar_covariates,
    transforms = list(
      signal = fda_bspline(df = 5, center = TRUE),
      nuisance = fda_fpca(n_components = 2)
    ),
    scalar_transform = fda_standardize()
  )

  train_matrix <- apply_fda_preprocessor(prep, train_predictors, train$scalar_covariates)
  test_matrix <- apply_fda_preprocessor(prep, test_predictors, test$scalar_covariates)

  expect_s3_class(prep, "fda_preprocessor")
  expect_s3_class(train_matrix, "fda_matrix")
  expect_equal(ncol(train_matrix$x), 9)
  expect_identical(colnames(train_matrix$x), colnames(test_matrix$x))
  expect_true(all(c("transform", "source_representation", "domain_start", "domain_end") %in% names(train_matrix$feature_map)))
  expect_true(any(train_matrix$feature_map$basis_type == "spline"))
  expect_true(any(train_matrix$feature_map$basis_type == "fpca"))
  expect_true(any(train_matrix$feature_map$representation == "scalar"))
})

test_that("design objects can be built from raw curves, preprocessors, and scalar covariates", {
  data <- make_preprocess_example(n = 60, seed = 3)

  design <- fda_design(
    response = data$y,
    predictors = list(
      signal = fda_grid(data$predictors$signal, argvals = data$grid, name = "signal", unit = "time"),
      nuisance = fda_grid(data$predictors$nuisance, argvals = data$grid, name = "nuisance", unit = "time")
    ),
    scalar_covariates = data$scalar_covariates,
    transforms = list(
      signal = fda_bspline(df = 6, center = TRUE),
      nuisance = fda_fpca(n_components = 2)
    ),
    scalar_transform = fda_standardize(),
    family = "gaussian"
  )

  map <- selection_map(design)
  summary_design <- summary(design)

  expect_s3_class(design, "fda_design")
  expect_s3_class(design$preprocessor, "fda_preprocessor")
  expect_equal(summary_design$n_scalar_covariates, 2)
  expect_true(all(c("transform", "source_representation", "domain_start", "domain_end") %in% names(map)))
  expect_true(any(map$representation == "scalar"))
  expect_true(any(map$basis_type == "spline"))
  expect_true(any(map$basis_type == "fpca"))
})

test_that("selected() returns consistent filtered maps across fit types", {
  data <- make_preprocess_example(n = 60, seed = 4)
  design <- fda_design(
    response = data$y,
    predictors = list(
      signal = fda_grid(data$predictors$signal, argvals = data$grid, name = "signal"),
      nuisance = fda_grid(data$predictors$nuisance, argvals = data$grid, name = "nuisance")
    ),
    scalar_covariates = data$scalar_covariates,
    transforms = list(
      signal = fda_bspline(df = 5),
      nuisance = fda_fpca(n_components = 2)
    ),
    scalar_transform = fda_standardize(),
    family = "gaussian"
  )

  stab_fit <- fit_stability(
    design,
    selector = "glmnet",
    B = 10,
    cutoff = 0.5,
    seed = 5
  )
  sb_fit <- fit_selectboost(
    design,
    selector = "glmnet",
    mode = "fast",
    steps.seq = c(0.6, 0.2),
    B = 4
  )

  stab_selected <- selected(stab_fit, level = "group")
  sb_selected <- selected(sb_fit, level = "group", c0 = colnames(sb_fit$feature_selection)[1], threshold = 0)

  expect_true(all(stab_selected$group_selected))
  expect_true(all(sb_selected$max_selection > 0))
})
