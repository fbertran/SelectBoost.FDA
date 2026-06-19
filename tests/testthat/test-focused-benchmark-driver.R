focused_benchmark_script <- function() {
  candidates <- c(
    file.path(getwd(), "tools", "run_focused_benchmark.R"),
    file.path(getwd(), "..", "tools", "run_focused_benchmark.R"),
    file.path(getwd(), "..", "..", "tools", "run_focused_benchmark.R")
  )
  candidates <- candidates[file.exists(candidates)]
  if (length(candidates) == 0L) {
    skip("Focused benchmark driver is not available in installed-package checks.")
  }
  normalizePath(candidates[1L], mustWork = TRUE)
}

test_that("focused benchmark driver writes quick artifacts to tempdir", {
  skip_on_cran()

  output_dir <- tempfile("selectboost-benchmark-")
  script <- focused_benchmark_script()
  result <- system2(
    file.path(R.home("bin"), "Rscript"),
    c(
      script,
      "--quick",
      "--n-replicates=1",
      "--seed=101",
      "--checkpoint-every=1",
      paste0("--output-dir=", output_dir)
    ),
    stdout = TRUE,
    stderr = TRUE
  )

  expect_equal(attr(result, "status") %||% 0, 0)
  expected <- c(
    "benchmark_config_baseline.yml",
    "progress.tsv",
    "benchmark_raw_metrics_checkpoint.csv",
    "benchmark_raw_metrics.csv",
    "benchmark_summary_by_setting.csv",
    "benchmark_best_settings.csv",
    "paired_gain_summary.csv",
    "paired_gain_bootstrap_ci.csv",
    "assessment_top_positive_settings.csv",
    "assessment_negative_gain_settings.csv",
    "assessment_all_setting_summary.csv",
    "assessment_failure_modes.csv",
    "assessment_surface_summary.csv",
    "assessment_monotonicity_summary.csv",
    "assessment_precision_recall_paths.csv",
    "assessment_best_thresholds.csv",
    "association_diagnostics.csv",
    "association_group_size_summary.csv",
    "assessment_association_comparison_table.csv",
    "method_comparison_summary.csv",
    "method_comparison_runtime.csv",
    "assessment_method_comparison_table.csv",
    "runtime_by_setting.csv",
    "runtime_by_method.csv",
    "benchmark_precision_recall_paths.csv",
    "benchmark_monotonicity_summary.csv",
    "benchmark_runtime_summary.csv",
    "benchmark_runtime_by_size_resolution.csv",
    "benchmark_scenario_summary.csv",
    "benchmark_size_resolution_summary.csv",
    "benchmark_noise_summary.csv",
    "benchmark_noise_f1_gain_panel.csv",
    "benchmark_representation_summary.csv",
    "assessment_representation_table.csv",
    "run_metadata.yml",
    "COMPLETED",
    "session_info.txt",
    "config.yml"
  )
  expect_true(all(file.exists(file.path(output_dir, expected))))
  expect_true(file.exists(file.path(output_dir, "checkpoints", "benchmark_raw_metrics_rep001.csv")))
  expect_true(file.exists(file.path(output_dir, "checkpoints", "benchmark_raw_metrics_latest.csv")))
  expect_false(file.exists(file.path(output_dir, "RUNNING")))

  required_columns <- c(
    "benchmark_name", "baseline_name", "package_version", "git_commit", "seed", "rng_backend",
    "replicate", "method", "scenario", "representation", "n", "grid_length",
    "noise_axis", "snr", "noise_sd", "association_method", "bandwidth",
    "selector", "B", "steps.seq"
  )
  metrics <- utils::read.csv(file.path(output_dir, "benchmark_raw_metrics.csv"))
  expect_true(all(c(required_columns, "level", "f1") %in% names(metrics)))
  expect_true(all(metrics$benchmark_name == "baseline_focused_benchmark_2026"))
  expect_true(all(metrics$baseline_name == metrics$benchmark_name))
  expect_true("effective_variance_snr" %in% names(metrics))
  expect_true(all(metrics$seed == 101))
  expect_true(all(metrics$rng_backend == "base_r_deterministic_vmf_shim"))
  expect_true(all(c("simulation_seed", "benchmark_seed") %in% names(metrics)))
  expect_true(all(c("simulation_elapsed", "benchmark_elapsed", "setting_elapsed") %in% names(metrics)))
  expect_true(all(metrics$n == 24))
  expect_true(all(metrics$grid_length == 16))
  expect_true(all(metrics$noise_axis == "default"))
  expect_true(all(is.na(metrics$snr)))
  expect_true(all(is.na(metrics$noise_sd)))
  expect_true(all(c("grid", "bspline", "fpca") %in% unique(metrics$representation)))
  expect_true(all(c("feature", "group", "basis") %in% unique(metrics$level)))

  progress <- utils::read.delim(file.path(output_dir, "progress.tsv"), check.names = FALSE)
  expect_true(all(c("timestamp", "event", "completed_runs", "total_runs", "percent_complete") %in% names(progress)))
  expect_true(all(c("checkpoint_file", "checkpoint_rows") %in% names(progress)))
  expect_true(all(c("noise_axis", "snr", "noise_sd") %in% names(progress)))
  expect_true(all(c(
    "runtime_status", "n_warnings", "n_failures",
    "simulation_user", "simulation_system", "benchmark_user",
    "benchmark_system", "setting_user", "setting_system",
    "result_size_mb"
  ) %in% names(progress)))
  expect_true(all(c("study_start", "setting_complete", "replicate_complete", "study_complete") %in% progress$event))
  expect_equal(utils::tail(progress$event, 1), "study_complete")
  expect_equal(suppressWarnings(as.numeric(utils::tail(progress$percent_complete, 1))), 100)

  checkpoint <- utils::read.csv(file.path(output_dir, "benchmark_raw_metrics_checkpoint.csv"), check.names = FALSE)
  replicate_checkpoint <- utils::read.csv(
    file.path(output_dir, "checkpoints", "benchmark_raw_metrics_rep001.csv"),
    check.names = FALSE
  )
  latest_checkpoint <- utils::read.csv(
    file.path(output_dir, "checkpoints", "benchmark_raw_metrics_latest.csv"),
    check.names = FALSE
  )
  setting_checkpoints <- list.files(
    file.path(output_dir, "checkpoints"),
    pattern = "^benchmark_raw_metrics_setting[0-9]{6}[.]csv$",
    full.names = TRUE
  )
  expect_identical(names(checkpoint), names(metrics))
  expect_identical(names(replicate_checkpoint), names(metrics))
  expect_identical(names(latest_checkpoint), names(metrics))
  expect_equal(nrow(checkpoint), nrow(metrics))
  expect_equal(nrow(replicate_checkpoint), nrow(metrics))
  expect_equal(length(setting_checkpoints), length(unique(metrics$setting_index)))

  summary <- utils::read.csv(file.path(output_dir, "benchmark_summary_by_setting.csv"))
  best <- utils::read.csv(file.path(output_dir, "benchmark_best_settings.csv"))
  summary_n1 <- utils::read.csv(file.path(output_dir, "benchmark_summary_n1.csv"))
  paired_gain <- utils::read.csv(file.path(output_dir, "paired_gain_summary.csv"))
  paired_gain_ci <- utils::read.csv(file.path(output_dir, "paired_gain_bootstrap_ci.csv"))
  assessment_top_positive <- utils::read.csv(file.path(output_dir, "assessment_top_positive_settings.csv"))
  assessment_negative <- utils::read.csv(file.path(output_dir, "assessment_negative_gain_settings.csv"))
  assessment_all <- utils::read.csv(file.path(output_dir, "assessment_all_setting_summary.csv"))
  assessment_failures <- utils::read.csv(file.path(output_dir, "assessment_failure_modes.csv"))
  assessment_surface <- utils::read.csv(file.path(output_dir, "assessment_surface_summary.csv"))
  assessment_monotonicity <- utils::read.csv(file.path(output_dir, "assessment_monotonicity_summary.csv"))
  assessment_pr <- utils::read.csv(file.path(output_dir, "assessment_precision_recall_paths.csv"))
  assessment_thresholds <- utils::read.csv(file.path(output_dir, "assessment_best_thresholds.csv"))
  association_diagnostics <- utils::read.csv(file.path(output_dir, "association_diagnostics.csv"))
  association_groups <- utils::read.csv(file.path(output_dir, "association_group_size_summary.csv"))
  assessment_association <- utils::read.csv(file.path(output_dir, "assessment_association_comparison_table.csv"))
  method_comparison <- utils::read.csv(file.path(output_dir, "method_comparison_summary.csv"))
  method_runtime <- utils::read.csv(file.path(output_dir, "method_comparison_runtime.csv"))
  assessment_method <- utils::read.csv(file.path(output_dir, "assessment_method_comparison_table.csv"))
  runtime_by_setting <- utils::read.csv(file.path(output_dir, "runtime_by_setting.csv"))
  runtime_by_method <- utils::read.csv(file.path(output_dir, "runtime_by_method.csv"))
  runtime <- utils::read.csv(file.path(output_dir, "benchmark_runtime_summary.csv"))
  runtime_size <- utils::read.csv(file.path(output_dir, "benchmark_runtime_by_size_resolution.csv"))
  scenario_summary <- utils::read.csv(file.path(output_dir, "benchmark_scenario_summary.csv"))
  size_summary <- utils::read.csv(file.path(output_dir, "benchmark_size_resolution_summary.csv"))
  noise_summary <- utils::read.csv(file.path(output_dir, "benchmark_noise_summary.csv"))
  noise_panel <- utils::read.csv(file.path(output_dir, "benchmark_noise_f1_gain_panel.csv"))
  representation_summary <- utils::read.csv(file.path(output_dir, "benchmark_representation_summary.csv"))
  assessment_table <- utils::read.csv(file.path(output_dir, "assessment_representation_table.csv"))
  expect_true(all(required_columns %in% names(summary)))
  expect_true(all(required_columns %in% names(best)))
  expect_true(all(required_columns %in% names(summary_n1)))
  expect_true(all(required_columns %in% names(paired_gain)))
  expect_true(all(required_columns %in% names(paired_gain_ci)))
  expect_true(all(required_columns %in% names(assessment_top_positive)))
  expect_true(all(required_columns %in% names(assessment_negative)))
  expect_true(all(required_columns %in% names(assessment_all)))
  expect_true(all(required_columns %in% names(assessment_failures)))
  expect_true(all(required_columns %in% names(assessment_surface)))
  expect_true(all(required_columns %in% names(assessment_monotonicity)))
  expect_true(all(required_columns %in% names(assessment_pr)))
  expect_true(all(required_columns %in% names(assessment_thresholds)))
  expect_true(all(required_columns %in% names(association_diagnostics)))
  expect_true(all(required_columns %in% names(association_groups)))
  expect_true(all(required_columns %in% names(assessment_association)))
  expect_true(all(required_columns %in% names(method_comparison)))
  expect_true(all(required_columns %in% names(method_runtime)))
  expect_true(all(required_columns %in% names(assessment_method)))
  expect_true(all(required_columns %in% names(runtime_by_setting)))
  expect_true(all(required_columns %in% names(runtime_by_method)))
  expect_true(all(required_columns %in% names(runtime)))
  expect_true(all(c(required_columns, "benchmark_elapsed_mean", "setting_elapsed_mean") %in% names(runtime_size)))
  expect_true(all(c(required_columns, "f1_mean", "fp_mean", "selection_rate_mean") %in% names(scenario_summary)))
  expect_true(all(c(required_columns, "f1_mean", "selection_rate_mean") %in% names(size_summary)))
  expect_true(all(c(required_columns, "f1_mean", "selection_rate_mean") %in% names(noise_summary)))
  expect_true(all(c(required_columns, "f1_gain_mean", "f1_gain_se", "win_rate_mean") %in% names(noise_panel)))
  expect_true(all(required_columns %in% names(representation_summary)))
  expect_true(all(required_columns %in% names(assessment_table)))
  expect_true(all(c("f1_mean", "f1_sd", "f1_se") %in% names(summary_n1)))
  paired_uncertainty_columns <- c(
    "paired_gain_mean", "paired_gain_sd", "paired_gain_se",
    "bootstrap_ci_lower", "bootstrap_ci_upper",
    "win_rate", "n_complete_method_pairs", "n_valid_pairs",
    "n_invalid_metric_pairs", "has_method_failures"
  )
  expect_true(all(paired_uncertainty_columns %in% names(paired_gain)))
  expect_true(all(paired_uncertainty_columns %in% names(paired_gain_ci)))
  expect_true(all(paired_gain$n_complete_method_pairs == 1))
  expect_true(all(paired_gain$n_valid_pairs %in% c(0, 1)))
  expect_false(any(paired_gain$has_method_failures))
  finite_ci <- !is.na(paired_gain$paired_gain_mean)
  expect_equal(paired_gain$bootstrap_ci_lower[finite_ci], paired_gain$paired_gain_mean[finite_ci])
  expect_equal(paired_gain$bootstrap_ci_upper[finite_ci], paired_gain$paired_gain_mean[finite_ci])
  expect_true(all(c("assessment_rank", "paired_gain_mean", "win_rate") %in% names(assessment_top_positive)))
  expect_true(all(c("assessment_rank", "paired_gain_mean", "win_rate") %in% names(assessment_negative)))
  expect_true(all(c("summary_scope", "median_gain", "iqr_gain", "fraction_positive", "interpretation_rule") %in% names(assessment_all)))
  expect_true(all(c("failure_mode", "assessment_note", "paired_gain_mean") %in% names(assessment_failures)))
  expect_true(all(c("surface_scenario_type", "q", "c0", "mean_selection", "n_selected") %in% names(assessment_surface)))
  expect_true(all(c(
    "surface_design_source", "surface_inherits_main_n",
    "surface_inherits_main_grid_length", "surface_inherits_main_noise"
  ) %in% names(assessment_surface)))
  expect_true(all(c("surface_scenario_type", "axis", "fraction_monotone", "expected_direction") %in% names(assessment_monotonicity)))
  expect_true(all(c("surface_scenario_type", "q", "c0", "threshold", "precision", "recall", "f1") %in% names(assessment_pr)))
  expect_true(all(c("surface_scenario_type", "threshold_type", "threshold", "precision", "recall", "f1") %in% names(assessment_thresholds)))
  expect_true(all(c(
    "sparsity", "mean_association", "median_association",
    "within_block_mass", "cross_block_mass", "local_mass", "nonlocal_mass",
    "effective_degree_mean", "within_blocks"
  ) %in% names(association_diagnostics)))
  expect_true(all(c(
    "c0", "n_induced_groups", "group_size_min", "group_size_median",
    "group_size_mean", "group_size_max", "singleton_fraction",
    "group_size_distribution"
  ) %in% names(association_groups)))
  expect_true(all(c(
    "association_method", "sparsity_mean", "within_block_mass_mean",
    "cross_block_mass_mean", "effective_degree_mean_mean", "assessment_note"
  ) %in% names(assessment_association)))
  method_labels <- c(
    "plain_selectboost",
    "selectboost_fda_lasso",
    "selectboost_fda_group_lasso",
    "selectboost_fda_sparse_group_lasso",
    "stability_lasso",
    "stability_group_lasso",
    "stability_sparse_group_lasso"
  )
  expect_setequal(unique(assessment_method$method), method_labels)
  expect_true(all(c(
    "perturbation_type", "base_selector", "selector_package",
    "method_available", "n_completed_fits", "n_failed_fits",
    "n_skipped_fits", "n_warnings", "n_failures",
    "runtime_user_mean", "runtime_system_mean", "runtime_elapsed_mean",
    "memory_mb_mean", "memory_mb_max", "assessment_label"
  ) %in% names(assessment_method)))
  expect_true(all(c(
    "perturbation_type", "base_selector", "selector_package",
    "method_available", "method_status", "method_user", "method_system",
    "method_elapsed", "n_warnings", "n_failures", "fit_object_size_mb",
    "error_message"
  ) %in% names(method_runtime)))
  expect_true(all(method_runtime$method_status %in% c("completed", "skipped", "failed")))
  expect_true(any(method_runtime$method == "plain_selectboost" & method_runtime$method_status == "completed"))
  expect_true(all(c("plain_selectboost", "fda_selectboost", "stability_selection") %in% unique(assessment_method$perturbation_type)))
  expect_true(all(c("msgps", "lasso", "group_lasso", "sparse_group_lasso") %in% unique(assessment_method$base_selector)))
  if (!requireNamespace("glmnet", quietly = TRUE)) {
    expect_true(any(
      method_runtime$method %in% c("selectboost_fda_lasso", "stability_lasso") &
        method_runtime$method_status == "skipped"
    ))
  }
  if (!requireNamespace("grpreg", quietly = TRUE)) {
    expect_true(any(
      method_runtime$method %in% c("selectboost_fda_group_lasso", "stability_group_lasso") &
        method_runtime$method_status == "skipped"
    ))
  }
  if (!requireNamespace("SGL", quietly = TRUE)) {
    expect_true(any(
      method_runtime$method %in% c("selectboost_fda_sparse_group_lasso", "stability_sparse_group_lasso") &
        method_runtime$method_status == "skipped"
    ))
  }
  runtime_setting_columns <- c(
    "runtime_source", "runtime_status", "n_runtime_rows",
    "n_failures", "n_warnings", "simulation_user", "simulation_system",
    "simulation_elapsed", "benchmark_user", "benchmark_system",
    "benchmark_elapsed", "setting_user", "setting_system",
    "setting_elapsed", "n_selected_features_mean",
    "n_selected_features_max", "memory_mb"
  )
  runtime_method_columns <- c(
    "runtime_source", "perturbation_type", "base_selector",
    "selector_package", "n_settings", "n_completed", "n_failed",
    "n_skipped", "n_failures", "n_warnings", "elapsed_mean",
    "elapsed_total", "user_mean", "user_total", "system_mean",
    "system_total", "n_selected_features_mean", "memory_mb_mean"
  )
  expect_true(all(runtime_setting_columns %in% names(runtime_by_setting)))
  expect_true(all(runtime_method_columns %in% names(runtime_by_method)))
  expect_true(all(runtime_by_setting$runtime_status %in% c("completed", "failed")))
  expect_true(all(runtime_by_setting$n_failures >= 0))
  expect_true(all(runtime_by_setting$n_warnings >= 0))
  expect_true(all(runtime_by_setting$setting_elapsed >= 0))
  expect_true(any(runtime_by_method$runtime_source == "main_benchmark"))
  expect_true(any(runtime_by_method$runtime_source == "method_comparison"))
  expect_true(all(runtime_by_method$n_failed >= 0))
  expect_true(all(runtime_by_method$n_warnings >= 0))
  expect_true(all(c("n_failures", "n_warnings", "memory_mb_mean", "n_selected_features_mean") %in% names(runtime)))
  expect_true(any(assessment_all$summary_scope == "overall"))
  expect_true(any(grepl("best-settings table", assessment_all$interpretation_rule)))
  if (nrow(assessment_negative) > 0L) {
    expect_true(all(assessment_negative$paired_gain_mean < 0))
  }
  if (nrow(assessment_failures) > 0L) {
    expect_true(all(assessment_failures$paired_gain_mean < 0))
  }
  representative_surface_scenarios <- c(
    "localized_dense", "confounded_blocks", "smooth_sparse",
    "basis_block_signal", "fpca_low_rank_signal", "null_signal",
    "mislocalized_signal"
  )
  expect_setequal(unique(assessment_surface$surface_scenario_type), representative_surface_scenarios)
  expect_true(all(c("c0", "q") %in% unique(assessment_monotonicity$axis)))
  expect_true(any(assessment_thresholds$threshold_type == "best_f1"))
  expect_true(all(c("fixed_0.5", "fixed_0.75", "fixed_0.9") %in% unique(assessment_thresholds$threshold_type)))
  expect_true(all(assessment_surface$method == "selectboost_surface"))
  expect_true(all(assessment_surface$B == 1))
  expect_true(all(assessment_surface$steps.seq == "0.7;0.4"))
  expect_true(all(abs(association_diagnostics$cross_block_mass[association_diagnostics$within_blocks]) < 1e-12))
  expect_true(all(c(0.7, 0.4) %in% association_groups$c0))
  expect_true(all(association_groups$n_induced_groups >= 1))
  join_cols <- c(
    "scenario", "representation", "n", "grid_length", "noise_axis",
    "association_method", "bandwidth"
  )
  benchmark_settings <- unique(metrics[metrics$method == "selectboost", join_cols, drop = FALSE])
  diagnostic_settings <- unique(association_diagnostics[, join_cols, drop = FALSE])
  expect_true(nrow(merge(diagnostic_settings, benchmark_settings, by = join_cols)) > 0)
  expect_true(all(c("representation_label", "selectboost_f1_mean", "plain_selectboost_f1_mean", "delta_mean") %in% names(assessment_table)))
  expect_true(all(c("grid", "bspline", "fpca") %in% unique(representation_summary$representation)))
  expect_true(all(c("grid", "bspline", "fpca") %in% unique(assessment_table$representation)))
  expect_false(any(is.na(metrics$selector)))
  expect_false(any(is.na(metrics$B)))
  expect_false(any(is.na(runtime$steps.seq)))
  expect_true(all(c(24) %in% unique(metrics$n)))
  expect_true(all(c(16) %in% unique(metrics$grid_length)))

  config <- readLines(file.path(output_dir, "benchmark_config_baseline.yml"), warn = FALSE)
  expect_true(any(grepl("^baseline_name: baseline_focused_benchmark_2026$", config)))
  expect_true(any(grepl("^benchmark_name: baseline_focused_benchmark_2026$", config)))
  expect_true(any(grepl("^  - progress.tsv$", config)))
  expect_true(any(grepl("^  - benchmark_raw_metrics_checkpoint.csv$", config)))
  expect_true(any(grepl("^  - checkpoints/benchmark_raw_metrics_latest.csv$", config)))
  expect_true(any(grepl("^  - run_metadata.yml$", config)))
  expect_true(any(grepl("^  - COMPLETED$", config)))
  expect_true(any(grepl("^  - benchmark_size_resolution_summary.csv$", config)))
  expect_true(any(grepl("^  - benchmark_runtime_by_size_resolution.csv$", config)))
  expect_true(any(grepl("^  - paired_gain_bootstrap_ci.csv$", config)))
  expect_true(any(grepl("^  - assessment_top_positive_settings.csv$", config)))
  expect_true(any(grepl("^  - assessment_negative_gain_settings.csv$", config)))
  expect_true(any(grepl("^  - assessment_all_setting_summary.csv$", config)))
  expect_true(any(grepl("^  - assessment_failure_modes.csv$", config)))
  expect_true(any(grepl("^  - assessment_surface_summary.csv$", config)))
  expect_true(any(grepl("^  - assessment_monotonicity_summary.csv$", config)))
  expect_true(any(grepl("^  - assessment_precision_recall_paths.csv$", config)))
  expect_true(any(grepl("^  - assessment_best_thresholds.csv$", config)))
  expect_true(any(grepl("^  - association_diagnostics.csv$", config)))
  expect_true(any(grepl("^  - association_group_size_summary.csv$", config)))
  expect_true(any(grepl("^  - assessment_association_comparison_table.csv$", config)))
  expect_true(any(grepl("^  - method_comparison_summary.csv$", config)))
  expect_true(any(grepl("^  - method_comparison_runtime.csv$", config)))
  expect_true(any(grepl("^  - assessment_method_comparison_table.csv$", config)))
  expect_true(any(grepl("^  - runtime_by_setting.csv$", config)))
  expect_true(any(grepl("^  - runtime_by_method.csv$", config)))
  expect_true(any(grepl("^  - benchmark_noise_summary.csv$", config)))
  expect_true(any(grepl("^  - benchmark_noise_f1_gain_panel.csv$", config)))
  expect_true(any(grepl("^run_profile: quick$", config)))
  expect_true(any(grepl("^rng_backend: base_r_deterministic_vmf_shim$", config)))
  expect_true(any(grepl("^interface_args:$", config)))
  expect_true(any(grepl("^  scenario_grid:$", config)))
  expect_true(any(grepl("^  q_grid:$", config)))
  expect_true(any(grepl("^  c0_grid:$", config)))
  expect_true(any(grepl("^  association_grid:$", config)))
  expect_true(any(grepl("^  bandwidth_grid:$", config)))
  expect_true(any(grepl("^  assessment_summary: true$", config)))
  expect_true(any(grepl("^  save_surfaces: true$", config)))
  expect_true(any(grepl("^  save_association_diagnostics: true$", config)))
  expect_true(any(grepl("^  bootstrap_reps:", config)))
  expect_true(any(grepl("^  checkpoint_every: 1$", config)))
  expect_true(any(grepl("^  representation_grid:$", config)))
  expect_true(any(grepl("^  snr_grid:", config)))
  expect_true(any(grepl("^  noise_sd_grid:", config)))
  expect_true(any(grepl("^simulate_grid:", config)))
  expect_true(any(grepl("^selectboost_grid:", config)))
  expect_true(any(grepl("^paired_gain_args:", config)))
  expect_true(any(grepl("^association_diagnostic_args:", config)))
  expect_true(any(grepl("^method_comparison_args:", config)))
  expect_true(any(grepl("^assessment_surface_args:", config)))

  run_metadata <- readLines(file.path(output_dir, "run_metadata.yml"), warn = FALSE)
  expect_true(any(grepl("^run_id:", run_metadata)))
  expect_true(any(grepl("^checkpoint_every: 1$", run_metadata)))
  expect_true(any(grepl("^resume: false$", run_metadata)))

  rerun <- suppressWarnings(system2(
    file.path(R.home("bin"), "Rscript"),
    c(
      script,
      "--quick",
      "--n-replicates=1",
      "--seed=101",
      paste0("--output-dir=", output_dir)
    ),
    stdout = TRUE,
    stderr = TRUE
  ))
  expect_true((attr(rerun, "status") %||% 0) != 0)
  expect_true(any(grepl("completed benchmark run", rerun)))
})

