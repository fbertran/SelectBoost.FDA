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
  scenarios <- c("localized_dense", "distributed_smooth", "confounded_blocks")
  sims <- lapply(seq_along(representations), function(i) {
    simulate_fda_scenario(
      n = 35,
      grid_length = 24,
      representation = representations[i],
      scenario = scenarios[i],
      seed = 200 + i
    )
  })

  for (i in seq_along(sims)) {
    sim <- sims[[i]]
    expect_s3_class(sim, "fda_simulation_data")
    expect_s3_class(sim$design, "fda_design")
    expect_true(length(sim$truth$active_features) > 0)
    expect_true("signal" %in% sim$truth$active_predictors)
    expect_true(sim$scenario %in% scenarios)

    if (!identical(representations[i], "grid")) {
      expect_true(any(sim$design$feature_map$representation == "basis"))
    }
  }
})

test_that("simulation controls expose confounding and local structure settings", {
  sim <- simulate_fda_scenario(
    n = 30,
    grid_length = 24,
    scenario = "confounded_blocks",
    confounding_strength = 1.1,
    active_region_scale = 0.6,
    local_correlation = 2,
    seed = 250
  )

  expect_equal(sim$confounding_strength, 1.1)
  expect_equal(sim$active_region_scale, 0.6)
  expect_equal(sim$local_correlation, 2)
  expect_s3_class(sim, "fda_simulation_data")
})

test_that("benchmark utilities evaluate multiple FDA methods on shared truth", {
  sim <- simulate_fda_scenario(
    n = 45,
    grid_length = 24,
    scenario = "localized_dense",
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
  performance <- summarise_benchmark_performance(bench, level = "feature", metric = "f1")
  advantage <- summarise_benchmark_advantage(
    bench,
    target = "selectboost",
    reference = "plain_selectboost",
    level = "feature",
    metric = "f1"
  )

  expect_s3_class(comparison, "fda_method_comparison")
  expect_true(all(c("method", "precision", "recall", "jaccard") %in% names(feature_metrics)))
  expect_true(all(c("stability", "interval", "selectboost", "plain_selectboost") %in% unique(feature_metrics$method)))
  expect_true(all(c("stability", "interval", "selectboost", "plain_selectboost") %in% unique(group_metrics$method)))
  expect_s3_class(bench, "fda_benchmark")
  expect_true(all(c("feature", "group") %in% unique(bench$metrics$level)))
  expect_true(all(c("scenario", "representation", "family") %in% names(bench$metrics)))
  expect_true(all(c("method", "f1_mean") %in% names(performance)))
  expect_true(all(c("reference", "delta_mean", "win_rate") %in% names(advantage)))
  expect_true(nrow(selection_map(bench, level = "group")) > 0)
})

test_that("simulation studies aggregate repeated benchmark metrics", {
  study <- run_simulation_study(
    n_rep = 2,
    simulate_args = list(n = 35, grid_length = 20, representation = "basis", scenario = "confounded_blocks"),
    benchmark_args = list(
      methods = c("stability", "selectboost", "plain_selectboost"),
      levels = c("feature", "group", "basis"),
      stability_args = list(selector = "lasso", B = 6, cutoff = 0.4, seed = 401),
      selectboost_args = list(selector = "lasso", B = 4, steps.seq = c(0.6, 0.3), c0lim = FALSE),
      plain_selectboost_args = list(selector = "lasso", B = 4, steps.seq = c(0.6, 0.3), c0lim = FALSE)
    ),
    seed = 400
  )
  performance <- summarise_benchmark_performance(study, level = "feature", metric = "f1")
  advantage <- summarise_benchmark_advantage(
    study,
    target = "selectboost",
    reference = c("plain_selectboost", "stability"),
    level = "feature",
    metric = "f1"
  )

  expect_s3_class(study, "fda_simulation_study")
  expect_true(all(c("replicate", "method", "level") %in% names(study$metrics)))
  expect_true("scenario" %in% names(study$summary_table))
  expect_true(nrow(study$summary_table) > 0)
  expect_true(all(c("scenario", "method", "f1_mean") %in% names(performance)))
  expect_true(all(c("reference", "delta_mean", "win_rate") %in% names(advantage)))
  expect_true(all(c("feature", "group", "basis") %in% unique(study$metrics$level)))
})

test_that("targeted sensitivity study keeps FDA-setting columns in summaries", {
  study <- run_selectboost_sensitivity_study(
    n_rep = 1,
    simulate_grid = data.frame(
      scenario = c("localized_dense", "confounded_blocks"),
      confounding_strength = c(0.4, 0.9),
      active_region_scale = c(1, 0.7),
      local_correlation = c(0, 2),
      stringsAsFactors = FALSE
    ),
    selectboost_grid = data.frame(
      association_method = c("correlation", "hybrid"),
      bandwidth = c(NA, 4),
      stringsAsFactors = FALSE
    ),
    simulate_args = list(n = 35, grid_length = 20),
    benchmark_args = list(
      methods = c("selectboost", "plain_selectboost"),
      levels = "feature",
      selectboost_args = list(selector = "lasso", B = 4, steps.seq = c(0.6, 0.3), c0lim = FALSE),
      plain_selectboost_args = list(selector = "lasso", B = 4, steps.seq = c(0.6, 0.3), c0lim = FALSE)
    ),
    seed = 500
  )

  performance <- summarise_benchmark_performance(study, level = "feature", metric = "f1")
  advantage <- summarise_benchmark_advantage(
    study,
    target = "selectboost",
    reference = "plain_selectboost",
    level = "feature",
    metric = "f1"
  )

  expect_s3_class(study, "fda_selectboost_sensitivity_study")
  expect_true(all(c("association_method", "bandwidth", "confounding_strength", "active_region_scale", "local_correlation") %in% names(study$metrics)))
  expect_true(all(c("scenario", "association_method", "bandwidth", "f1_mean") %in% names(performance)))
  expect_true(all(c("scenario", "association_method", "bandwidth", "delta_mean", "win_rate") %in% names(advantage)))
  expect_true(all(c("localized_dense", "confounded_blocks") %in% unique(advantage$scenario)))
})
