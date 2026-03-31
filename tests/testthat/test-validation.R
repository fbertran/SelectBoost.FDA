test_that("plain SelectBoost baseline produces classed FDA results", {
  sim <- simulate_fda_scenario(
    n = 40,
    grid_length = 24,
    seed = 101
  )

  fit <- plain_selectboost(
    sim$design,
    selector = "lasso",
    mode = "fast",
    steps.seq = c(0.6, 0.3),
    c0lim = FALSE,
    B = 4
  )

  expect_s3_class(fit, "plain_selectboost_result")
  expect_s3_class(summary(fit), "summary.plain_selectboost_result")
  expect_equal(dim(fit$feature_selection), c(ncol(sim$design$matrix$x), 2))
  expect_true(nrow(selection_map(fit, level = "group", c0 = colnames(fit$feature_selection)[1])) > 0)
})

test_that("simulation scenarios preserve mapped truth across representations", {
  representations <- c("grid", "basis", "fpca")
  sims <- lapply(seq_along(representations), function(i) {
    simulate_fda_scenario(
      n = 35,
      grid_length = 24,
      representation = representations[i],
      seed = 200 + i
    )
  })

  for (i in seq_along(sims)) {
    sim <- sims[[i]]
    expect_s3_class(sim, "fda_simulation_data")
    expect_s3_class(sim$design, "fda_design")
    expect_true(length(sim$truth$active_features) > 0)
    expect_true("signal" %in% sim$truth$active_predictors)

    if (!identical(representations[i], "grid")) {
      expect_true(any(sim$design$feature_map$representation == "basis"))
    }
  }
})

test_that("benchmark utilities evaluate multiple FDA methods on shared truth", {
  sim <- simulate_fda_scenario(
    n = 45,
    grid_length = 24,
    seed = 301
  )

  comparison <- compare_selection_methods(
    sim$design,
    methods = c("stability", "interval", "selectboost", "plain_selectboost"),
    stability_args = list(selector = "lasso", B = 8, cutoff = 0.4, seed = 302),
    interval_args = list(selector = "lasso", width = 4, B = 8, cutoff = 0.4, seed = 303),
    selectboost_args = list(selector = "lasso", B = 4, steps.seq = c(0.6, 0.3), c0lim = FALSE),
    plain_selectboost_args = list(selector = "lasso", B = 4, steps.seq = c(0.6, 0.3), c0lim = FALSE)
  )

  feature_metrics <- evaluate_selection(comparison, truth = sim, level = "feature")
  group_metrics <- evaluate_selection(comparison, truth = sim, level = "group")
  bench <- benchmark_selection_methods(
    sim,
    methods = c("stability", "interval", "selectboost", "plain_selectboost"),
    levels = c("feature", "group"),
    stability_args = list(selector = "lasso", B = 8, cutoff = 0.4, seed = 304),
    interval_args = list(selector = "lasso", width = 4, B = 8, cutoff = 0.4, seed = 305),
    selectboost_args = list(selector = "lasso", B = 4, steps.seq = c(0.6, 0.3), c0lim = FALSE),
    plain_selectboost_args = list(selector = "lasso", B = 4, steps.seq = c(0.6, 0.3), c0lim = FALSE)
  )

  expect_s3_class(comparison, "fda_method_comparison")
  expect_true(all(c("method", "precision", "recall", "jaccard") %in% names(feature_metrics)))
  expect_true(all(c("stability", "interval", "selectboost", "plain_selectboost") %in% unique(feature_metrics$method)))
  expect_true(all(c("stability", "interval", "selectboost", "plain_selectboost") %in% unique(group_metrics$method)))
  expect_s3_class(bench, "fda_benchmark")
  expect_true(all(c("feature", "group") %in% unique(bench$metrics$level)))
  expect_true(nrow(selection_map(bench, level = "group")) > 0)
})

test_that("simulation studies aggregate repeated benchmark metrics", {
  study <- run_simulation_study(
    n_rep = 2,
    simulate_args = list(n = 35, grid_length = 20, representation = "basis"),
    benchmark_args = list(
      methods = c("stability", "selectboost", "plain_selectboost"),
      levels = c("feature", "group", "basis"),
      stability_args = list(selector = "lasso", B = 6, cutoff = 0.4, seed = 401),
      selectboost_args = list(selector = "lasso", B = 4, steps.seq = c(0.6, 0.3), c0lim = FALSE),
      plain_selectboost_args = list(selector = "lasso", B = 4, steps.seq = c(0.6, 0.3), c0lim = FALSE)
    ),
    seed = 400
  )

  expect_s3_class(study, "fda_simulation_study")
  expect_true(all(c("replicate", "method", "level") %in% names(study$metrics)))
  expect_true(nrow(study$summary_table) > 0)
  expect_true(all(c("feature", "group", "basis") %in% unique(study$metrics$level)))
})