test_that("focused benchmark driver protects active runs and resume preserves checkpoint files", {
  skip_on_cran()

  output_dir <- tempfile("selectboost-benchmark-resume-")
  dir.create(file.path(output_dir, "checkpoints"), recursive = TRUE, showWarnings = FALSE)
  writeLines("run_id: previous\npid: 1\nstart_time: old", file.path(output_dir, "RUNNING"))
  writeLines("sentinel\tvalue\nbefore\t1", file.path(output_dir, "progress.tsv"))
  writeLines("sentinel", file.path(output_dir, "checkpoints", "manual_checkpoint.csv"))

  script <- focused_benchmark_script()
  blocked <- suppressWarnings(system2(
    file.path(R.home("bin"), "Rscript"),
    c(
      script,
      "--quick",
      "--n-replicates=1",
      "--seed=101",
      paste0("--output-dir=", output_dir)
    ),
    stdout = TRUE,
    stderr = TRUE
  ))
  expect_true((attr(blocked, "status") %||% 0) != 0)
  expect_true(any(grepl("active or interrupted benchmark run", blocked)))
  expect_true(file.exists(file.path(output_dir, "progress.tsv")))
  expect_true(file.exists(file.path(output_dir, "checkpoints", "manual_checkpoint.csv")))

  resumed <- system2(
    file.path(R.home("bin"), "Rscript"),
    c(
      script,
      "--quick",
      "--n-replicates=1",
      "--seed=101",
      "--representation-grid=grid",
      "--checkpoint-every=1",
      "--resume",
      paste0("--output-dir=", output_dir)
    ),
    stdout = TRUE,
    stderr = TRUE
  )
  expect_equal(attr(resumed, "status") %||% 0, 0)
  expect_true(any(grepl("does not skip previously completed settings yet", resumed)))
  expect_true(file.exists(file.path(output_dir, "checkpoints", "manual_checkpoint.csv")))
  expect_true(file.exists(file.path(output_dir, "COMPLETED")))
  expect_false(file.exists(file.path(output_dir, "RUNNING")))
})

