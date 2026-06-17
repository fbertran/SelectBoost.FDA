test_that("perturbation grid returns stable S3 selection surfaces", {
  sim <- simulate_fda_scenario(
    n = 18,
    grid_length = 10,
    include_scalar = FALSE,
    seed = 21
  )

  fit <- fit_perturbation_grid(
    sim$design,
    q_grid = c(0.6, 0.8),
    c0_grid = c(0.7, 0.4),
    B = 1,
    selectboost_B = 1,
    selector = "msgps",
    levels = c("feature", "group"),
    seed = 22
  )

  expect_s3_class(fit, "fda_perturbation_grid")
  expect_equal(fit$q_grid, c(0.6, 0.8))
  expect_equal(fit$c0_grid, c(0.7, 0.4))
  expect_true(nrow(fit$surface) > 0)
  expect_true(all(c("q", "c0", "selection", "level") %in% names(selection_surface(fit))))
  expect_true(nrow(selection_map(fit, level = "feature")) > 0)
  expect_s3_class(summary(fit), "summary.fda_perturbation_grid")
})

test_that("same perturbation-grid seed gives identical surface summaries", {
  sim <- simulate_fda_scenario(
    n = 18,
    grid_length = 10,
    include_scalar = FALSE,
    seed = 31
  )
  args <- list(
    x = sim$design,
    q_grid = c(0.7),
    c0_grid = c(1),
    B = 1,
    selectboost_B = 1,
    selector_fun = function(X, y, groups, family, ...) {
      as.numeric(colMeans(abs(X)) > stats::median(colMeans(abs(X))))
    },
    levels = "feature",
    seed = 32
  )

  fit1 <- do.call(fit_perturbation_grid, args)
  fit2 <- do.call(fit_perturbation_grid, args)

  expect_equal(fit1$surface, fit2$surface)
})
