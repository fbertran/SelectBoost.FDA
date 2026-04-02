script_args <- commandArgs(trailingOnly = FALSE)
script_path <- sub("^--file=", "", script_args[grepl("^--file=", script_args)][1])
project_root <- normalizePath(file.path(dirname(script_path), ".."), mustWork = TRUE)
setwd(project_root)

if (requireNamespace("pkgload", quietly = TRUE)) {
  pkgload::load_all(project_root, export_all = FALSE, helpers = FALSE, quiet = TRUE)
} else {
  library(SelectBoost.FDA)
}

output_dir <- file.path(project_root, "inst", "extdata", "benchmarks")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

study_settings <- list(
  n_rep = 3L,
  simulate_grid = expand.grid(
    scenario = c("localized_dense", "confounded_blocks"),
    confounding_strength = c(0.6, 1.0),
    active_region_scale = c(0.8, 0.5),
    local_correlation = c(0, 2),
    stringsAsFactors = FALSE
  ),
  selectboost_grid = data.frame(
    association_method = c("correlation", "neighborhood", "hybrid", "interval", "interval"),
    bandwidth = c(NA, 4, 4, 4, 8),
    stringsAsFactors = FALSE
  ),
  simulate_args = list(
    n = 50,
    grid_length = 30,
    representation = "grid"
  ),
  benchmark_args = list(
    methods = c("selectboost", "plain_selectboost"),
    levels = c("feature", "group"),
    selectboost_args = list(
      selector = "lasso",
      B = 4,
      steps.seq = c(0.9, 0.7, 0.5, 0.3),
      c0lim = FALSE
    ),
    plain_selectboost_args = list(
      selector = "lasso",
      B = 4,
      steps.seq = c(0.9, 0.7, 0.5, 0.3),
      c0lim = FALSE
    )
  ),
  seed = 20260402L
)

study <- do.call(run_selectboost_sensitivity_study, study_settings)

feature_performance <- summarise_benchmark_performance(
  study,
  level = "feature",
  metric = "f1"
)

feature_advantage <- summarise_benchmark_advantage(
  study,
  target = "selectboost",
  reference = "plain_selectboost",
  level = "feature",
  metric = "f1"
)

group_advantage <- summarise_benchmark_advantage(
  study,
  target = "selectboost",
  reference = "plain_selectboost",
  level = "group",
  metric = "f1"
)

setting_cols <- intersect(
  c(
    "scenario", "representation", "family",
    "confounding_strength", "active_region_scale", "local_correlation",
    "association_method", "bandwidth"
  ),
  names(feature_advantage)
)

selectboost_perf <- feature_performance[
  feature_performance$method == "selectboost",
  c(setting_cols, "f1_mean", "f1_sd"),
  drop = FALSE
]
names(selectboost_perf)[names(selectboost_perf) == "f1_mean"] <- "selectboost_f1_mean"
names(selectboost_perf)[names(selectboost_perf) == "f1_sd"] <- "selectboost_f1_sd"

plain_perf <- feature_performance[
  feature_performance$method == "plain_selectboost",
  c(setting_cols, "f1_mean", "f1_sd"),
  drop = FALSE
]
names(plain_perf)[names(plain_perf) == "f1_mean"] <- "plain_selectboost_f1_mean"
names(plain_perf)[names(plain_perf) == "f1_sd"] <- "plain_selectboost_f1_sd"

top_feature_settings <- merge(
  feature_advantage,
  selectboost_perf,
  by = setting_cols,
  all.x = TRUE,
  sort = FALSE
)
top_feature_settings <- merge(
  top_feature_settings,
  plain_perf,
  by = setting_cols,
  all.x = TRUE,
  sort = FALSE
)
top_feature_settings <- top_feature_settings[
  order(
    -top_feature_settings$delta_mean,
    -top_feature_settings$win_rate,
    -top_feature_settings$selectboost_f1_mean
  ),
  c(
    setting_cols,
    "delta_mean", "delta_sd", "win_rate",
    "selectboost_f1_mean", "selectboost_f1_sd",
    "plain_selectboost_f1_mean", "plain_selectboost_f1_sd"
  ),
  drop = FALSE
]

write.csv(
  study$summary_table,
  file = file.path(output_dir, "selectboost_sensitivity_summary.csv"),
  row.names = FALSE
)
write.csv(
  feature_performance,
  file = file.path(output_dir, "selectboost_sensitivity_feature_performance.csv"),
  row.names = FALSE
)
write.csv(
  feature_advantage,
  file = file.path(output_dir, "selectboost_sensitivity_feature_advantage.csv"),
  row.names = FALSE
)
write.csv(
  group_advantage,
  file = file.path(output_dir, "selectboost_sensitivity_group_advantage.csv"),
  row.names = FALSE
)
write.csv(
  top_feature_settings,
  file = file.path(output_dir, "selectboost_sensitivity_top_settings.csv"),
  row.names = FALSE
)

saveRDS(
  list(
    study = study,
    feature_performance = feature_performance,
    feature_advantage = feature_advantage,
    group_advantage = group_advantage,
    top_feature_settings = top_feature_settings,
    study_settings = study_settings
  ),
  file = file.path(output_dir, "selectboost_sensitivity_study.rds"),
  version = 2
)

cat("Saved benchmark artifacts to:\n")
cat("  ", output_dir, "\n", sep = "")
cat("Top feature settings:\n")
print(utils::head(top_feature_settings, 10), row.names = FALSE)