test_that("focused benchmark driver accepts phase 13 campaign grids", {
  skip_on_cran()

  output_dir <- tempfile("selectboost-benchmark-interface-")
  script <- focused_benchmark_script()
  result <- system2(
    file.path(R.home("bin"), "Rscript"),
    c(
      script,
      "--quick",
      "--n-replicates=1",
      "--seed=101",
      "--representation-grid=grid",
      "--scenario-grid=smooth_sparse",
      "--n-grid=24",
      "--grid-length-grid=12",
      "--association-grid=correlation,hybrid",
      "--bandwidth-grid=3",
      "--q-grid=0.4,0.7",
      "--c0-grid=0.8,0.6",
      "--checkpoint-every",
      "2",
      "--assessment-summary",
      "--save-surfaces",
      "--surface-use-main-settings",
      "--save-association-diagnostics",
      "--bootstrap-reps=50",
      paste0("--output-dir=", output_dir)
    ),
    stdout = TRUE,
    stderr = TRUE
  )

  expect_equal(attr(result, "status") %||% 0, 0)
  metrics <- utils::read.csv(file.path(output_dir, "benchmark_raw_metrics.csv"))
  expect_setequal(unique(metrics$scenario), "smooth_sparse")
  expect_setequal(unique(metrics$representation), "grid")
  expect_setequal(unique(metrics$association_method), c("correlation", "hybrid"))
  expect_setequal(stats::na.omit(unique(metrics$bandwidth)), 3)
  expect_true(all(metrics$steps.seq == "0.8;0.6"))

  surface <- utils::read.csv(file.path(output_dir, "assessment_surface_summary.csv"))
  expect_setequal(unique(surface$surface_scenario_type), "smooth_sparse")
  expect_setequal(unique(surface$q), c(0.4, 0.7))
  expect_setequal(unique(surface$c0), c(0.8, 0.6))
  expect_true(all(surface$surface_design_source == "main_grid_representative"))
  expect_true(all(surface$surface_inherits_main_n))
  expect_true(all(surface$surface_inherits_main_grid_length))
  expect_true(all(surface$surface_inherits_main_noise))

  association <- utils::read.csv(file.path(output_dir, "association_diagnostics.csv"))
  expect_setequal(unique(association$scenario), "smooth_sparse")
  expect_setequal(unique(association$association_method), c("correlation", "hybrid"))
  expect_setequal(stats::na.omit(unique(association$bandwidth)), 3)

  config <- readLines(file.path(output_dir, "benchmark_config_baseline.yml"), warn = FALSE)
  expect_true(any(grepl("^  bootstrap_reps: 50$", config)))
  expect_true(any(grepl("^  checkpoint_every: 2$", config)))
  expect_true(any(grepl("^  surface_use_main_settings: true$", config)))
  expect_true(any(grepl("^    - smooth_sparse$", config)))
  expect_true(any(grepl("^    - 0.4$", config)))
  expect_true(any(grepl("^    - 0.8$", config)))
  expect_true(any(grepl("^    - hybrid$", config)))
  expect_true(any(grepl("^    - 3$", config)))
})

