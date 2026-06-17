parse_cli_args <- function(args) {
  out <- list(
    output_dir = "",
    n_replicates = 1L,
    seed = 20260616L,
    quick = FALSE,
    methods = c("selectboost_fda", "plain_selectboost"),
    n_cores = 1L
  )

  i <- 1L
  while (i <= length(args)) {
    arg <- args[[i]]
    if (identical(arg, "--quick")) {
      out$quick <- TRUE
    } else if (grepl("^--output-dir=", arg)) {
      out$output_dir <- sub("^--output-dir=", "", arg)
    } else if (identical(arg, "--output-dir") && i < length(args)) {
      i <- i + 1L
      out$output_dir <- args[[i]]
    } else if (grepl("^--n-replicates=", arg)) {
      out$n_replicates <- as.integer(sub("^--n-replicates=", "", arg))
    } else if (identical(arg, "--n-replicates") && i < length(args)) {
      i <- i + 1L
      out$n_replicates <- as.integer(args[[i]])
    } else if (grepl("^--seed=", arg)) {
      out$seed <- as.integer(sub("^--seed=", "", arg))
    } else if (identical(arg, "--seed") && i < length(args)) {
      i <- i + 1L
      out$seed <- as.integer(args[[i]])
    } else if (grepl("^--methods=", arg)) {
      out$methods <- strsplit(sub("^--methods=", "", arg), ",", fixed = TRUE)[[1L]]
    } else if (identical(arg, "--methods") && i < length(args)) {
      i <- i + 1L
      out$methods <- strsplit(args[[i]], ",", fixed = TRUE)[[1L]]
    } else if (grepl("^--n-cores=", arg)) {
      out$n_cores <- as.integer(sub("^--n-cores=", "", arg))
    } else if (identical(arg, "--n-cores") && i < length(args)) {
      i <- i + 1L
      out$n_cores <- as.integer(args[[i]])
    }
    i <- i + 1L
  }

  out$methods <- trimws(out$methods)
  out
}

load_package_from_script <- function() {
  script_args <- commandArgs(trailingOnly = FALSE)
  script_path_arg <- grep("^--file=", script_args, value = TRUE)
  project_root <- if (length(script_path_arg) > 0L) {
    normalizePath(file.path(dirname(sub("^--file=", "", script_path_arg[1L])), ".."), mustWork = TRUE)
  } else {
    normalizePath(getwd(), mustWork = TRUE)
  }

  if (requireNamespace("pkgload", quietly = TRUE)) {
    pkgload::load_all(project_root, export_all = FALSE, helpers = FALSE, quiet = TRUE)
  } else {
    library(SelectBoost.FDA)
  }

  invisible(project_root)
}

write_yaml_like <- function(x, file) {
  lines <- unlist(lapply(names(x), function(name) {
    value <- x[[name]]
    if (length(value) > 1L) {
      c(paste0(name, ":"), paste0("  - ", value))
    } else {
      paste0(name, ": ", value)
    }
  }), use.names = FALSE)
  writeLines(lines, con = file, useBytes = TRUE)
}

bind_rows_fill <- function(dfs) {
  dfs <- Filter(function(x) !is.null(x) && nrow(x) > 0L, dfs)
  if (length(dfs) == 0L) {
    return(data.frame())
  }
  all_names <- unique(unlist(lapply(dfs, names), use.names = FALSE))
  dfs <- lapply(dfs, function(df) {
    missing <- setdiff(all_names, names(df))
    for (name in missing) {
      df[[name]] <- NA
    }
    df[all_names]
  })
  do.call(rbind, dfs)
}

method_names_for_existing_api <- function(methods) {
  mapped <- character()
  if ("selectboost_fda" %in% methods || "selectboost" %in% methods) {
    mapped <- c(mapped, "selectboost")
  }
  if ("plain_selectboost" %in% methods) {
    mapped <- c(mapped, "plain_selectboost")
  }
  if ("stability_lasso" %in% methods || "stability" %in% methods) {
    mapped <- c(mapped, "stability")
  }
  unique(mapped)
}

args <- parse_cli_args(commandArgs(trailingOnly = TRUE))
load_package_from_script()

if (!nzchar(args$output_dir)) {
  env_dir <- Sys.getenv("SELECTBOOST_FDA_BENCHMARK_DIR", unset = "")
  args$output_dir <- if (nzchar(env_dir)) {
    env_dir
  } else {
    file.path(tempdir(), "selectboost_fda_focused_benchmark")
  }
}
dir.create(args$output_dir, recursive = TRUE, showWarnings = FALSE)

methods <- method_names_for_existing_api(args$methods)
if (length(methods) == 0L) {
  stop("No supported methods were requested.", call. = FALSE)
}

quick <- isTRUE(args$quick)
simulate_grid <- if (quick) {
  data.frame(
    scenario = "localized_dense",
    confounding_strength = 0.8,
    active_region_scale = 0.7,
    local_correlation = 1.5,
    stringsAsFactors = FALSE
  )
} else {
  expand.grid(
    scenario = c("localized_dense", "confounded_blocks"),
    confounding_strength = c(0.6, 1.0),
    active_region_scale = c(0.8, 0.5),
    local_correlation = c(0, 2),
    stringsAsFactors = FALSE
  )
}

selectboost_grid <- if (quick) {
  data.frame(
    association_method = c("correlation", "hybrid"),
    bandwidth = c(NA, 4),
    stringsAsFactors = FALSE
  )
} else {
  data.frame(
    association_method = c("correlation", "neighborhood", "hybrid", "interval", "interval"),
    bandwidth = c(NA, 4, 4, 4, 8),
    stringsAsFactors = FALSE
  )
}

