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
  representations <- c("grid", "bspline", "fpca")
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
    expect_identical(sim$truth$active_features, sim$truth$feature_truth$feature[sim$truth$feature_truth$active])
    expect_setequal(sim$truth$feature_universe, sim$design$feature_map$feature)
    expect_true(sim$scenario %in% scenarios)
    expect_equal(sim$representation, representations[i])

    feature_targets <- sim$truth$active_features
    feature_idx <- match(feature_targets, sim$truth$feature_universe, nomatch = 0L)
    feature_idx <- feature_idx[feature_idx > 0L]
    group_members <- split(seq_along(sim$design$matrix$blocks), sim$design$matrix$blocks)
    group_targets <- names(group_members)[vapply(group_members, function(idx) {
      any(idx %in% feature_idx)
    }, logical(1))]
    expect_true(length(feature_targets) > 0)
    expect_true(length(group_targets) > 0)

    if (!identical(representations[i], "grid")) {
      expect_true(any(sim$design$feature_map$representation == "basis"))
      basis_truth <- sim$truth$feature_truth[sim$truth$feature_truth$representation == "basis", , drop = FALSE]
      basis_component_keys <- paste(
        basis_truth$predictor,
        basis_truth$basis_type,
        basis_truth$component,
        sep = "::"
      )
      expect_true(length(sim$truth$active_basis_components) > 0)
      expect_true(all(sim$truth$active_basis_components %in% sim$truth$basis_component_universe))
      expect_true(all(grepl("^signal::", sim$truth$active_basis_components)))
      expect_setequal(basis_component_keys[basis_truth$active], sim$truth$active_basis_components)
      expect_setequal(basis_component_keys, sim$truth$basis_component_universe)
    } else {
      expect_length(sim$truth$basis_component_universe, 0)
    }
  }
})

test_that("phase 4 simulation scenarios expose explicit ground truth", {
  scenario_grid <- data.frame(
    scenario = c(
      "localized_dense",
      "confounded_blocks",
      "smooth_sparse",
      "basis_block_signal",
      "fpca_low_rank_signal",
      "mislocalized_signal"
    ),
    representation = c("grid", "grid", "grid", "bspline", "fpca", "grid"),
    stringsAsFactors = FALSE
  )

  for (i in seq_len(nrow(scenario_grid))) {
    sim <- simulate_fda_scenario(
      n = 28,
      grid_length = 18,
      scenario = scenario_grid$scenario[i],
      representation = scenario_grid$representation[i],
      include_scalar = FALSE,
      seed = 700 + i
    )

    expect_s3_class(sim, "fda_simulation_data")
    expect_true(nrow(sim$truth$active_functional) > 0)
    expect_true(length(sim$truth$active_features) > 0)
    expect_true(any(sim$truth$feature_truth$active))
    expect_setequal(
      sim$truth$active_features,
      sim$truth$feature_truth$feature[sim$truth$feature_truth$active]
    )
  }

  fpca_sim <- simulate_fda_scenario(
    n = 32,
    grid_length = 20,
    scenario = "fpca_low_rank_signal",
    representation = "fpca",
    include_scalar = FALSE,
    seed = 720
  )
  expect_setequal(
    fpca_sim$truth$active_basis_components,
    c("signal::fpca::PC1", "signal::fpca::PC2")
  )
})