test_that("focused benchmark driver accepts SNR and fixed-noise grids", {
  skip_on_cran()

  output_dir <- tempfile("selectboost-benchmark-noise-")
  script <- focused_benchmark_script()
  result <- system2(
    file.path(R.home("bin"), "Rscript"),
    c(
      script,
      "--quick",
      "--n-replicates=1",
      "--seed=101",
      "--representation-grid=grid",
      "--n-grid=24",
      "--grid-length-grid=12",
      "--snr-grid=0.5,1",
      "--noise-sd-grid=0.5",
      paste0("--output-dir=", output_dir)
    ),
    stdout = TRUE,
    stderr = TRUE
  )

  expect_equal(attr(result, "status") %||% 0, 0)
  metrics <- utils::read.csv(file.path(output_dir, "benchmark_raw_metrics.csv"))
  expect_setequal(unique(metrics$noise_axis), c("snr", "noise_sd"))
  expect_true(0.5 %in% unique(stats::na.omit(metrics$snr)))
  expect_true(1 %in% unique(stats::na.omit(metrics$snr)))
  expect_true(0.5 %in% unique(stats::na.omit(metrics$noise_sd)))

  noise_summary <- utils::read.csv(file.path(output_dir, "benchmark_noise_summary.csv"))
  noise_panel <- utils::read.csv(file.path(output_dir, "benchmark_noise_f1_gain_panel.csv"))
  paired_gain_ci <- utils::read.csv(file.path(output_dir, "paired_gain_bootstrap_ci.csv"))
  assessment_all <- utils::read.csv(file.path(output_dir, "assessment_all_setting_summary.csv"))
  expect_true(all(c("noise_axis", "snr", "noise_sd", "effective_snr", "effective_variance_snr", "f1_mean") %in% names(noise_summary)))
  expect_true(all(c("noise_axis", "snr", "noise_sd", "effective_snr", "effective_variance_snr", "f1_gain_mean") %in% names(noise_panel)))
  expect_true(all(c("bootstrap_ci_lower", "bootstrap_ci_upper", "n_valid_pairs") %in% names(paired_gain_ci)))
  expect_true(all(c("summary_scope", "median_gain", "fraction_positive") %in% names(assessment_all)))
  expect_true(0.5 %in% unique(stats::na.omit(noise_summary$snr)))
  expect_true("noise_sd" %in% unique(noise_panel$noise_axis))

  config <- readLines(file.path(output_dir, "benchmark_config_baseline.yml"), warn = FALSE)
  expect_true(any(grepl("^  snr_grid:$", config)))
  expect_true(any(grepl("^    - 0.5$", config)))
  expect_true(any(grepl("^  noise_sd_grid:$", config)))
})

