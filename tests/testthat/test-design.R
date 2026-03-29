test_that("fda constructors build a reversible design object", {
  grid <- fda_grid(
    values = matrix(rnorm(20), nrow = 5, ncol = 4),
    argvals = seq(0, 1, length.out = 4),
    name = "signal",
    unit = "time"
  )
  basis <- fda_basis(
    coefficients = matrix(rnorm(15), nrow = 5, ncol = 3),
    basis_type = "fpca",
    component_names = paste0("pc", 1:3),
    name = "scores"
  )

  design <- fda_design(
    response = rnorm(5),
    predictors = list(signal = grid, scores = basis),
    family = "gaussian"
  )

  expect_s3_class(grid, "fda_grid")
  expect_s3_class(basis, "fda_basis")
  expect_s3_class(design, "fda_design")
  expect_equal(nrow(selection_map(design)), 7)
  expect_equal(unique(selection_map(design)$predictor), c("signal", "scores"))
  expect_equal(selection_map(design, level = "basis")$predictor, "scores")
  expect_equal(selection_map(design, level = "basis")$n_components, 3)
})

test_that("design-driven fit wrappers return classed selection objects", {
  data <- make_example_fda_data(n = 60)
  design <- fda_design(
    response = data$y,
    predictors = list(
      signal = fda_grid(data$x$signal, name = "signal"),
      noise = fda_grid(data$x$noise, name = "noise")
    ),
    family = "gaussian"
  )

  stab_fit <- fit_stability(
    design,
    selector = "grpreg",
    B = 12,
    cutoff = 0.6,
    seed = 1
  )

  sb_fit <- fit_selectboost(
    design,
    selector = "glmnet",
    mode = "fast",
    steps.seq = c(0.6, 0.2),
    B = 4
  )

  expect_s3_class(stab_fit, "fda_stability_fit")
  expect_s3_class(sb_fit, "fda_selectboost_fit")
  expect_true(all(c("feature_frequency", "selected") %in% names(selection_map(stab_fit))))
  expect_true(all(c("c0", "selection") %in% names(selection_map(sb_fit))))
  expect_true(all(c("group", "mean_selection") %in% names(selection_map(sb_fit, level = "group", c0 = "c0 = 1"))))
})

test_that("basis summaries aggregate component-level stability information", {
  set.seed(11)
  scores1 <- matrix(rnorm(120), nrow = 40, ncol = 3)
  scores2 <- matrix(rnorm(80), nrow = 40, ncol = 2)
  y <- 2 * scores1[, 1] - 1.25 * scores1[, 2] + rnorm(40, sd = 0.3)

  design <- fda_design(
    response = y,
    predictors = list(
      fpca_signal = fda_basis(scores1, basis_type = "fpca", component_names = paste0("PC", 1:3), name = "fpca_signal"),
      fpca_noise = fda_basis(scores2, basis_type = "fpca", component_names = paste0("PC", 1:2), name = "fpca_noise")
    ),
    family = "gaussian"
  )

  fit <- fit_stability(
    design,
    selector = "glmnet",
    B = 12,
    cutoff = 0.5,
    seed = 3
  )

  basis_map <- selection_map(fit, level = "basis")

  expect_equal(nrow(basis_map), 2)
  expect_true(all(c("predictor", "n_components", "selected_components") %in% names(basis_map)))
  expect_true(basis_map$selected_components[basis_map$predictor == "fpca_signal"] >=
                basis_map$selected_components[basis_map$predictor == "fpca_noise"])
})
