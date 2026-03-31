test_that("common selector aliases include sparse-group lasso", {
  skip_if_not_installed("SGL")

  data <- make_preprocess_example(n = 60, seed = 11)
  design <- fda_design(
    response = data$y,
    predictors = list(
      signal = fda_grid(data$predictors$signal, argvals = data$grid, name = "signal"),
      nuisance = fda_grid(data$predictors$nuisance, argvals = data$grid, name = "nuisance")
    ),
    scalar_covariates = data$scalar_covariates,
    scalar_transform = fda_standardize(),
    family = "gaussian"
  )

  stab_fit <- fit_stability(
    design,
    selector = "sparse_group_lasso",
    B = 8,
    cutoff = 0.4,
    seed = 12
  )
  sb_fit <- fit_selectboost(
    design,
    selector = "sparse_group_lasso",
    mode = "fast",
    steps.seq = c(0.6, 0.3),
    c0lim = FALSE,
    B = 4
  )

  expect_s3_class(stab_fit, "fda_stability_selection")
  expect_s3_class(sb_fit, "selectboost_fda_result")
  expect_true(length(stab_fit$feature_frequency) == ncol(design$matrix$x))
  expect_true(ncol(sb_fit$feature_selection) == 2)
})

test_that("overlapping interval groups are first-class stability-selection inputs", {
  data <- make_preprocess_example(n = 60, seed = 13)
  design <- fda_design(
    response = data$y,
    predictors = list(
      signal = fda_grid(data$predictors$signal, argvals = data$grid, name = "signal"),
      nuisance = fda_grid(data$predictors$nuisance, argvals = data$grid, name = "nuisance")
    ),
    family = "gaussian"
  )

  groups <- functional_interval_groups(design, width = 6, step = 3, overlap = TRUE)
  fit <- stability_selection_fda(
    design,
    selector = "lasso",
    groups = groups,
    B = 10,
    cutoff = 0.4,
    seed = 14
  )
  group_map <- selection_map(fit, level = "group")

  expect_s3_class(groups, "fda_group_list")
  expect_true(attr(groups, "overlap"))
  expect_true(nrow(group_map) > length(unique(design$matrix$blocks)))
  expect_true(all(c("interval_label", "group_frequency") %in% names(group_map)))
})

test_that("association helpers and calibration helpers support region-aware workflows", {
  data <- make_preprocess_example(n = 60, seed = 15)
  design <- fda_design(
    response = data$y,
    predictors = list(
      signal = fda_grid(data$predictors$signal, argvals = data$grid, name = "signal"),
      nuisance = fda_grid(data$predictors$nuisance, argvals = data$grid, name = "nuisance")
    ),
    family = "gaussian"
  )

  assoc_neighborhood <- functional_association(design, method = "neighborhood", bandwidth = 3)
  assoc_interval <- functional_association(design, method = "interval", width = 5)
  c0_grid <- suggest_c0_grid(design, n = 4, association_method = "hybrid")

  cal_stability <- calibrate_stability_selection(
    design,
    selector = "lasso",
    sample_fraction_grid = c(0.5, 0.7),
    cutoff_grid = c(0.4, 0.6),
    B = 8,
    seed = 16
  )
  cal_width <- calibrate_interval_width(
    design,
    widths = c(4, 6),
    selector = "lasso",
    B = 8,
    cutoff = 0.4,
    seed = 17
  )
  cal_selectboost <- calibrate_selectboost(
    design,
    selector = "lasso",
    c0_grid = c(0.6, 0.3),
    B = 4
  )

  expect_equal(dim(assoc_neighborhood), dim(design$matrix$x)[2] * c(1, 1))
  expect_equal(dim(assoc_interval), dim(design$matrix$x)[2] * c(1, 1))
  expect_equal(length(c0_grid), 4)
  expect_s3_class(cal_stability, "fda_calibration_grid")
  expect_s3_class(cal_width, "fda_calibration_grid")
  expect_s3_class(cal_selectboost, "fda_calibration_grid")
  expect_equal(nrow(cal_stability$grid), 4)
  expect_equal(nrow(cal_width$grid), 2)
  expect_true(all(c("c0", "n_selected_features") %in% names(cal_selectboost$grid)))
})

test_that("comparison utilities and formula interface work on the same design semantics", {
  data <- make_preprocess_example(n = 70, seed = 18)
  formula_data <- list(
    y = data$y,
    signal = fda_grid(data$predictors$signal, argvals = data$grid, name = "signal"),
    nuisance = fda_grid(data$predictors$nuisance, argvals = data$grid, name = "nuisance"),
    age = data$scalar_covariates$age,
    treatment = factor(data$scalar_covariates$treatment)
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

  comparison <- compare_selection_methods(
    design,
    methods = c("stability", "interval", "selectboost"),
    stability_args = list(selector = "lasso", B = 8, cutoff = 0.4, seed = 19),
    interval_args = list(selector = "lasso", width = 5, B = 8, cutoff = 0.4, seed = 20),
    selectboost_args = list(selector = "lasso", B = 4, steps.seq = c(0.6, 0.3), c0lim = FALSE)
  )
  formula_fit <- fit_stability_formula(
    y ~ signal + nuisance + age + treatment,
    data = formula_data,
    transforms = list(
      signal = fda_fpca(n_components = 3),
      nuisance = fda_bspline(df = 5)
    ),
    scalar_transform = fda_standardize(),
    family = "gaussian",
    selector = "lasso",
    B = 8,
    cutoff = 0.4,
    seed = 21
  )

  expect_s3_class(design, "fda_design")
  expect_s3_class(comparison, "fda_method_comparison")
  expect_s3_class(formula_fit, "fda_stability_selection")
  expect_true(all(c("method", "n_selected_features") %in% names(comparison$summary_table)))
  expect_true(all(c("stability", "interval", "selectboost") %in% unique(comparison$summary_table$method)))
  expect_true(nrow(selection_map(comparison, level = "group")) > 0)
})