test_that("focused benchmark driver accepts explicit size-resolution grids", {
  skip_on_cran()

  output_dir <- tempfile("selectboost-benchmark-size-")
  script <- focused_benchmark_script()
  result <- system2(
    file.path(R.home("bin"), "Rscript"),
    c(
      script,
      "--quick",
      "--n-replicates=1",
      "--seed=101",
      "--representation-grid=grid",
      "--n-grid=24,28",
      "--grid-length-grid=12,16",
      paste0("--output-dir=", output_dir)
    ),
    stdout = TRUE,
    stderr = TRUE
  )

  expect_equal(attr(result, "status") %||% 0, 0)
  metrics <- utils::read.csv(file.path(output_dir, "benchmark_raw_metrics.csv"))
  expect_setequal(unique(metrics$n), c(24, 28))
  expect_setequal(unique(metrics$grid_length), c(12, 16))

  size_summary <- utils::read.csv(file.path(output_dir, "benchmark_size_resolution_summary.csv"))
  runtime_size <- utils::read.csv(file.path(output_dir, "benchmark_runtime_by_size_resolution.csv"))
  expect_true(all(c(24, 28) %in% unique(size_summary$n)))
  expect_true(all(c(12, 16) %in% unique(size_summary$grid_length)))
  expect_true(all(c(24, 28) %in% unique(runtime_size$n)))
  expect_true(all(c(12, 16) %in% unique(runtime_size$grid_length)))
  expect_true(all(!is.na(runtime_size$benchmark_elapsed_mean)))
})