test_that("null-signal scenario reports false positive behavior", {
  sim <- simulate_fda_scenario(
    n = 24,
    grid_length = 14,
    scenario = "null_signal",
    representation = "grid",
    include_scalar = FALSE,
    seed = 730
  )

  expect_s3_class(sim, "fda_simulation_data")
  expect_equal(nrow(sim$truth$active_functional), 0)
  expect_length(sim$truth$active_features, 0)
  expect_false(any(sim$truth$feature_truth$active))

  bench <- benchmark_selection_methods(
    sim,
    methods = "plain_selectboost",
    levels = "feature",
    plain_selectboost_args = list(
      selector = "lasso",
      B = 2,
      steps.seq = 0.5,
      c0lim = FALSE
    )
  )

  expect_true(all(bench$metrics$n_truth == 0))
  expect_equal(bench$metrics$fp, bench$metrics$n_selected)
  expect_true(all(bench$metrics$selection_rate >= 0))
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

test_that("simulation supports fixed-SNR and fixed-noise axes", {
  low_snr <- simulate_fda_scenario(
    n = 30,
    grid_length = 20,
    scenario = "localized_dense",
    include_scalar = FALSE,
    noise_axis = "snr",
    snr = 0.5,
    seed = 260
  )
  high_snr <- simulate_fda_scenario(
    n = 30,
    grid_length = 20,
    scenario = "localized_dense",
    include_scalar = FALSE,
    noise_axis = "snr",
    snr = 4,
    seed = 260
  )
  fixed_noise <- simulate_fda_scenario(
    n = 30,
    grid_length = 20,
    scenario = "localized_dense",
    include_scalar = FALSE,
    noise_axis = "noise_sd",
    noise_sd = 1.2,
    seed = 261
  )

  expect_equal(low_snr$noise_axis, "snr")
  expect_equal(low_snr$snr, 0.5)
  expect_equal(low_snr$effective_snr, 0.5, tolerance = 1e-10)
  expect_equal(high_snr$effective_snr, 4, tolerance = 1e-10)
  expect_gt(low_snr$noise_sd, high_snr$noise_sd)
  expect_equal(fixed_noise$noise_axis, "noise_sd")
  expect_equal(fixed_noise$requested_noise_sd, 1.2)
  expect_equal(fixed_noise$noise_sd, 1.2)
})

test_that("sensitivity study records failed settings instead of dropping them", {
  study <- run_selectboost_sensitivity_study(
    n_rep = 1,
    simulate_grid = data.frame(
      scenario = "localized_dense",
      representation = "grid",
      stringsAsFactors = FALSE
    ),
    selectboost_grid = data.frame(
      association_method = "correlation",
      bandwidth = NA_real_,
      stringsAsFactors = FALSE
    ),
    simulate_args = list(n = 20, grid_length = 12, include_scalar = FALSE),
    benchmark_args = list(
      methods = "selectboost",
      levels = "feature",
      selectboost_args = list(
        selector = "not_a_selector",
        B = 1,
        steps.seq = 0.5,
        c0lim = FALSE
      )
    ),
    seed = 901
  )

  expect_s3_class(study, "fda_selectboost_sensitivity_study")
  expect_true(all(c(
    "runtime_status", "n_failures", "n_warnings",
    "benchmark_user", "benchmark_system", "benchmark_elapsed",
    "setting_user", "setting_system", "setting_elapsed",
    "error_message"
  ) %in% names(study$metrics)))
  expect_true(any(study$metrics$runtime_status == "failed"))
  expect_true(any(study$metrics$n_failures > 0))
  expect_true(any(nzchar(study$metrics$error_message)))
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
    simulate_args = list(n = 35, grid_length = 20, representation = "bspline", scenario = "confounded_blocks"),
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
      noise_axis = c("snr", "noise_sd"),
      snr = c(1, NA),
      noise_sd = c(NA, 0.5),
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
  expect_true(all(c("association_method", "bandwidth", "confounding_strength", "active_region_scale", "local_correlation", "noise_axis", "snr", "noise_sd") %in% names(study$metrics)))
  expect_true(all(c("scenario", "association_method", "bandwidth", "noise_axis", "f1_mean") %in% names(performance)))
  expect_true(all(c("scenario", "association_method", "bandwidth", "noise_axis", "delta_mean", "win_rate") %in% names(advantage)))
  expect_true(all(c("localized_dense", "confounded_blocks") %in% unique(advantage$scenario)))
  expect_true(1 %in% unique(stats::na.omit(study$metrics$snr)))
  expect_true(0.5 %in% unique(stats::na.omit(study$metrics$noise_sd)))
})
