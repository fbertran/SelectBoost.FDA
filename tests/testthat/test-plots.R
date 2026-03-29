test_that("stability-selection plot methods render interval and basis summaries", {
  data <- make_example_fda_data()

  interval_fit <- interval_stability_selection(
    x = data$x,
    y = data$y,
    width = 2,
    selector = "glmnet",
    B = 10,
    seed = 4,
    cutoff = 0.5
  )

  scores1 <- matrix(rnorm(120), nrow = 40, ncol = 3)
  scores2 <- matrix(rnorm(80), nrow = 40, ncol = 2)
  y <- 2 * scores1[, 1] - scores1[, 2] + rnorm(40, sd = 0.25)
  basis_design <- fda_design(
    response = y,
    predictors = list(
      fpca_signal = fda_basis(scores1, basis_type = "fpca", component_names = paste0("PC", 1:3), name = "fpca_signal"),
      fpca_noise = fda_basis(scores2, basis_type = "fpca", component_names = paste0("PC", 1:2), name = "fpca_noise")
    ),
    family = "gaussian"
  )
  basis_fit <- fit_stability(
    basis_design,
    selector = "glmnet",
    B = 10,
    cutoff = 0.5,
    seed = 5
  )

  pdf_file <- tempfile(fileext = ".pdf")
  grDevices::pdf(pdf_file)
  on.exit({
    grDevices::dev.off()
    unlink(pdf_file)
  }, add = TRUE)

  expect_no_error(plot(
    interval_fit,
    type = "interval",
    value = "mean",
    facet = "predictor",
    palette = grDevices::heat.colors(24),
    legend_title = "Mean freq",
    legend_n_ticks = 4,
    legend_digits = 3
  ))
  expect_no_error(plot(basis_fit, type = "basis", value = "mean"))
})

test_that("selectboost plot methods render feature, group, and basis summaries", {
  data <- make_example_fda_data(n = 60)
  design <- fda_design(
    response = data$y,
    predictors = list(
      signal = fda_grid(data$x$signal, name = "signal"),
      noise = fda_grid(data$x$noise, name = "noise")
    ),
    family = "gaussian"
  )
  sb_fit <- fit_selectboost(
    design,
    selector = "glmnet",
    mode = "fast",
    steps.seq = c(0.6, 0.2),
    B = 4
  )

  basis_scores <- matrix(rnorm(120), nrow = 40, ncol = 3)
  basis_design <- fda_design(
    response = 1.5 * basis_scores[, 1] - basis_scores[, 2] + rnorm(40, sd = 0.3),
    predictors = list(
      fpca_signal = fda_basis(basis_scores, basis_type = "fpca", component_names = paste0("PC", 1:3), name = "fpca_signal")
    ),
    family = "gaussian"
  )
  basis_sb_fit <- fit_selectboost(
    basis_design,
    selector = "glmnet",
    mode = "fast",
    steps.seq = c(0.6, 0.2),
    B = 4
  )

  pdf_file <- tempfile(fileext = ".pdf")
  grDevices::pdf(pdf_file)
  on.exit({
    grDevices::dev.off()
    unlink(pdf_file)
  }, add = TRUE)

  expect_no_error(plot(sb_fit, type = "feature"))
  expect_no_error(plot(
    sb_fit,
    type = "group",
    value = "mean",
    palette = grDevices::terrain.colors(24),
    show_legend = FALSE
  ))
  expect_no_error(plot(
    basis_sb_fit,
    type = "basis",
    value = "mean",
    legend_cex = 0.65
  ))
})