test_that("focused benchmark driver is reproducible for the same quick seed", {
  skip_on_cran()

  output_a <- tempfile("selectboost-benchmark-repro-a-")
  output_b <- tempfile("selectboost-benchmark-repro-b-")
  script <- focused_benchmark_script()

  common_args <- c("--quick", "--n-replicates=1", "--seed=101", "--representation-grid=grid")
  result_a <- system2(
    file.path(R.home("bin"), "Rscript"),
    c(script, common_args, paste0("--output-dir=", output_a)),
    stdout = TRUE,
    stderr = TRUE
  )
  result_b <- system2(
    file.path(R.home("bin"), "Rscript"),
    c(script, common_args, paste0("--output-dir=", output_b)),
    stdout = TRUE,
    stderr = TRUE
  )

  expect_equal(attr(result_a, "status") %||% 0, 0)
  expect_equal(attr(result_b, "status") %||% 0, 0)

  comparable <- c(
    "benchmark_raw_metrics.csv",
    "benchmark_summary_by_setting.csv",
    "benchmark_summary_n1.csv",
    "benchmark_best_settings.csv",
    "benchmark_feature_advantage.csv",
    "paired_gain_summary.csv",
    "paired_gain_bootstrap_ci.csv",
    "assessment_top_positive_settings.csv",
    "assessment_negative_gain_settings.csv",
    "assessment_all_setting_summary.csv",
    "assessment_failure_modes.csv",
    "assessment_surface_summary.csv",
    "assessment_monotonicity_summary.csv",
    "assessment_precision_recall_paths.csv",
    "assessment_best_thresholds.csv",
    "association_diagnostics.csv",
    "association_group_size_summary.csv",
    "assessment_association_comparison_table.csv",
    "method_comparison_summary.csv",
    "method_comparison_runtime.csv",
    "assessment_method_comparison_table.csv",
    "runtime_by_setting.csv",
    "runtime_by_method.csv",
    "benchmark_noise_summary.csv",
    "benchmark_noise_f1_gain_panel.csv"
  )
  for (file in comparable) {
    a <- utils::read.csv(file.path(output_a, file), check.names = FALSE)
    b <- utils::read.csv(file.path(output_b, file), check.names = FALSE)
    volatile <- intersect(c(
      "simulation_elapsed", "benchmark_elapsed", "setting_elapsed",
      "simulation_user", "simulation_system", "benchmark_user",
      "benchmark_system", "setting_user", "setting_system",
      "method_user", "method_system", "method_elapsed",
      "runtime_user_mean", "runtime_system_mean", "runtime_elapsed_mean",
      "elapsed_mean", "elapsed_sd", "elapsed_se", "elapsed_total",
      "user_mean", "user_total", "system_mean", "system_total"
    ), names(a))
    if (length(volatile) > 0L) {
      expect_true(all(a[volatile] >= 0))
      expect_true(all(b[volatile] >= 0))
      a[volatile] <- NULL
      b[volatile] <- NULL
    }
    expect_identical(a, b, info = file)
  }
})