selectboost_steps <- if (quick) c(0.7, 0.4) else c(0.9, 0.7, 0.5, 0.3)
selectboost_reps <- if (quick) 2L else 4L
sim_n <- if (quick) 24L else 50L
grid_length <- if (quick) 16L else 30L

timing <- system.time({
  study <- run_selectboost_sensitivity_study(
    n_rep = args$n_replicates,
    simulate_grid = simulate_grid,
    selectboost_grid = selectboost_grid,
    simulate_args = list(
      n = sim_n,
      grid_length = grid_length,
      representation = "grid"
    ),
    benchmark_args = list(
      methods = methods,
      levels = c("feature", "group"),
      stability_args = list(
        selector = "lasso",
        B = if (quick) 4L else 8L,
        cutoff = 0.5,
        seed = args$seed
      ),
      selectboost_args = list(
        selector = "msgps",
        B = selectboost_reps,
        steps.seq = selectboost_steps,
        c0lim = FALSE
      ),
      plain_selectboost_args = list(
        selector = "msgps",
        B = selectboost_reps,
        steps.seq = selectboost_steps,
        c0lim = FALSE
      )
    ),
    seed = args$seed,
    keep_results = FALSE
  )
})

summary_by_setting <- as_benchmark_summary_data(study, select_c0 = "best")
feature_advantage <- if (all(c("selectboost", "plain_selectboost") %in% unique(study$metrics$method))) {
  summarise_benchmark_advantage(
    study,
    target = "selectboost",
    reference = "plain_selectboost",
    level = "feature",
    metric = "f1"
  )
} else {
  data.frame()
}
best_settings <- report_benchmark_table(study, top_n = 20L)
precision_recall_paths <- as_precision_recall_path_data(study)

sim_for_paths <- simulate_fda_scenario(
  n = sim_n,
  grid_length = grid_length,
  scenario = "localized_dense",
  confounding_strength = 0.8,
  active_region_scale = 0.7,
  local_correlation = 1.5,
  seed = args$seed + 1000L
)
surface_fit <- fit_perturbation_grid(
  sim_for_paths$design,
  q_grid = if (quick) c(0.5, 0.75) else c(0.5, 0.632, 0.8),
  c0_grid = selectboost_steps,
  B = if (quick) 1L else 3L,
  selectboost_B = 1L,
  selector = "msgps",
  association_method = "hybrid",
  bandwidth = 4,
  levels = c("feature", "group"),
  seed = args$seed + 2000L
)
surface_fit$truth <- sim_for_paths$truth
monotonicity_summary <- summarise_monotonicity(
  surface_fit,
  axis = "c0",
  direction = "nonincreasing",
  level = "feature"
)
surface_pr_paths <- precision_recall_curve_fda(
  surface_fit,
  truth = sim_for_paths,
  level = "feature",
  threshold_grid = seq(0, 1, by = 0.25)
)
precision_recall_paths <- bind_rows_fill(list(precision_recall_paths, surface_pr_paths))

runtime_summary <- data.frame(
  user = unname(timing[["user.self"]]),
  system = unname(timing[["sys.self"]]),
  elapsed = unname(timing[["elapsed"]]),
  n_failures = nrow(surface_fit$warnings),
  stringsAsFactors = FALSE
)

utils::write.csv(study$metrics, file.path(args$output_dir, "benchmark_raw_metrics.csv"), row.names = FALSE)
utils::write.csv(summary_by_setting, file.path(args$output_dir, "benchmark_summary_by_setting.csv"), row.names = FALSE)
utils::write.csv(best_settings, file.path(args$output_dir, "benchmark_best_settings.csv"), row.names = FALSE)
utils::write.csv(precision_recall_paths, file.path(args$output_dir, "benchmark_precision_recall_paths.csv"), row.names = FALSE)
utils::write.csv(monotonicity_summary, file.path(args$output_dir, "benchmark_monotonicity_summary.csv"), row.names = FALSE)
utils::write.csv(runtime_summary, file.path(args$output_dir, "benchmark_runtime_summary.csv"), row.names = FALSE)
utils::write.csv(feature_advantage, file.path(args$output_dir, "benchmark_feature_advantage.csv"), row.names = FALSE)
saveRDS(
  list(
    study = study,
    surface_fit = surface_fit,
    summary_by_setting = summary_by_setting,
    best_settings = best_settings,
    precision_recall_paths = precision_recall_paths,
    monotonicity_summary = monotonicity_summary,
    runtime_summary = runtime_summary,
    args = args
  ),
  file.path(args$output_dir, "benchmark_results.rds"),
  version = 2
)

writeLines(capture.output(utils::sessionInfo()), file.path(args$output_dir, "session_info.txt"), useBytes = TRUE)
write_yaml_like(
  list(
    quick = quick,
    output_dir = args$output_dir,
    n_replicates = args$n_replicates,
    seed = args$seed,
    methods = args$methods,
    n_cores = args$n_cores,
    sim_n = sim_n,
    grid_length = grid_length,
    selectboost_steps = selectboost_steps
  ),
  file.path(args$output_dir, "config.yml")
)

cat("Saved benchmark artifacts to:\n")
cat("  ", args$output_dir, "\n", sep = "")
cat("Best settings:\n")
print(utils::head(best_settings, 10L), row.names = FALSE)
