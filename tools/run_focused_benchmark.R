parse_cli_args <- function(args) {
  out <- list(
    output_dir = "",
    n_replicates = 1L,
    seed = 20260616L,
    quick = FALSE,
    profile = "custom",
    methods = c("selectboost_fda", "plain_selectboost"),
    representation_grid = c("grid", "bspline", "fpca"),
    scenario_grid = NULL,
    n_grid = NULL,
    grid_length_grid = NULL,
    snr_grid = NULL,
    noise_sd_grid = NULL,
    q_grid = NULL,
    c0_grid = NULL,
    association_grid = NULL,
    bandwidth_grid = NULL,
    assessment_summary = TRUE,
    save_surfaces = TRUE,
    save_association_diagnostics = TRUE,
    bootstrap_replicates = 2000L,
    checkpoint_every = 100L,
    resume = FALSE,
    surface_use_main_settings = FALSE,
    n_cores = 1L,
    deterministic_rng = TRUE,
    n_replicates_explicit = FALSE
  )

  i <- 1L
  while (i <= length(args)) {
    arg <- args[[i]]
    if (identical(arg, "--quick")) {
      out$quick <- TRUE
      out$profile <- "quick"
    } else if (identical(arg, "--medium")) {
      out$quick <- FALSE
      if (!isTRUE(out$n_replicates_explicit)) {
        out$n_replicates <- 30L
      }
      out$profile <- "medium"
    } else if (identical(arg, "--final") || identical(arg, "--assessment-final")) {
      out$quick <- FALSE
      if (!isTRUE(out$n_replicates_explicit)) {
        out$n_replicates <- 50L
      }
      out$profile <- "final"
    } else if (grepl("^--output-dir=", arg)) {
      out$output_dir <- sub("^--output-dir=", "", arg)
    } else if (identical(arg, "--output-dir") && i < length(args)) {
      i <- i + 1L
      out$output_dir <- args[[i]]
    } else if (grepl("^--n-replicates=", arg)) {
      out$n_replicates <- as.integer(sub("^--n-replicates=", "", arg))
      out$n_replicates_explicit <- TRUE
    } else if (identical(arg, "--n-replicates") && i < length(args)) {
      i <- i + 1L
      out$n_replicates <- as.integer(args[[i]])
      out$n_replicates_explicit <- TRUE
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
    } else if (grepl("^--representation-grid=", arg)) {
      out$representation_grid <- strsplit(sub("^--representation-grid=", "", arg), ",", fixed = TRUE)[[1L]]
    } else if (identical(arg, "--representation-grid") && i < length(args)) {
      i <- i + 1L
      out$representation_grid <- strsplit(args[[i]], ",", fixed = TRUE)[[1L]]
    } else if (grepl("^--scenario-grid=", arg)) {
      out$scenario_grid <- strsplit(sub("^--scenario-grid=", "", arg), ",", fixed = TRUE)[[1L]]
    } else if (identical(arg, "--scenario-grid") && i < length(args)) {
      i <- i + 1L
      out$scenario_grid <- strsplit(args[[i]], ",", fixed = TRUE)[[1L]]
    } else if (grepl("^--n-grid=", arg)) {
      out$n_grid <- strsplit(sub("^--n-grid=", "", arg), ",", fixed = TRUE)[[1L]]
    } else if (identical(arg, "--n-grid") && i < length(args)) {
      i <- i + 1L
      out$n_grid <- strsplit(args[[i]], ",", fixed = TRUE)[[1L]]
    } else if (grepl("^--grid-length-grid=", arg)) {
      out$grid_length_grid <- strsplit(sub("^--grid-length-grid=", "", arg), ",", fixed = TRUE)[[1L]]
    } else if (identical(arg, "--grid-length-grid") && i < length(args)) {
      i <- i + 1L
      out$grid_length_grid <- strsplit(args[[i]], ",", fixed = TRUE)[[1L]]
    } else if (grepl("^--snr-grid=", arg)) {
      out$snr_grid <- strsplit(sub("^--snr-grid=", "", arg), ",", fixed = TRUE)[[1L]]
    } else if (identical(arg, "--snr-grid") && i < length(args)) {
      i <- i + 1L
      out$snr_grid <- strsplit(args[[i]], ",", fixed = TRUE)[[1L]]
    } else if (grepl("^--noise-sd-grid=", arg)) {
      out$noise_sd_grid <- strsplit(sub("^--noise-sd-grid=", "", arg), ",", fixed = TRUE)[[1L]]
    } else if (identical(arg, "--noise-sd-grid") && i < length(args)) {
      i <- i + 1L
      out$noise_sd_grid <- strsplit(args[[i]], ",", fixed = TRUE)[[1L]]
    } else if (grepl("^--q-grid=", arg)) {
      out$q_grid <- strsplit(sub("^--q-grid=", "", arg), ",", fixed = TRUE)[[1L]]
    } else if (identical(arg, "--q-grid") && i < length(args)) {
      i <- i + 1L
      out$q_grid <- strsplit(args[[i]], ",", fixed = TRUE)[[1L]]
    } else if (grepl("^--c0-grid=", arg)) {
      out$c0_grid <- strsplit(sub("^--c0-grid=", "", arg), ",", fixed = TRUE)[[1L]]
    } else if (identical(arg, "--c0-grid") && i < length(args)) {
      i <- i + 1L
      out$c0_grid <- strsplit(args[[i]], ",", fixed = TRUE)[[1L]]
    } else if (grepl("^--association-grid=", arg)) {
      out$association_grid <- strsplit(sub("^--association-grid=", "", arg), ",", fixed = TRUE)[[1L]]
    } else if (identical(arg, "--association-grid") && i < length(args)) {
      i <- i + 1L
      out$association_grid <- strsplit(args[[i]], ",", fixed = TRUE)[[1L]]
    } else if (grepl("^--bandwidth-grid=", arg)) {
      out$bandwidth_grid <- strsplit(sub("^--bandwidth-grid=", "", arg), ",", fixed = TRUE)[[1L]]
    } else if (identical(arg, "--bandwidth-grid") && i < length(args)) {
      i <- i + 1L
      out$bandwidth_grid <- strsplit(args[[i]], ",", fixed = TRUE)[[1L]]
    } else if (grepl("^--bootstrap-replicates=", arg)) {
      out$bootstrap_replicates <- as.integer(sub("^--bootstrap-replicates=", "", arg))
    } else if (grepl("^--bootstrap-reps=", arg)) {
      out$bootstrap_replicates <- as.integer(sub("^--bootstrap-reps=", "", arg))
    } else if ((identical(arg, "--bootstrap-replicates") || identical(arg, "--bootstrap-reps")) && i < length(args)) {
      i <- i + 1L
      out$bootstrap_replicates <- as.integer(args[[i]])
    } else if (grepl("^--checkpoint-every=", arg)) {
      out$checkpoint_every <- as.integer(sub("^--checkpoint-every=", "", arg))
    } else if (identical(arg, "--checkpoint-every") && i < length(args)) {
      i <- i + 1L
      out$checkpoint_every <- as.integer(args[[i]])
    } else if (grepl("^--n-cores=", arg)) {
      out$n_cores <- as.integer(sub("^--n-cores=", "", arg))
    } else if (identical(arg, "--n-cores") && i < length(args)) {
      i <- i + 1L
      out$n_cores <- as.integer(args[[i]])
    } else if (identical(arg, "--upstream-rfast-rvmf")) {
      out$deterministic_rng <- FALSE
    } else if (identical(arg, "--assessment-summary")) {
      out$assessment_summary <- TRUE
    } else if (identical(arg, "--no-assessment-summary")) {
      out$assessment_summary <- FALSE
    } else if (identical(arg, "--save-surfaces")) {
      out$save_surfaces <- TRUE
    } else if (identical(arg, "--no-save-surfaces")) {
      out$save_surfaces <- FALSE
    } else if (identical(arg, "--save-association-diagnostics")) {
      out$save_association_diagnostics <- TRUE
    } else if (identical(arg, "--no-save-association-diagnostics")) {
      out$save_association_diagnostics <- FALSE
    } else if (identical(arg, "--resume")) {
      out$resume <- TRUE
    } else if (identical(arg, "--surface-use-main-settings")) {
      out$surface_use_main_settings <- TRUE
    }
    i <- i + 1L
  }

  out$methods <- trimws(out$methods)
  out$representation_grid <- normalize_representation_grid(out$representation_grid)
  out$scenario_grid <- normalize_scenario_grid(out$scenario_grid, allow_null = TRUE)
  out$n_grid <- normalize_integer_grid(out$n_grid, "--n-grid")
  out$grid_length_grid <- normalize_integer_grid(out$grid_length_grid, "--grid-length-grid")
  out$snr_grid <- normalize_numeric_grid(out$snr_grid, "--snr-grid")
  out$noise_sd_grid <- normalize_numeric_grid(out$noise_sd_grid, "--noise-sd-grid")
  out$q_grid <- normalize_unit_grid(out$q_grid, "--q-grid", allow_one = TRUE)
  out$c0_grid <- normalize_unit_grid(out$c0_grid, "--c0-grid", allow_one = TRUE)
  out$association_grid <- normalize_association_grid(out$association_grid, allow_null = TRUE)
  out$bandwidth_grid <- normalize_bandwidth_grid(out$bandwidth_grid)
  if (length(out$bootstrap_replicates) != 1L || is.na(out$bootstrap_replicates) ||
      out$bootstrap_replicates < 1L) {
    stop("`--bootstrap-replicates` must be a positive integer.", call. = FALSE)
  }
  if (length(out$checkpoint_every) != 1L || is.na(out$checkpoint_every) ||
      out$checkpoint_every < 1L) {
    stop("`--checkpoint-every` must be a positive integer.", call. = FALSE)
  }
  out
}

normalize_representation_grid <- function(values) {
  values <- trimws(as.character(values))
  values <- values[nzchar(values)]
  values[values == "basis"] <- "bspline"
  allowed <- c("grid", "bspline", "fpca")
  unknown <- setdiff(values, allowed)
  if (length(values) == 0L || length(unknown) > 0L) {
    stop(sprintf(
      "`--representation-grid` must contain only: %s.",
      paste(allowed, collapse = ", ")
    ), call. = FALSE)
  }
  unique(values)
}

normalize_scenario_grid <- function(values, allow_null = FALSE) {
  if (is.null(values)) {
    if (isTRUE(allow_null)) {
      return(NULL)
    }
    values <- character()
  }
  values <- trimws(as.character(values))
  values <- values[nzchar(values)]
  allowed <- c(
    "localized_dense",
    "confounded_blocks",
    "smooth_sparse",
    "basis_block_signal",
    "fpca_low_rank_signal",
    "null_signal",
    "mislocalized_signal",
    "distributed_smooth"
  )
  unknown <- setdiff(values, allowed)
  if (length(values) == 0L || length(unknown) > 0L) {
    stop(sprintf(
      "`--scenario-grid` must contain only: %s.",
      paste(allowed, collapse = ", ")
    ), call. = FALSE)
  }
  unique(values)
}

normalize_integer_grid <- function(values, option) {
  if (is.null(values)) {
    return(NULL)
  }
  values <- trimws(as.character(values))
  values <- values[nzchar(values)]
  out <- suppressWarnings(as.integer(values))
  if (length(out) == 0L || any(is.na(out)) || any(out < 1L)) {
    stop(sprintf("`%s` must be a comma-separated list of positive integers.", option), call. = FALSE)
  }
  unique(out)
}

normalize_numeric_grid <- function(values, option) {
  if (is.null(values)) {
    return(NULL)
  }
  values <- trimws(as.character(values))
  values <- values[nzchar(values)]
  out <- suppressWarnings(as.numeric(values))
  if (length(out) == 0L || any(is.na(out)) || any(!is.finite(out)) || any(out <= 0)) {
    stop(sprintf("`%s` must be a comma-separated list of positive finite numbers.", option), call. = FALSE)
  }
  unique(out)
}

normalize_unit_grid <- function(values, option, allow_one = TRUE) {
  out <- normalize_numeric_grid(values, option)
  if (is.null(out)) {
    return(NULL)
  }
  upper_ok <- if (isTRUE(allow_one)) out <= 1 else out < 1
  if (any(!upper_ok)) {
    interval <- if (isTRUE(allow_one)) "(0, 1]" else "(0, 1)"
    stop(sprintf("`%s` values must be in %s.", option, interval), call. = FALSE)
  }
  unique(out)
}

normalize_association_grid <- function(values, allow_null = FALSE) {
  if (is.null(values)) {
    if (isTRUE(allow_null)) {
      return(NULL)
    }
    values <- character()
  }
  values <- trimws(as.character(values))
  values <- values[nzchar(values)]
  allowed <- c("correlation", "neighborhood", "hybrid", "interval")
  unknown <- setdiff(values, allowed)
  if (length(values) == 0L || length(unknown) > 0L) {
    stop(sprintf(
      "`--association-grid` must contain only: %s.",
      paste(allowed, collapse = ", ")
    ), call. = FALSE)
  }
  unique(values)
}

normalize_bandwidth_grid <- function(values) {
  if (is.null(values)) {
    return(NULL)
  }
  values <- trimws(as.character(values))
  values <- values[nzchar(values)]
  values[tolower(values) %in% c("na", "null", "none")] <- NA_character_
  out <- suppressWarnings(as.numeric(values))
  if (length(out) == 0L || any(!is.na(out) & (!is.finite(out) | out <= 0))) {
    stop("`--bandwidth-grid` must be a comma-separated list of positive numbers, with optional NA/null entries.", call. = FALSE)
  }
  unique(out)
}

baseline_name <- "baseline_focused_benchmark_2026"

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

detect_git_commit <- function(project_root) {
  git <- Sys.which("git")
  if (!nzchar(git)) {
    return(NA_character_)
  }

  commit <- tryCatch(
    system2(git, c("-C", project_root, "rev-parse", "HEAD"), stdout = TRUE, stderr = FALSE),
    error = function(e) character()
  )
  if (length(commit) == 0L || !nzchar(commit[1L])) {
    return(NA_character_)
  }
  commit[1L]
}

deterministic_rvmf <- function(n, mu, k, parallel = FALSE) {
  mu <- as.numeric(mu)
  d <- length(mu)
  if (d == 0L) {
    stop("`mu` must contain at least one value.", call. = FALSE)
  }

  norm_mu <- sqrt(sum(mu^2))
  if (!is.finite(norm_mu) || norm_mu == 0) {
    mu <- rep(0, d)
    mu[1L] <- 1
  } else {
    mu <- mu / norm_mu
  }

  k <- suppressWarnings(as.numeric(k[1L]))
  if (!is.finite(k) || k < 0) {
    k <- 0
  }

  unit_sphere <- function(n, d) {
    draws <- matrix(stats::rnorm(n * d), nrow = n, ncol = d)
    norms <- sqrt(rowSums(draws^2))
    invalid <- !is.finite(norms) | norms == 0
    while (any(invalid)) {
      draws[invalid, ] <- matrix(stats::rnorm(sum(invalid) * d), nrow = sum(invalid), ncol = d)
      norms <- sqrt(rowSums(draws^2))
      invalid <- !is.finite(norms) | norms == 0
    }
    sweep(draws, 1L, norms, "/")
  }

  if (d == 1L) {
    return(matrix(ifelse(stats::runif(n) < stats::plogis(2 * k * mu[1L]), 1, -1), ncol = 1L))
  }

  if (k < sqrt(.Machine$double.eps)) {
    draws <- unit_sphere(n, d)
  } else {
    b <- (-2 * k + sqrt(4 * k^2 + (d - 1)^2)) / (d - 1)
    x0 <- (1 - b) / (1 + b)
    c_const <- k * x0 + (d - 1) * log(1 - x0^2)
    draws <- matrix(NA_real_, nrow = n, ncol = d)

    for (i in seq_len(n)) {
      repeat {
        z <- stats::rbeta(1L, (d - 1) / 2, (d - 1) / 2)
        w <- (1 - (1 + b) * z) / (1 - (1 - b) * z)
        accept <- k * w + (d - 1) * log(1 - x0 * w) - c_const
        if (accept >= log(stats::runif(1L))) {
          break
        }
      }
      v <- unit_sphere(1L, d - 1L)
      draws[i, ] <- c(w, sqrt(pmax(0, 1 - w^2)) * as.numeric(v))
    }
  }

  e1 <- c(1, rep(0, d - 1L))
  if (sqrt(sum((mu - e1)^2)) < sqrt(.Machine$double.eps)) {
    return(draws)
  }
  if (sqrt(sum((mu + e1)^2)) < sqrt(.Machine$double.eps)) {
    draws[, 1L] <- -draws[, 1L]
    return(draws)
  }

  u <- e1 - mu
  u <- u / sqrt(sum(u^2))
  draws - 2 * tcrossprod(as.numeric(draws %*% u), u)
}

install_deterministic_selectboost_rng <- function(enabled = TRUE) {
  if (!isTRUE(enabled)) {
    return(function() invisible(FALSE))
  }
  if (!requireNamespace("SelectBoost", quietly = TRUE)) {
    return(function() invisible(FALSE))
  }

  imports_env <- parent.env(environment(SelectBoost:::boost.random))
  had_binding <- exists("rvmf", envir = imports_env, inherits = FALSE)
  old_value <- if (had_binding) get("rvmf", envir = imports_env, inherits = FALSE) else NULL
  was_locked <- had_binding && bindingIsLocked("rvmf", imports_env)

  if (was_locked) {
    unlockBinding("rvmf", imports_env)
  }
  assign("rvmf", deterministic_rvmf, envir = imports_env)
  lockBinding("rvmf", imports_env)

  function() {
    if (bindingIsLocked("rvmf", imports_env)) {
      unlockBinding("rvmf", imports_env)
    }
    if (had_binding) {
      assign("rvmf", old_value, envir = imports_env)
      if (was_locked) {
        lockBinding("rvmf", imports_env)
      }
    } else {
      rm("rvmf", envir = imports_env)
    }
    invisible(TRUE)
  }
}

yaml_scalar <- function(value) {
  if (length(value) == 0L || is.null(value) ||
      (length(value) == 1L && is.atomic(value) && is.na(value))) {
    return("null")
  }
  if (is.logical(value)) {
    return(if (isTRUE(value)) "true" else "false")
  }
  if (is.numeric(value)) {
    return(format(value, scientific = FALSE, trim = TRUE))
  }
  value <- as.character(value)
  if (!grepl("^[A-Za-z0-9_.:/+-]+$", value)) {
    value <- gsub("\"", "\\\\\"", value)
    return(paste0("\"", value, "\""))
  }
  value
}

yaml_vector_lines <- function(name, values) {
  if (length(values) == 0L) {
    return(paste0(name, ": []"))
  }
  c(paste0(name, ":"), paste0("  - ", vapply(values, yaml_scalar, character(1))))
}

yaml_nested_vector_lines <- function(name, values, indent = "  ") {
  if (length(values) == 0L) {
    return(paste0(indent, name, ": []"))
  }
  c(
    paste0(indent, name, ":"),
    paste0(indent, "  - ", vapply(values, yaml_scalar, character(1)))
  )
}

yaml_data_frame_lines <- function(name, data) {
  if (is.null(data) || nrow(data) == 0L) {
    return(paste0(name, ": []"))
  }

  lines <- paste0(name, ":")
  for (i in seq_len(nrow(data))) {
    row <- data[i, , drop = FALSE]
    first <- TRUE
    for (field in names(row)) {
      prefix <- if (first) "  - " else "    "
      lines <- c(lines, paste0(prefix, field, ": ", yaml_scalar(row[[field]][1L])))
      first <- FALSE
    }
  }
  lines
}

write_baseline_config <- function(file,
                                  baseline_name,
                                  args,
                                  package_version,
                                  git_commit,
                                  quick,
                                  methods,
                                  simulate_grid,
                                  selectboost_grid,
                                  sim_n,
                                  grid_length,
                                  representation_grid,
                                  n_grid,
                                  grid_length_grid,
                                  snr_grid,
                                  noise_sd_grid,
                                  selectboost_steps,
                                  selectboost_reps,
                                  stability_reps,
                                  method_comparison_reps,
                                  method_comparison_selectboost_reps,
                                  method_comparison_stability_reps,
                                  surface_q_grid,
                                  surface_c0_grid,
                                  surface_reps,
                                  surface_selectboost_reps,
                                  rng_backend,
                                  output_dir = NULL) {
  surface_scenarios <- filtered_surface_scenario_grid(
    scenario_grid = args$scenario_grid,
    representation_grid = representation_grid
  )$scenario
  lines <- c(
    paste0("benchmark_name: ", yaml_scalar(baseline_name)),
    paste0("baseline_name: ", yaml_scalar(baseline_name)),
    paste0("package_version: ", yaml_scalar(package_version)),
    paste0("git_commit: ", yaml_scalar(git_commit)),
    paste0("seed: ", yaml_scalar(args$seed)),
    paste0("n_replicates: ", yaml_scalar(args$n_replicates)),
    paste0("run_profile: ", yaml_scalar(args$profile)),
    paste0("quick: ", yaml_scalar(quick)),
    paste0("rng_backend: ", yaml_scalar(rng_backend)),
    paste0("output_dir: ", yaml_scalar(output_dir)),
    "interface_args:",
    yaml_nested_vector_lines("scenario_grid", if (is.null(args$scenario_grid)) unique(simulate_grid$scenario) else args$scenario_grid),
    yaml_nested_vector_lines("q_grid", if (is.null(args$q_grid)) surface_q_grid else args$q_grid),
    yaml_nested_vector_lines("c0_grid", if (is.null(args$c0_grid)) selectboost_steps else args$c0_grid),
    yaml_nested_vector_lines("association_grid", if (is.null(args$association_grid)) unique(selectboost_grid$association_method) else args$association_grid),
    yaml_nested_vector_lines("bandwidth_grid", if (is.null(args$bandwidth_grid)) unique(selectboost_grid$bandwidth) else args$bandwidth_grid),
    paste0("  assessment_summary: ", yaml_scalar(args$assessment_summary)),
    paste0("  save_surfaces: ", yaml_scalar(args$save_surfaces)),
    paste0("  save_association_diagnostics: ", yaml_scalar(args$save_association_diagnostics)),
    paste0("  bootstrap_reps: ", yaml_scalar(args$bootstrap_replicates)),
    paste0("  checkpoint_every: ", yaml_scalar(args$checkpoint_every)),
    paste0("  resume: ", yaml_scalar(args$resume)),
    paste0("  surface_use_main_settings: ", yaml_scalar(args$surface_use_main_settings)),
    yaml_vector_lines("requested_methods", args$methods),
    yaml_vector_lines("benchmark_methods", methods),
    "simulate_args:",
    paste0("  n: ", yaml_scalar(sim_n)),
    paste0("  grid_length: ", yaml_scalar(grid_length)),
    yaml_nested_vector_lines("representation_grid", representation_grid),
    yaml_nested_vector_lines("n_grid", n_grid),
    yaml_nested_vector_lines("grid_length_grid", grid_length_grid),
    yaml_nested_vector_lines("snr_grid", if (is.null(snr_grid)) numeric() else snr_grid),
    yaml_nested_vector_lines("noise_sd_grid", if (is.null(noise_sd_grid)) numeric() else noise_sd_grid),
    "  family: gaussian",
    yaml_data_frame_lines("simulate_grid", simulate_grid),
    yaml_data_frame_lines("selectboost_grid", selectboost_grid),
    "selectboost_args:",
    "  selector: msgps",
    paste0("  B: ", yaml_scalar(selectboost_reps)),
    yaml_nested_vector_lines("steps.seq", selectboost_steps),
    "  c0lim: false",
    "plain_selectboost_args:",
    "  selector: msgps",
    paste0("  B: ", yaml_scalar(selectboost_reps)),
    yaml_nested_vector_lines("steps.seq", selectboost_steps),
    "  c0lim: false",
    "stability_args:",
    "  selector: lasso",
    paste0("  B: ", yaml_scalar(stability_reps)),
    "  cutoff: 0.5",
    "paired_gain_args:",
    paste0("  bootstrap_replicates: ", yaml_scalar(args$bootstrap_replicates)),
    "  bootstrap_confidence: 0.95",
    "  bootstrap_method: deterministic_percentile",
    "association_diagnostic_args:",
    "  within_blocks: true",
    yaml_nested_vector_lines("c0_grid", selectboost_steps),
    "method_comparison_args:",
    paste0("  n_replicates: ", yaml_scalar(method_comparison_reps)),
    paste0("  selectboost_B: ", yaml_scalar(method_comparison_selectboost_reps)),
    paste0("  stability_B: ", yaml_scalar(method_comparison_stability_reps)),
    "  optional_backends:",
    "    glmnet: selectboost_fda_lasso,stability_lasso",
    "    grpreg: selectboost_fda_group_lasso,stability_group_lasso",
    "    SGL: selectboost_fda_sparse_group_lasso,stability_sparse_group_lasso",
    "assessment_surface_args:",
    yaml_nested_vector_lines("q_grid", surface_q_grid),
    yaml_nested_vector_lines("c0_grid", surface_c0_grid),
    paste0("  B: ", yaml_scalar(surface_reps)),
    paste0("  selectboost_B: ", yaml_scalar(surface_selectboost_reps)),
    paste0("  surface_use_main_settings: ", yaml_scalar(args$surface_use_main_settings)),
    "  selector: msgps",
    yaml_nested_vector_lines("representative_scenarios", surface_scenarios),
    "output_files:",
    "  - benchmark_config_baseline.yml",
    "  - progress.tsv",
    "  - benchmark_raw_metrics_checkpoint.csv",
    "  - checkpoints/benchmark_raw_metrics_repNNN.csv",
    "  - checkpoints/benchmark_raw_metrics_settingNNNNNN.csv",
    "  - checkpoints/benchmark_raw_metrics_latest.csv",
    "  - run_metadata.yml",
    "  - RUNNING",
    "  - COMPLETED",
    "  - benchmark_raw_metrics.csv",
    "  - benchmark_summary_by_setting.csv",
    paste0("  - benchmark_summary_n", args$n_replicates, ".csv"),
    if (args$n_replicates %in% c(50L, 100L)) "  - benchmark_summary_n50_or_n100.csv" else character(),
    "  - benchmark_best_settings.csv",
    "  - paired_gain_summary.csv",
    "  - paired_gain_bootstrap_ci.csv",
    "  - assessment_top_positive_settings.csv",
    "  - assessment_negative_gain_settings.csv",
    "  - assessment_all_setting_summary.csv",
    "  - assessment_failure_modes.csv",
    "  - assessment_surface_summary.csv",
    "  - assessment_monotonicity_summary.csv",
    "  - assessment_precision_recall_paths.csv",
    "  - assessment_best_thresholds.csv",
    "  - association_diagnostics.csv",
    "  - association_group_size_summary.csv",
    "  - assessment_association_comparison_table.csv",
    "  - method_comparison_summary.csv",
    "  - method_comparison_runtime.csv",
    "  - assessment_method_comparison_table.csv",
    "  - runtime_by_setting.csv",
    "  - runtime_by_method.csv",
    "  - benchmark_precision_recall_paths.csv",
    "  - benchmark_monotonicity_summary.csv",
    "  - benchmark_runtime_summary.csv",
    "  - benchmark_runtime_by_size_resolution.csv",
    "  - benchmark_representation_summary.csv",
    "  - benchmark_scenario_summary.csv",
    "  - benchmark_size_resolution_summary.csv",
    "  - benchmark_noise_summary.csv",
    "  - benchmark_noise_f1_gain_panel.csv",
    "  - assessment_representation_table.csv",
    "  - session_info.txt"
  )
  writeLines(lines, con = file, useBytes = TRUE)
}

make_run_id <- function() {
  paste0(
    "focused-benchmark-",
    format(Sys.time(), "%Y%m%dT%H%M%OS3"),
    "-pid",
    Sys.getpid()
  )
}

write_key_value_yaml <- function(file, values) {
  lines <- paste0(names(values), ": ", vapply(values, yaml_scalar, character(1)))
  writeLines(lines, con = file, useBytes = TRUE)
}

write_running_marker <- function(output_dir, run_id, start_time) {
  write_key_value_yaml(
    file.path(output_dir, "RUNNING"),
    list(
      run_id = run_id,
      pid = Sys.getpid(),
      start_time = format(start_time, "%Y-%m-%dT%H:%M:%OS3%z")
    )
  )
}

write_completed_marker <- function(output_dir, run_id, start_time, end_time) {
  write_key_value_yaml(
    file.path(output_dir, "COMPLETED"),
    list(
      run_id = run_id,
      pid = Sys.getpid(),
      start_time = format(start_time, "%Y-%m-%dT%H:%M:%OS3%z"),
      end_time = format(end_time, "%Y-%m-%dT%H:%M:%OS3%z")
    )
  )
}

write_run_metadata <- function(output_dir,
                               run_id,
                               start_time,
                               package_version,
                               git_commit,
                               args) {
  write_key_value_yaml(
    file.path(output_dir, "run_metadata.yml"),
    list(
      run_id = run_id,
      start_time = format(start_time, "%Y-%m-%dT%H:%M:%OS3%z"),
      pid = Sys.getpid(),
      hostname = Sys.info()[["nodename"]] %||% NA_character_,
      output_dir = normalizePath(output_dir, mustWork = FALSE),
      package_version = package_version,
      git_commit = git_commit,
      seed = args$seed,
      n_replicates = args$n_replicates,
      profile = args$profile,
      checkpoint_every = args$checkpoint_every,
      resume = args$resume
    )
  )
}

guard_run_markers <- function(output_dir, resume = FALSE) {
  running_file <- file.path(output_dir, "RUNNING")
  completed_file <- file.path(output_dir, "COMPLETED")
  if (file.exists(running_file) && !isTRUE(resume)) {
    stop(
      "Output directory appears to contain an active or interrupted benchmark run. ",
      "Use a different --output-dir, remove RUNNING manually, or use --resume.",
      call. = FALSE
    )
  }
  if (file.exists(completed_file) && !isTRUE(resume)) {
    stop(
      "Output directory appears to contain a completed benchmark run. ",
      "Use a different --output-dir, remove COMPLETED manually, or use --resume.",
      call. = FALSE
    )
  }
  if (isTRUE(resume)) {
    message("--resume preserves existing checkpoint files but does not skip previously completed settings yet.")
  }
  invisible(TRUE)
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

default_simulate_base_grid <- function(quick = FALSE) {
  if (isTRUE(quick)) {
    return(data.frame(
      scenario = "localized_dense",
      confounding_strength = 0.8,
      active_region_scale = 0.7,
      local_correlation = 1.5,
      stringsAsFactors = FALSE
    ))
  }

  rbind(
    expand.grid(
      scenario = c("localized_dense", "confounded_blocks"),
      confounding_strength = c(0.6, 1.0),
      active_region_scale = c(0.8, 0.5),
      local_correlation = c(0, 2),
      stringsAsFactors = FALSE
    ),
    data.frame(
      scenario = c(
        "smooth_sparse",
        "basis_block_signal",
        "fpca_low_rank_signal",
        "null_signal",
        "mislocalized_signal"
      ),
      confounding_strength = c(0.4, 0.3, 0.2, 0.0, 0.6),
      active_region_scale = c(0.6, 1.0, 1.0, 1.0, 0.5),
      local_correlation = c(2.0, 1.5, 1.0, 2.0, 2.0),
      stringsAsFactors = FALSE
    )
  )
}

apply_scenario_grid <- function(base_grid, scenario_grid) {
  if (is.null(scenario_grid)) {
    return(base_grid)
  }

  base_grid <- base_grid[base_grid$scenario %in% scenario_grid, , drop = FALSE]
  missing <- setdiff(scenario_grid, unique(base_grid$scenario))
  if (length(missing) > 0L) {
    defaults <- data.frame(
      scenario = missing,
      confounding_strength = 0.6,
      active_region_scale = 0.8,
      local_correlation = 1.5,
      stringsAsFactors = FALSE
    )
    defaults$confounding_strength[defaults$scenario == "null_signal"] <- 0
    defaults$confounding_strength[defaults$scenario == "fpca_low_rank_signal"] <- 0.2
    defaults$confounding_strength[defaults$scenario == "basis_block_signal"] <- 0.3
    defaults$confounding_strength[defaults$scenario == "smooth_sparse"] <- 0.4
    defaults$active_region_scale[defaults$scenario %in% c("confounded_blocks", "mislocalized_signal")] <- 0.5
    defaults$active_region_scale[defaults$scenario %in% c("basis_block_signal", "fpca_low_rank_signal", "null_signal")] <- 1.0
    defaults$local_correlation[defaults$scenario %in% c("confounded_blocks", "smooth_sparse", "null_signal", "mislocalized_signal")] <- 2.0
    defaults$local_correlation[defaults$scenario == "fpca_low_rank_signal"] <- 1.0
    base_grid <- rbind(base_grid, defaults)
  }

  base_grid[match(scenario_grid, base_grid$scenario), , drop = FALSE]
}

default_selectboost_grid <- function(quick = FALSE) {
  if (isTRUE(quick)) {
    return(data.frame(
      association_method = c("correlation", "hybrid"),
      bandwidth = c(NA, 4),
      stringsAsFactors = FALSE
    ))
  }

  data.frame(
    association_method = c("correlation", "neighborhood", "hybrid", "interval", "interval"),
    bandwidth = c(NA, 4, 4, 4, 8),
    stringsAsFactors = FALSE
  )
}

build_selectboost_grid_from_cli <- function(quick = FALSE,
                                            association_grid = NULL,
                                            bandwidth_grid = NULL) {
  if (is.null(association_grid) && is.null(bandwidth_grid)) {
    return(default_selectboost_grid(quick))
  }

  association_grid <- association_grid %||% unique(default_selectboost_grid(quick)$association_method)
  rows <- lapply(association_grid, function(method) {
    if (identical(method, "correlation")) {
      bandwidth_values <- NA_real_
    } else {
      bandwidth_values <- bandwidth_grid
      if (is.null(bandwidth_values) || all(is.na(bandwidth_values))) {
        bandwidth_values <- if (isTRUE(quick)) 4 else c(4, 8)
      }
      bandwidth_values <- bandwidth_values[!is.na(bandwidth_values)]
    }
    data.frame(
      association_method = method,
      bandwidth = bandwidth_values,
      stringsAsFactors = FALSE
    )
  })

  grid <- do.call(rbind, rows)
  rownames(grid) <- NULL
  unique(grid)
}

metadata_value <- function(value, n) {
  rep(value, length.out = n)
}

steps_label <- function(steps) {
  paste(as.character(steps), collapse = ";")
}

method_selector <- function(method) {
  ifelse(method %in% c("stability", "stability_lasso"), "lasso", "msgps")
}

method_B <- function(method, selectboost_reps, stability_reps) {
  ifelse(method %in% c("stability", "stability_lasso"), stability_reps, selectboost_reps)
}

method_steps <- function(method, selectboost_steps) {
  ifelse(
    method %in% c("selectboost", "plain_selectboost", "selectboost_vs_plain_selectboost", "all"),
    steps_label(selectboost_steps),
    NA_character_
  )
}

add_benchmark_metadata <- function(data,
                                   baseline_name,
                                   package_version,
                                   git_commit,
                                   seed,
                                   selectboost_reps,
                                   stability_reps,
                                   selectboost_steps,
                                   rng_backend = NA_character_,
                                   default_method = "all",
                                   default_scenario = "all",
                                   default_representation = "grid",
                                   default_n = "all",
                                   default_grid_length = "all",
                                   default_noise_axis = "default",
                                   default_snr = NA_real_,
                                   default_noise_sd = NA_real_,
                                   default_association = "all",
                                   default_bandwidth = NA_real_,
                                   default_replicate = NA_character_) {
  data <- as.data.frame(data, stringsAsFactors = FALSE)
  n <- nrow(data)

  if (!"replicate" %in% names(data)) {
    data$replicate <- metadata_value(default_replicate, n)
  }
  if (!"method" %in% names(data)) {
    data$method <- metadata_value(default_method, n)
  }
  if (!"scenario" %in% names(data)) {
    data$scenario <- metadata_value(default_scenario, n)
  }
  if (!"representation" %in% names(data)) {
    data$representation <- metadata_value(default_representation, n)
  }
  if (!"n" %in% names(data)) {
    data$n <- metadata_value(default_n, n)
  }
  if (!"grid_length" %in% names(data)) {
    data$grid_length <- metadata_value(default_grid_length, n)
  }
  if (!"noise_axis" %in% names(data)) {
    data$noise_axis <- metadata_value(default_noise_axis, n)
  }
  if (!"snr" %in% names(data)) {
    data$snr <- metadata_value(default_snr, n)
  }
  if (!"noise_sd" %in% names(data)) {
    data$noise_sd <- metadata_value(default_noise_sd, n)
  }
  if (!"association_method" %in% names(data)) {
    data$association_method <- metadata_value(default_association, n)
  }
  if (!"bandwidth" %in% names(data)) {
    data$bandwidth <- metadata_value(default_bandwidth, n)
  }

  data$benchmark_name <- metadata_value(baseline_name, n)
  data$baseline_name <- metadata_value(baseline_name, n)
  data$package_version <- metadata_value(package_version, n)
  data$git_commit <- metadata_value(git_commit, n)
  data$seed <- metadata_value(seed, n)
  data$rng_backend <- metadata_value(rng_backend, n)
  if (!"selector" %in% names(data) || all(is.na(data$selector))) {
    data$selector <- method_selector(data$method)
  }
  if (!"B" %in% names(data) || all(is.na(data[["B"]]))) {
    data[["B"]] <- method_B(data$method, selectboost_reps, stability_reps)
  }
  if (!"steps.seq" %in% names(data) || all(is.na(data[["steps.seq"]]))) {
    data[["steps.seq"]] <- method_steps(data$method, selectboost_steps)
  }

  first_cols <- c(
    "benchmark_name", "baseline_name", "package_version", "git_commit", "seed", "rng_backend",
    "replicate", "method", "scenario", "representation", "n", "grid_length",
    "noise_axis", "snr", "noise_sd", "association_method", "bandwidth",
    "selector", "B", "steps.seq"
  )
  data[, unique(c(first_cols, setdiff(names(data), first_cols))), drop = FALSE]
}

progress_value <- function(value, default = NA_character_) {
  if (is.null(value) || length(value) == 0L) {
    return(default)
  }
  if (length(value) > 1L) {
    value <- paste(as.character(value), collapse = ",")
  }
  if (length(value) == 1L && is.atomic(value) && is.na(value)) {
    return(default)
  }
  as.character(value)
}

progress_label <- function(info, collection, name, default = NA_character_) {
  labels <- info[[collection]]
  if (is.null(labels) || is.null(labels[[name]])) {
    return(default)
  }
  progress_value(labels[[name]], default = default)
}

append_tsv_row <- function(file, row) {
  row <- as.data.frame(row, stringsAsFactors = FALSE)
  file_exists <- file.exists(file)
  write.table(
    row,
    file = file,
    append = file_exists,
    sep = "\t",
    quote = TRUE,
    qmethod = "double",
    row.names = FALSE,
    col.names = !file_exists,
    na = ""
  )
}

append_csv_rows <- function(file, data) {
  data <- as.data.frame(data, stringsAsFactors = FALSE)
  if (nrow(data) == 0L) {
    return(invisible(FALSE))
  }
  file_exists <- file.exists(file)
  write.table(
    data,
    file = file,
    append = file_exists,
    sep = ",",
    quote = TRUE,
    qmethod = "double",
    row.names = FALSE,
    col.names = !file_exists,
    na = ""
  )
  invisible(TRUE)
}

prepare_progress_outputs <- function(output_dir, resume = FALSE) {
  checkpoints_dir <- file.path(output_dir, "checkpoints")
  dir.create(checkpoints_dir, recursive = TRUE, showWarnings = FALSE)
  if (!isTRUE(resume)) {
    unlink(file.path(output_dir, "progress.tsv"))
    unlink(file.path(output_dir, "benchmark_raw_metrics_checkpoint.csv"))
    unlink(file.path(output_dir, "COMPLETED"))
    unlink(Sys.glob(file.path(checkpoints_dir, "*.csv")))
  }

  list(
    progress_file = file.path(output_dir, "progress.tsv"),
    checkpoint_file = file.path(output_dir, "benchmark_raw_metrics_checkpoint.csv"),
    checkpoints_dir = checkpoints_dir
  )
}

make_progress_row <- function(event,
                              info,
                              start_time,
                              checkpoint_file = NA_character_,
                              rows = NA_integer_,
                              checkpoint_rows = NA_integer_) {
  now <- Sys.time()
  total_runs <- suppressWarnings(as.numeric(progress_value(info$total_runs, NA_character_)))
  completed_runs <- suppressWarnings(as.numeric(progress_value(info$completed_runs, NA_character_)))
  percent_complete <- if (is.finite(total_runs) && total_runs > 0) {
    round(100 * completed_runs / total_runs, 2)
  } else {
    NA_real_
  }

  data.frame(
    timestamp = format(now, "%Y-%m-%dT%H:%M:%OS3%z"),
    elapsed_seconds = round(as.numeric(difftime(now, start_time, units = "secs")), 3),
    event = event,
    replicate = progress_value(info$replicate),
    replicate_seed = progress_value(info$replicate_seed),
    simulate_index = progress_value(info$simulate_index),
    selectboost_index = progress_value(info$selectboost_index),
    completed_runs = progress_value(info$completed_runs),
    total_runs = progress_value(info$total_runs),
    percent_complete = percent_complete,
    scenario = progress_label(info, "simulate_labels", "scenario"),
    representation = progress_label(info, "simulate_labels", "representation"),
    n = progress_label(info, "simulate_labels", "n"),
    grid_length = progress_label(info, "simulate_labels", "grid_length"),
    noise_axis = progress_label(info, "simulate_labels", "noise_axis"),
    snr = progress_label(info, "simulate_labels", "snr"),
    noise_sd = progress_label(info, "simulate_labels", "noise_sd"),
    confounding_strength = progress_label(info, "simulate_labels", "confounding_strength"),
    active_region_scale = progress_label(info, "simulate_labels", "active_region_scale"),
    local_correlation = progress_label(info, "simulate_labels", "local_correlation"),
    association_method = progress_label(info, "selectboost_labels", "association_method"),
    bandwidth = progress_label(info, "selectboost_labels", "bandwidth"),
    simulation_seed = progress_value(info$simulation_seed),
    benchmark_seed = progress_value(info$benchmark_seed),
    runtime_status = progress_value(info$runtime_status),
    n_warnings = progress_value(info$n_warnings),
    n_failures = progress_value(info$n_failures),
    error_message = progress_value(info$error_message),
    simulation_user = progress_value(info$simulation_user),
    simulation_system = progress_value(info$simulation_system),
    simulation_elapsed = progress_value(info$simulation_elapsed),
    benchmark_user = progress_value(info$benchmark_user),
    benchmark_system = progress_value(info$benchmark_system),
    benchmark_elapsed = progress_value(info$benchmark_elapsed),
    setting_user = progress_value(info$setting_user),
    setting_system = progress_value(info$setting_system),
    setting_elapsed = progress_value(info$setting_elapsed),
    result_size_mb = progress_value(info$result_size_mb),
    rows = progress_value(rows),
    checkpoint_rows = progress_value(checkpoint_rows),
    checkpoint_file = progress_value(checkpoint_file),
    stringsAsFactors = FALSE
  )
}

make_focused_progress_callback <- function(output_dir,
                                           baseline_name,
                                           package_version,
                                           git_commit,
                                           seed,
                                           rng_backend,
                                           selectboost_reps,
                                           stability_reps,
                                           selectboost_steps,
                                           checkpoint_every = 100L,
                                           resume = FALSE) {
  outputs <- prepare_progress_outputs(output_dir, resume = resume)
  start_time <- Sys.time()
  appended_setting_indices <- integer()

  add_checkpoint_metadata <- function(metrics) {
    add_benchmark_metadata(
      metrics,
      baseline_name = baseline_name,
      package_version = package_version,
      git_commit = git_commit,
      seed = seed,
      selectboost_reps = selectboost_reps,
      stability_reps = stability_reps,
      selectboost_steps = selectboost_steps,
      rng_backend = rng_backend
    )
  }

  setting_index_from_info <- function(info, metrics = NULL) {
    if (!is.null(metrics) && "setting_index" %in% names(metrics)) {
      value <- suppressWarnings(as.integer(stats::na.omit(unique(metrics$setting_index))))
      if (length(value) > 0L && !is.na(value[1L])) {
        return(value[1L])
      }
    }
    value <- suppressWarnings(as.integer(info$completed_runs))
    if (length(value) == 0L || is.na(value)) NA_integer_ else value
  }

  write_latest_checkpoint <- function(metrics) {
    latest_file <- file.path(outputs$checkpoints_dir, "benchmark_raw_metrics_latest.csv")
    utils::write.csv(metrics, latest_file, row.names = FALSE)
    latest_file
  }

  function(event, ...) {
    info <- list(...)
    checkpoint_file <- NA_character_
    rows <- info$rows
    checkpoint_rows <- NA_integer_

    if (identical(event, "setting_complete")) {
      metrics <- info$metrics
      setting_index <- setting_index_from_info(info, metrics)
      should_checkpoint <- !is.na(setting_index) && setting_index %% checkpoint_every == 0L
      if (isTRUE(should_checkpoint) && !is.null(metrics) && nrow(metrics) > 0L) {
        metrics <- add_checkpoint_metadata(metrics)
        checkpoint_file <- file.path(
          outputs$checkpoints_dir,
          sprintf("benchmark_raw_metrics_setting%06d.csv", as.integer(setting_index))
        )
        utils::write.csv(metrics, checkpoint_file, row.names = FALSE)
        write_latest_checkpoint(metrics)
        append_csv_rows(outputs$checkpoint_file, metrics)
        appended_setting_indices <<- union(appended_setting_indices, as.integer(setting_index))
        checkpoint_rows <- nrow(metrics)
      }
    }

    if (identical(event, "replicate_complete")) {
      metrics <- info$metrics
      if (!is.null(metrics) && nrow(metrics) > 0L) {
        metrics <- add_checkpoint_metadata(metrics)
        checkpoint_file <- file.path(
          outputs$checkpoints_dir,
          sprintf("benchmark_raw_metrics_rep%03d.csv", as.integer(info$replicate))
        )
        utils::write.csv(metrics, checkpoint_file, row.names = FALSE)
        if ("setting_index" %in% names(metrics)) {
          setting_indices <- suppressWarnings(as.integer(metrics$setting_index))
          append_mask <- is.na(setting_indices) | !setting_indices %in% appended_setting_indices
          metrics_to_append <- metrics[append_mask, , drop = FALSE]
          appended_setting_indices <<- union(appended_setting_indices, stats::na.omit(unique(setting_indices)))
          latest_index <- suppressWarnings(max(setting_indices, na.rm = TRUE))
          if (is.finite(latest_index)) {
            write_latest_checkpoint(metrics[setting_indices == latest_index, , drop = FALSE])
          }
        } else {
          metrics_to_append <- metrics
          write_latest_checkpoint(utils::tail(metrics, 1L))
        }
        append_csv_rows(outputs$checkpoint_file, metrics_to_append)
        rows <- nrow(metrics)
        checkpoint_rows <- nrow(metrics)
      }
    }

    append_tsv_row(
      outputs$progress_file,
      make_progress_row(
        event = event,
        info = info,
        start_time = start_time,
        checkpoint_file = checkpoint_file,
        rows = rows,
        checkpoint_rows = checkpoint_rows
      )
    )
    invisible(NULL)
  }
}

add_standard_errors <- function(data) {
  data <- as.data.frame(data, stringsAsFactors = FALSE)
  if (!"n_rep" %in% names(data)) {
    return(data)
  }

  sd_cols <- setdiff(grep("_sd$", names(data), value = TRUE), c("noise_sd", "effective_noise_sd"))
  for (sd_col in sd_cols) {
    se_col <- sub("_sd$", "_se", sd_col)
    if (se_col %in% names(data)) {
      next
    }
    data[[se_col]] <- data[[sd_col]] / sqrt(pmax(data$n_rep, 1))
  }
  data
}

make_best_settings <- function(feature_advantage, feature_performance) {
  if (nrow(feature_advantage) == 0L || nrow(feature_performance) == 0L) {
    return(data.frame())
  }

  setting_cols <- intersect(
    c(
        "scenario", "representation", "family",
        "n", "grid_length", "noise_axis", "snr", "noise_sd",
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

  out <- merge(feature_advantage, selectboost_perf, by = setting_cols, all.x = TRUE, sort = FALSE)
  out <- merge(out, plain_perf, by = setting_cols, all.x = TRUE, sort = FALSE)
  out$method <- "selectboost_vs_plain_selectboost"
  out <- out[
    order(
      -out$delta_mean,
      -out$win_rate,
      -out$selectboost_f1_mean
    ),
    ,
    drop = FALSE
  ]
  utils::head(out, 20L)
}

deterministic_bootstrap_mean_ci <- function(values,
                                            bootstrap_replicates = 2000L,
                                            confidence = 0.95,
                                            offset = 0L) {
  values <- as.numeric(values)
  values <- values[!is.na(values)]
  n <- length(values)
  if (n == 0L) {
    return(c(lower = NA_real_, upper = NA_real_))
  }
  if (n == 1L) {
    return(c(lower = values[1L], upper = values[1L]))
  }

  bootstrap_replicates <- as.integer(bootstrap_replicates)
  draws <- seq_len(bootstrap_replicates * n)
  mixed <- (draws * 1103515245 + 12345 + as.numeric(offset) * 104729) %% 2147483647
  idx <- as.integer(mixed %% n) + 1L
  means <- rowMeans(matrix(values[idx], nrow = bootstrap_replicates, ncol = n))
  alpha <- (1 - confidence) / 2
  stats::quantile(means, probs = c(alpha, 1 - alpha), names = FALSE, type = 6, na.rm = TRUE)
}

build_paired_gain_differences <- function(study,
                                          levels = c("feature", "group"),
                                          metric = "f1",
                                          target = "selectboost",
                                          reference = "plain_selectboost") {
  metrics <- as.data.frame(study$metrics, stringsAsFactors = FALSE)
  if (nrow(metrics) == 0L || !"replicate" %in% names(metrics)) {
    return(data.frame())
  }
  best_metric_rows_fn <- get("best_metric_rows", envir = asNamespace("SelectBoost.FDA"))

  rows <- lapply(levels, function(level) {
    best <- best_metric_rows_fn(
      metrics = metrics,
      level = level,
      metric = metric,
      optimize = "max",
      select_c0 = "best"
    )
    if (nrow(best) == 0L) {
      return(data.frame())
    }

    setting_cols <- intersect(
      c(
        "scenario", "representation", "family",
        "n", "grid_length", "noise_axis", "snr", "noise_sd",
        "confounding_strength", "active_region_scale", "local_correlation",
        "association_method", "bandwidth", "level", "width"
      ),
      names(best)
    )
    pair_cols <- c(setting_cols, "replicate")
    split_keys <- interaction_key(best[pair_cols])

    do.call(rbind, lapply(split(seq_len(nrow(best)), split_keys), function(idx) {
      part <- best[idx, , drop = FALSE]
      target_rows <- part[part$method == target, , drop = FALSE]
      reference_rows <- part[part$method == reference, , drop = FALSE]
      out <- part[1, pair_cols, drop = FALSE]
      if ("effective_snr" %in% names(part)) {
        out$effective_snr <- mean_or_na(part$effective_snr)
      }
      if ("effective_variance_snr" %in% names(part)) {
        out$effective_variance_snr <- mean_or_na(part$effective_variance_snr)
      }
      out$target <- target
      out$reference <- reference
      out$metric <- metric
      out$target_row_count <- nrow(target_rows)
      out$reference_row_count <- nrow(reference_rows)
      out$target_value <- if (nrow(target_rows) > 0L) target_rows[[metric]][1L] else NA_real_
      out$reference_value <- if (nrow(reference_rows) > 0L) reference_rows[[metric]][1L] else NA_real_
      out$delta <- out$target_value - out$reference_value
      out$valid_pair <- !is.na(out$delta)
      out$missing_target <- nrow(target_rows) == 0L
      out$missing_reference <- nrow(reference_rows) == 0L
      out$target_metric_missing <- nrow(target_rows) > 0L && is.na(out$target_value)
      out$reference_metric_missing <- nrow(reference_rows) > 0L && is.na(out$reference_value)
      out
    }))
  })

  bind_rows_fill(rows)
}

build_paired_gain_summary <- function(study,
                                      levels = c("feature", "group"),
                                      metric = "f1",
                                      bootstrap_replicates = 2000L,
                                      confidence = 0.95) {
  differences <- build_paired_gain_differences(study, levels = levels, metric = metric)
  if (nrow(differences) == 0L) {
    return(list(summary = data.frame(), bootstrap_ci = data.frame(), differences = data.frame()))
  }

  expected_replicates <- length(unique(differences$replicate))
  setting_cols <- intersect(
    c(
      "scenario", "representation", "family",
      "n", "grid_length", "noise_axis", "snr", "noise_sd",
      "confounding_strength", "active_region_scale", "local_correlation",
      "association_method", "bandwidth", "level", "width",
      "target", "reference", "metric"
    ),
    names(differences)
  )
  split_keys <- interaction_key(differences[setting_cols])
  group_index <- 0L

  summary <- do.call(rbind, lapply(split(seq_len(nrow(differences)), split_keys), function(idx) {
    group_index <<- group_index + 1L
    part <- differences[idx, , drop = FALSE]
    valid <- part$valid_pair %in% TRUE
    deltas <- part$delta[valid]
    target_values <- part$target_value[!is.na(part$target_value)]
    reference_values <- part$reference_value[!is.na(part$reference_value)]
    complete_method_pair <- !part$missing_target & !part$missing_reference
    n_valid <- length(deltas)
    n_complete_method_pairs <- length(unique(part$replicate[complete_method_pair]))
    delta_sd <- if (n_valid > 1L) stats::sd(deltas) else if (n_valid == 1L) 0 else NA_real_
    target_sd <- if (length(target_values) > 1L) stats::sd(target_values) else if (length(target_values) == 1L) 0 else NA_real_
    reference_sd <- if (length(reference_values) > 1L) stats::sd(reference_values) else if (length(reference_values) == 1L) 0 else NA_real_
    ci <- deterministic_bootstrap_mean_ci(
      deltas,
      bootstrap_replicates = bootstrap_replicates,
      confidence = confidence,
      offset = group_index
    )

    out <- part[1, setting_cols, drop = FALSE]
    out$n_expected_replicates <- expected_replicates
    out$n_target_replicates <- length(unique(part$replicate[!part$missing_target]))
    out$n_reference_replicates <- length(unique(part$replicate[!part$missing_reference]))
    out$n_complete_method_pairs <- n_complete_method_pairs
    out$n_valid_pairs <- n_valid
    out$n_rep <- n_valid
    out$n_missing_target <- pmax(0L, expected_replicates - out$n_target_replicates)
    out$n_missing_reference <- pmax(0L, expected_replicates - out$n_reference_replicates)
    out$n_missing_pairs <- pmax(0L, expected_replicates - n_complete_method_pairs)
    out$n_invalid_metric_pairs <- pmax(0L, n_complete_method_pairs - n_valid)
    out$has_method_failures <- out$n_missing_target > 0L ||
      out$n_missing_reference > 0L ||
      out$n_missing_pairs > 0L
    if ("effective_snr" %in% names(part)) {
      out$effective_snr <- mean_or_na(part$effective_snr)
    }
    if ("effective_variance_snr" %in% names(part)) {
      out$effective_variance_snr <- mean_or_na(part$effective_variance_snr)
    }
    out$target_value_mean <- mean_or_na(target_values)
    out$reference_value_mean <- mean_or_na(reference_values)
    out$delta_mean <- mean_or_na(deltas)
    out$delta_sd <- delta_sd
    out$delta_se <- if (n_valid > 0L) delta_sd / sqrt(n_valid) else NA_real_
    out$paired_gain_mean <- out$delta_mean
    out$paired_gain_sd <- out$delta_sd
    out$paired_gain_se <- out$delta_se
    out$bootstrap_ci_lower <- ci[1L]
    out$bootstrap_ci_upper <- ci[2L]
    out$bootstrap_confidence <- confidence
    out$bootstrap_replicates <- bootstrap_replicates
    out$bootstrap_method <- "deterministic_percentile"
    out$win_rate <- if (n_valid > 0L) mean(deltas > 0) else NA_real_
    out$target_value_sd <- target_sd
    out$reference_value_sd <- reference_sd
    out$target_value_se <- if (length(target_values) > 0L) target_sd / sqrt(length(target_values)) else NA_real_
    out$reference_value_se <- if (length(reference_values) > 0L) reference_sd / sqrt(length(reference_values)) else NA_real_
    out$method <- "selectboost_vs_plain_selectboost"
    out
  }))

  bootstrap_ci <- summary[
    ,
    unique(c(
      setting_cols,
      intersect(c("effective_snr", "effective_variance_snr"), names(summary)),
      "method", "n_expected_replicates", "n_complete_method_pairs", "n_valid_pairs",
      "n_missing_target", "n_missing_reference", "n_missing_pairs",
      "n_invalid_metric_pairs", "has_method_failures", "paired_gain_mean", "paired_gain_sd",
      "paired_gain_se", "bootstrap_ci_lower", "bootstrap_ci_upper",
      "bootstrap_confidence", "bootstrap_replicates", "bootstrap_method",
      "win_rate"
    )),
    drop = FALSE
  ]

  list(summary = summary, bootstrap_ci = bootstrap_ci, differences = differences)
}

build_representation_summary <- function(summary_by_setting) {
  data <- as.data.frame(summary_by_setting, stringsAsFactors = FALSE)
  data <- data[!is.na(data$f1_mean), , drop = FALSE]
  if (nrow(data) == 0L) {
    return(data.frame())
  }

  by_cols <- intersect(c("noise_axis", "snr", "noise_sd", "representation", "method", "level"), names(data))
  split_keys <- interaction_key(data[by_cols])
  do.call(rbind, lapply(split(seq_len(nrow(data)), split_keys), function(idx) {
    part <- data[idx, , drop = FALSE]
    out <- part[1, by_cols, drop = FALSE]
    out$n_settings <- nrow(part)
    out$f1_mean <- mean(part$f1_mean, na.rm = TRUE)
    out$f1_sd <- if (nrow(part) > 1L) stats::sd(part$f1_mean, na.rm = TRUE) else 0
    out$precision_mean <- mean(part$precision_mean, na.rm = TRUE)
    out$recall_mean <- mean(part$recall_mean, na.rm = TRUE)
    out$jaccard_mean <- mean(part$jaccard_mean, na.rm = TRUE)
    out$selection_rate_mean <- mean(part$selection_rate_mean, na.rm = TRUE)
    out
  }))
}

assessment_setting_columns <- function(data) {
  intersect(
    c(
      "scenario", "representation", "family",
      "n", "grid_length", "noise_axis", "snr", "noise_sd",
      "confounding_strength", "active_region_scale", "local_correlation",
      "association_method", "bandwidth", "level", "width",
      "target", "reference", "metric"
    ),
    names(data)
  )
}

build_assessment_top_positive_settings <- function(paired_gain_summary,
                                               top_n = 20L,
                                               level = "feature") {
  data <- as.data.frame(paired_gain_summary, stringsAsFactors = FALSE)
  if (nrow(data) == 0L || !"paired_gain_mean" %in% names(data)) {
    return(data.frame())
  }
  if ("level" %in% names(data)) {
    data <- data[data$level == level, , drop = FALSE]
  }
  data <- data[!is.na(data$paired_gain_mean) & data$paired_gain_mean > 0, , drop = FALSE]
  if (nrow(data) == 0L) {
    data$assessment_rank <- integer(0)
    return(data)
  }
  data <- data[
    order(
      -data$paired_gain_mean,
      -data$win_rate,
      -data$n_valid_pairs,
      data$has_method_failures
    ),
    ,
    drop = FALSE
  ]
  data$assessment_rank <- seq_len(nrow(data))
  utils::head(data, top_n)
}

build_assessment_negative_gain_settings <- function(paired_gain_summary,
                                                top_n = 20L,
                                                level = "feature") {
  data <- as.data.frame(paired_gain_summary, stringsAsFactors = FALSE)
  if (nrow(data) == 0L || !"paired_gain_mean" %in% names(data)) {
    return(data.frame())
  }
  if ("level" %in% names(data)) {
    data <- data[data$level == level, , drop = FALSE]
  }
  data <- data[!is.na(data$paired_gain_mean) & data$paired_gain_mean < 0, , drop = FALSE]
  if (nrow(data) == 0L) {
    data$assessment_rank <- integer(0)
    return(data)
  }
  data <- data[
    order(
      data$paired_gain_mean,
      data$win_rate,
      -data$n_valid_pairs,
      data$has_method_failures
    ),
    ,
    drop = FALSE
  ]
  data$assessment_rank <- seq_len(nrow(data))
  utils::head(data, top_n)
}

build_assessment_all_setting_summary <- function(paired_gain_summary,
                                             level = "feature") {
  data <- as.data.frame(paired_gain_summary, stringsAsFactors = FALSE)
  if (nrow(data) == 0L || !"paired_gain_mean" %in% names(data)) {
    return(data.frame())
  }
  if ("level" %in% names(data)) {
    data <- data[data$level == level, , drop = FALSE]
  }
  data <- data[!is.na(data$paired_gain_mean), , drop = FALSE]
  if (nrow(data) == 0L) {
    return(data.frame())
  }

  summarise_part <- function(part, by_cols, scope) {
    gains <- part$paired_gain_mean
    out <- part[1, by_cols, drop = FALSE]
    out$summary_scope <- scope
    out$n_settings <- length(gains)
    out$n_positive_settings <- sum(gains > 0, na.rm = TRUE)
    out$n_negative_settings <- sum(gains < 0, na.rm = TRUE)
    out$fraction_positive <- out$n_positive_settings / out$n_settings
    out$median_gain <- stats::median(gains, na.rm = TRUE)
    out$q1_gain <- stats::quantile(gains, probs = 0.25, names = FALSE, type = 6, na.rm = TRUE)
    out$q3_gain <- stats::quantile(gains, probs = 0.75, names = FALSE, type = 6, na.rm = TRUE)
    out$iqr_gain <- out$q3_gain - out$q1_gain
    out$mean_gain <- mean_or_na(gains)
    out$min_gain <- min(gains, na.rm = TRUE)
    out$max_gain <- max(gains, na.rm = TRUE)
    out$n_settings_with_failures <- sum(part$has_method_failures %in% TRUE, na.rm = TRUE)
    out$interpretation_rule <- "Use best-settings table only together with this all-setting summary."
    out
  }

  overall_cols <- intersect("level", names(data))
  overall <- summarise_part(data, overall_cols, "overall")

  by_cols <- intersect(c("level", "noise_axis", "snr", "noise_sd"), names(data))
  split_keys <- interaction_key(data[by_cols])
  by_noise <- do.call(rbind, lapply(split(seq_len(nrow(data)), split_keys), function(idx) {
    summarise_part(data[idx, , drop = FALSE], by_cols, "noise_axis")
  }))

  bind_rows_fill(list(overall, by_noise))
}

build_assessment_failure_modes <- function(paired_gain_summary,
                                       level = "feature") {
  data <- as.data.frame(paired_gain_summary, stringsAsFactors = FALSE)
  if (nrow(data) == 0L || !"paired_gain_mean" %in% names(data)) {
    return(data.frame())
  }
  if ("level" %in% names(data)) {
    data <- data[data$level == level, , drop = FALSE]
  }
  data <- data[!is.na(data$paired_gain_mean) & data$paired_gain_mean < 0, , drop = FALSE]
  if (nrow(data) == 0L) {
    data$failure_mode <- character(0)
    data$assessment_note <- character(0)
    return(data)
  }

  label_failure <- function(row) {
    labels <- character()
    if ("scenario" %in% names(row) && identical(as.character(row$scenario), "mislocalized_signal")) {
      labels <- c(labels, "locality_mismatch")
    }
    if ("scenario" %in% names(row) && identical(as.character(row$scenario), "null_signal")) {
      labels <- c(labels, "null_signal_false_positive_risk")
    }
    if ("association_method" %in% names(row) && identical(as.character(row$association_method), "correlation")) {
      labels <- c(labels, "no_fda_neighborhood_structure")
    }
    if ("active_region_scale" %in% names(row) && !is.na(row$active_region_scale) && row$active_region_scale >= 0.9) {
      labels <- c(labels, "broad_signal_less_locality_gain")
    }
    if ("local_correlation" %in% names(row) && !is.na(row$local_correlation) && row$local_correlation <= 0) {
      labels <- c(labels, "low_local_correlation")
    }
    if ("bandwidth" %in% names(row) && !is.na(row$bandwidth) && row$bandwidth > 6) {
      labels <- c(labels, "wide_bandwidth_possible_over_smoothing")
    }
    if ("n_invalid_metric_pairs" %in% names(row) && !is.na(row$n_invalid_metric_pairs) && row$n_invalid_metric_pairs > 0) {
      labels <- c(labels, "metric_not_applicable_for_some_pairs")
    }
    if (length(labels) == 0L) {
      labels <- "empirical_negative_gain"
    }
    paste(unique(labels), collapse = ";")
  }

  data <- data[
    order(
      data$paired_gain_mean,
      data$win_rate,
      -data$n_valid_pairs,
      data$has_method_failures
    ),
    ,
    drop = FALSE
  ]
  data$failure_mode <- vapply(seq_len(nrow(data)), function(i) {
    label_failure(data[i, , drop = FALSE])
  }, character(1))
  data$assessment_note <- "Visible negative-gain setting; use to state limitations alongside strengths."
  data
}

threshold_components <- function(association, c0) {
  adjacency <- abs(as.matrix(association)) >= c0
  diag(adjacency) <- TRUE
  p <- nrow(adjacency)
  visited <- rep(FALSE, p)
  components <- vector("list", p)
  n_components <- 0L

  for (start in seq_len(p)) {
    if (visited[start]) {
      next
    }
    queue <- start
    visited[start] <- TRUE
    members <- integer()

    while (length(queue) > 0L) {
      current <- queue[1L]
      queue <- queue[-1L]
      members <- c(members, current)
      neighbors <- which(adjacency[current, ] & !visited)
      if (length(neighbors) > 0L) {
        visited[neighbors] <- TRUE
        queue <- c(queue, neighbors)
      }
    }

    n_components <- n_components + 1L
    components[[n_components]] <- members
  }

  components[seq_len(n_components)]
}

summarise_threshold_group_sizes <- function(association,
                                            c0_grid,
                                            method = NA_character_) {
  rows <- lapply(c0_grid, function(c0) {
    components <- threshold_components(association, c0 = c0)
    sizes <- vapply(components, length, integer(1))
    distribution <- paste(
      paste0(sort(unique(sizes)), ":", tabulate(match(sizes, sort(unique(sizes))))),
      collapse = ";"
    )
    data.frame(
      method = method,
      c0 = c0,
      n_induced_groups = length(sizes),
      group_size_min = min(sizes),
      group_size_q1 = stats::quantile(sizes, probs = 0.25, names = FALSE, type = 6),
      group_size_median = stats::median(sizes),
      group_size_mean = mean(sizes),
      group_size_q3 = stats::quantile(sizes, probs = 0.75, names = FALSE, type = 6),
      group_size_max = max(sizes),
      group_size_sd = if (length(sizes) > 1L) stats::sd(sizes) else 0,
      singleton_fraction = mean(sizes == 1L),
      group_size_distribution = distribution,
      stringsAsFactors = FALSE
    )
  })
  bind_rows_fill(rows)
}

association_metric_columns <- c(
  "mean_association", "median_association", "sparsity",
  "within_block_mass", "cross_block_mass", "local_mass", "nonlocal_mass",
  "effective_degree_mean", "effective_degree_sd"
)

focused_grid_row_as_list <- function(grid, i, na_to_null = FALSE) {
  row <- lapply(grid[i, , drop = FALSE], function(value) {
    if (is.factor(value)) {
      value <- as.character(value)
    }
    if (isTRUE(na_to_null) && length(value) == 1L && is.atomic(value) && is.na(value)) {
      return(NULL)
    }
    value
  })

  if (isTRUE(na_to_null)) {
    row <- row[!vapply(row, is.null, logical(1))]
  }

  row
}

focused_append_parameter_columns <- function(data, params) {
  if (nrow(data) == 0L || length(params) == 0L) {
    return(data)
  }

  for (name in names(params)) {
    value <- params[[name]]
    if (is.null(value) || length(value) != 1L) {
      next
    }
    if (is.factor(value)) {
      value <- as.character(value)
    }
    data[[name]] <- rep(value, nrow(data))
  }

  data
}

focused_default_interval_width <- function(x) {
  fda_x <- as_functional_matrix(x)
  per_block <- tapply(fda_x$positions, fda_x$blocks, max)
  max(2L, floor(stats::median(as.numeric(per_block)) / 5))
}

build_association_diagnostic_artifacts <- function(simulate_grid,
                                                   selectboost_grid,
                                                   simulate_args,
                                                   c0_grid,
                                                   seed,
                                                   within_blocks = TRUE) {
  diagnostic_rows <- list()
  group_rows <- list()
  row_index <- 0L

  for (i in seq_len(nrow(simulate_grid))) {
    simulate_args_current <- utils::modifyList(
      simulate_args,
      focused_grid_row_as_list(simulate_grid, i, na_to_null = TRUE)
    )
    simulate_args_current$seed <- focused_next_seed(seed, i)
    sim <- do.call(simulate_fda_scenario, simulate_args_current)
    simulate_labels <- focused_grid_row_as_list(simulate_grid, i, na_to_null = FALSE)
    simulate_labels$family <- sim$design$family %||% simulate_labels$family %||% "gaussian"

    for (j in seq_len(nrow(selectboost_grid))) {
      selectboost_labels <- focused_grid_row_as_list(selectboost_grid, j, na_to_null = FALSE)
      selectboost_args_current <- focused_grid_row_as_list(selectboost_grid, j, na_to_null = TRUE)
      association_method <- selectboost_args_current$association_method %||% "correlation"
      bandwidth <- selectboost_args_current$bandwidth %||% NULL
      width <- selectboost_args_current$width %||% NULL
      step <- selectboost_args_current$step %||% width

      if (identical(association_method, "interval") && is.null(width)) {
        width <- focused_default_interval_width(sim$design)
        step <- step %||% width
      }

      association <- functional_association(
        x = sim$design,
        method = association_method,
        within_blocks = within_blocks,
        bandwidth = bandwidth,
        width = width,
        step = step
      )
      structure_summary <- summarise_association_structure(
        association = association,
        x = sim$design,
        bandwidth = bandwidth,
        method = association_method
      )
      structure_summary$within_blocks <- within_blocks
      structure_summary$bandwidth <- selectboost_labels$bandwidth %||% NA_real_
      structure_summary$width <- width %||% NA_real_
      structure_summary$step <- step %||% NA_real_
      structure_summary$method <- "association_diagnostic"
      structure_summary$association_method <- association_method
      structure_summary$replicate <- "diagnostic"
      structure_summary$selector <- "association"
      structure_summary$B <- 0L
      structure_summary[["steps.seq"]] <- steps_label(c0_grid)
      structure_summary <- focused_append_parameter_columns(structure_summary, simulate_labels)
      structure_summary <- focused_append_parameter_columns(structure_summary, selectboost_labels)

      group_summary <- summarise_threshold_group_sizes(
        association = association,
        c0_grid = c0_grid,
        method = "association_group_size"
      )
      group_summary$within_blocks <- within_blocks
      group_summary$bandwidth <- selectboost_labels$bandwidth %||% NA_real_
      group_summary$width <- width %||% NA_real_
      group_summary$step <- step %||% NA_real_
      group_summary$association_method <- association_method
      group_summary$replicate <- "diagnostic"
      group_summary$selector <- "association"
      group_summary$B <- 0L
      group_summary[["steps.seq"]] <- steps_label(c0_grid)
      group_summary <- focused_append_parameter_columns(group_summary, simulate_labels)
      group_summary <- focused_append_parameter_columns(group_summary, selectboost_labels)

      row_index <- row_index + 1L
      diagnostic_rows[[row_index]] <- structure_summary
      group_rows[[row_index]] <- group_summary
    }
  }

  diagnostics <- bind_rows_fill(diagnostic_rows)
  group_sizes <- bind_rows_fill(group_rows)
  list(
    diagnostics = diagnostics,
    group_sizes = group_sizes,
    assessment_table = build_assessment_association_comparison_table(diagnostics, group_sizes)
  )
}

build_assessment_association_comparison_table <- function(diagnostics,
                                                      group_sizes) {
  diagnostics <- as.data.frame(diagnostics, stringsAsFactors = FALSE)
  if (nrow(diagnostics) == 0L) {
    return(data.frame())
  }

  by_cols <- intersect(
    c("association_method", "bandwidth", "within_blocks", "representation"),
    names(diagnostics)
  )
  split_keys <- interaction_key(diagnostics[by_cols])

  rows <- lapply(split(seq_len(nrow(diagnostics)), split_keys), function(idx) {
    part <- diagnostics[idx, , drop = FALSE]
    out <- part[1, by_cols, drop = FALSE]
    out$method <- "association_comparison"
    out$replicate <- "diagnostic"
    out$selector <- "association"
    out$B <- 0L
    out[["steps.seq"]] <- part[["steps.seq"]][1L] %||% NA_character_
    out$n_diagnostic_settings <- nrow(part)
    for (metric in association_metric_columns) {
      if (metric %in% names(part)) {
        out[[paste0(metric, "_mean")]] <- mean_or_na(part[[metric]])
        out[[paste0(metric, "_sd")]] <- sd_or_zero(part[[metric]])
      }
    }
    out
  })
  out <- bind_rows_fill(rows)

  groups <- as.data.frame(group_sizes, stringsAsFactors = FALSE)
  if (nrow(groups) > 0L) {
    group_by_cols <- intersect(c(by_cols, "c0"), names(groups))
    group_keys <- interaction_key(groups[group_by_cols])
    group_summary <- lapply(split(seq_len(nrow(groups)), group_keys), function(idx) {
      part <- groups[idx, , drop = FALSE]
      out <- part[1, group_by_cols, drop = FALSE]
      out$n_induced_groups_mean <- mean_or_na(part$n_induced_groups)
      out$group_size_mean_mean <- mean_or_na(part$group_size_mean)
      out$singleton_fraction_mean <- mean_or_na(part$singleton_fraction)
      out
    })
    group_summary <- bind_rows_fill(group_summary)
    if (nrow(group_summary) > 0L) {
      group_wide <- reshape(
        group_summary,
        idvar = by_cols,
        timevar = "c0",
        direction = "wide"
      )
      out <- merge(out, group_wide, by = by_cols, all.x = TRUE, sort = FALSE)
    }
  }

  out$assessment_note <- "Association geometry summary; join to benchmark settings by representation, association_method, bandwidth, and within_blocks."
  out
}

method_comparison_specs <- function() {
  data.frame(
    method = c(
      "plain_selectboost",
      "selectboost_fda_lasso",
      "selectboost_fda_group_lasso",
      "selectboost_fda_sparse_group_lasso",
      "stability_lasso",
      "stability_group_lasso",
      "stability_sparse_group_lasso"
    ),
    perturbation_type = c(
      "plain_selectboost",
      "fda_selectboost",
      "fda_selectboost",
      "fda_selectboost",
      "stability_selection",
      "stability_selection",
      "stability_selection"
    ),
    base_selector = c(
      "msgps",
      "lasso",
      "group_lasso",
      "sparse_group_lasso",
      "lasso",
      "group_lasso",
      "sparse_group_lasso"
    ),
    selector_package = c(NA_character_, "glmnet", "grpreg", "SGL", "glmnet", "grpreg", "SGL"),
    stringsAsFactors = FALSE
  )
}

annotate_method_availability <- function(specs) {
  specs$method_available <- vapply(specs$selector_package, function(pkg) {
    is.na(pkg) || requireNamespace(pkg, quietly = TRUE)
  }, logical(1))
  specs$skip_reason <- ifelse(
    specs$method_available,
    NA_character_,
    paste0("optional package not installed: ", specs$selector_package)
  )
  specs
}

method_comparison_simulation_grid <- function(simulate_grid,
                                              sim_n,
                                              grid_length,
                                              quick = FALSE) {
  if (isTRUE(quick)) {
    return(utils::head(simulate_grid, 1L))
  }

  allowed_representations <- unique(simulate_grid$representation)
  grid <- surface_scenario_grid()
  grid <- grid[grid$representation %in% allowed_representations, , drop = FALSE]
  if (nrow(grid) == 0L) {
    return(utils::head(simulate_grid, 1L))
  }

  grid$n <- sim_n
  grid$grid_length <- grid_length
  grid$noise_axis <- "default"
  grid$snr <- NA_real_
  grid$noise_sd <- NA_real_
  grid <- grid[
    ,
    c(
      "representation", "n", "grid_length", "noise_axis", "snr", "noise_sd",
      "scenario", "confounding_strength", "active_region_scale", "local_correlation"
    ),
    drop = FALSE
  ]
  rownames(grid) <- NULL
  grid
}

focused_timing_value <- function(timing, name) {
  value <- unname(timing[[name]])
  if (length(value) == 0L || is.null(value) || is.na(value)) {
    return(NA_real_)
  }
  as.numeric(value)
}

focused_object_size_mb <- function(x) {
  if (is.null(x)) {
    return(NA_real_)
  }
  as.numeric(utils::object.size(x)) / (1024^2)
}

focused_capture_runtime_result <- function(expr) {
  warning_messages <- character()
  result <- NULL
  timing <- system.time({
    result <- withCallingHandlers(
      tryCatch(
        list(value = force(expr), error = NULL),
        error = function(e) list(value = NULL, error = e)
      ),
      warning = function(w) {
        warning_messages <<- c(warning_messages, conditionMessage(w))
        invokeRestart("muffleWarning")
      }
    )
  })

  list(
    value = result$value,
    error = result$error,
    warnings = unique(warning_messages),
    timing = timing
  )
}

method_runtime_row <- function(spec,
                               simulate_labels,
                               selectboost_labels = list(),
                               replicate,
                               status,
                               B = NA_integer_,
                               steps_seq = NA_character_,
                               elapsed = NA_real_,
                               user = NA_real_,
                               system = NA_real_,
                               n_warnings = 0L,
                               n_failures = if (identical(status, "failed")) 1L else 0L,
                               warning_messages = NA_character_,
                               fit_object_size_mb = NA_real_,
                               error_message = NA_character_) {
  out <- data.frame(
    method = spec$method,
    perturbation_type = spec$perturbation_type,
    base_selector = spec$base_selector,
    selector_package = spec$selector_package,
    selector = spec$base_selector,
    B = B,
    steps.seq = steps_seq,
    method_available = spec$method_available,
    skip_reason = spec$skip_reason,
    method_status = status,
    method_replicate = replicate,
    method_user = user,
    method_system = system,
    method_elapsed = elapsed,
    n_warnings = n_warnings,
    n_failures = n_failures,
    warning_messages = warning_messages,
    fit_object_size_mb = fit_object_size_mb,
    error_message = error_message,
    stringsAsFactors = FALSE
  )
  out <- focused_append_parameter_columns(out, simulate_labels)
  out <- focused_append_parameter_columns(out, selectboost_labels)
  if (!"association_method" %in% names(out)) {
    out$association_method <- NA_character_
  }
  if (!"bandwidth" %in% names(out)) {
    out$bandwidth <- NA_real_
  }
  out
}

run_one_method_fit <- function(spec,
                               sim,
                               selectboost_labels,
                               selectboost_steps,
                               selectboost_B,
                               stability_B,
                               stability_cutoff,
                               seed) {
  if (identical(spec$method, "plain_selectboost")) {
    return(withr::with_seed(
      as.integer(seed),
      plain_selectboost(
        x = sim$design,
        selector = spec$base_selector,
        mode = "fast",
        B = selectboost_B,
        steps.seq = selectboost_steps,
        c0lim = FALSE
      )
    ))
  }

  if (identical(spec$perturbation_type, "fda_selectboost")) {
    args <- focused_grid_row_as_list(selectboost_labels, 1L, na_to_null = TRUE)
    if (identical(args$association_method, "interval") && is.null(args$width)) {
      args$width <- focused_default_interval_width(sim$design)
      args$step <- args$step %||% args$width
    }
    return(withr::with_seed(
      as.integer(seed),
      do.call(
        selectboost_fda,
        c(
          list(
            x = sim$design,
            selector = spec$base_selector,
            mode = "fast",
            B = selectboost_B,
            steps.seq = selectboost_steps,
            c0lim = FALSE
          ),
          args
        )
      )
    ))
  }

  fit_stability(
    design = sim$design,
    selector = spec$base_selector,
    B = stability_B,
    cutoff = stability_cutoff,
    seed = seed
  )
}

evaluate_method_fit <- function(fit,
                                sim,
                                spec,
                                simulate_labels,
                                selectboost_labels,
                                replicate,
                                levels = c("feature", "group", "basis")) {
  rows <- lapply(levels, function(level) {
    out <- evaluate_selection(fit, truth = sim, level = level)
    out$level <- level
    out
  })
  metrics <- bind_rows_fill(rows)
  if (nrow(metrics) == 0L) {
    return(metrics)
  }
  metrics$method <- spec$method
  metrics$perturbation_type <- spec$perturbation_type
  metrics$base_selector <- spec$base_selector
  metrics$selector_package <- spec$selector_package
  metrics$method_available <- spec$method_available
  metrics$skip_reason <- spec$skip_reason
  metrics$method_status <- "completed"
  metrics$method_replicate <- replicate
  metrics$replicate <- replicate
  metrics$selector <- spec$base_selector
  metrics$scenario <- sim$scenario
  metrics$representation <- sim$representation
  metrics$family <- sim$family
  metrics$noise_axis <- sim$noise_axis %||% NA_character_
  metrics$snr <- sim$snr %||% NA_real_
  metrics$noise_sd <- sim$requested_noise_sd %||% sim$noise_sd %||% NA_real_
  metrics$effective_noise_sd <- sim$noise_sd %||% NA_real_
  metrics$effective_snr <- sim$effective_snr %||% NA_real_
  metrics$effective_variance_snr <- sim$effective_variance_snr %||% {
    value <- sim$effective_snr %||% NA_real_
    ifelse(is.na(value), NA_real_, value^2)
  }
  metrics <- focused_append_parameter_columns(metrics, simulate_labels)
  metrics <- focused_append_parameter_columns(metrics, selectboost_labels)
  metrics
}

run_method_comparison_study <- function(simulate_grid,
                                        selectboost_grid,
                                        simulate_args,
                                        selectboost_steps,
                                        n_rep,
                                        seed,
                                        selectboost_B,
                                        stability_B,
                                        stability_cutoff = 0.5,
                                        levels = c("feature", "group", "basis")) {
  specs <- annotate_method_availability(method_comparison_specs())
  metric_rows <- list()
  runtime_rows <- list()
  row_index <- 0L
  runtime_index <- 0L

  for (replicate in seq_len(as.integer(n_rep))) {
    replicate_seed <- focused_next_seed(seed, replicate)
    for (i in seq_len(nrow(simulate_grid))) {
      simulate_args_current <- utils::modifyList(
        simulate_args,
        focused_grid_row_as_list(simulate_grid, i, na_to_null = TRUE)
      )
      simulate_args_current$seed <- focused_next_seed(replicate_seed, i)
      sim <- do.call(simulate_fda_scenario, simulate_args_current)
      simulate_labels <- focused_grid_row_as_list(simulate_grid, i, na_to_null = FALSE)
      simulate_labels$family <- sim$family

      for (s in seq_len(nrow(specs))) {
        spec <- specs[s, , drop = FALSE]
        selectboost_setting_indices <- if (identical(spec$perturbation_type, "fda_selectboost")) {
          seq_len(nrow(selectboost_grid))
        } else {
          NA_integer_
        }

        for (j in selectboost_setting_indices) {
          selectboost_labels <- if (is.na(j)) {
            list(association_method = NA_character_, bandwidth = NA_real_)
          } else {
            focused_grid_row_as_list(selectboost_grid, j, na_to_null = FALSE)
          }

          if (!isTRUE(spec$method_available)) {
            runtime_index <- runtime_index + 1L
            runtime_rows[[runtime_index]] <- method_runtime_row(
              spec = spec,
              simulate_labels = simulate_labels,
              selectboost_labels = selectboost_labels,
              replicate = replicate,
              status = "skipped",
              B = if (identical(spec$perturbation_type, "stability_selection")) stability_B else selectboost_B,
              steps_seq = if (identical(spec$perturbation_type, "stability_selection")) NA_character_ else steps_label(selectboost_steps),
              error_message = spec$skip_reason
            )
            next
          }

          fit_seed <- focused_next_seed(focused_next_seed(simulate_args_current$seed, s * 100L), ifelse(is.na(j), 1L, j))
          fit_capture <- focused_capture_runtime_result(
              run_one_method_fit(
                spec = spec,
                sim = sim,
                selectboost_labels = as.data.frame(selectboost_labels, stringsAsFactors = FALSE),
                selectboost_steps = selectboost_steps,
                selectboost_B = selectboost_B,
                stability_B = stability_B,
                stability_cutoff = stability_cutoff,
                seed = fit_seed
              )
            )
          timing <- fit_capture$timing
          fit <- fit_capture$value
          elapsed <- focused_timing_value(timing, "elapsed")
          user <- focused_timing_value(timing, "user.self")
          system <- focused_timing_value(timing, "sys.self")
          warning_messages <- paste(fit_capture$warnings, collapse = " | ")

          if (!is.null(fit_capture$error)) {
            runtime_index <- runtime_index + 1L
            runtime_rows[[runtime_index]] <- method_runtime_row(
              spec = spec,
              simulate_labels = simulate_labels,
              selectboost_labels = selectboost_labels,
              replicate = replicate,
              status = "failed",
              B = if (identical(spec$perturbation_type, "stability_selection")) stability_B else selectboost_B,
              steps_seq = if (identical(spec$perturbation_type, "stability_selection")) NA_character_ else steps_label(selectboost_steps),
              elapsed = elapsed,
              user = user,
              system = system,
              n_warnings = length(fit_capture$warnings),
              n_failures = 1L,
              warning_messages = warning_messages,
              error_message = conditionMessage(fit_capture$error)
            )
            next
          }

          runtime_index <- runtime_index + 1L
          runtime_rows[[runtime_index]] <- method_runtime_row(
            spec = spec,
            simulate_labels = simulate_labels,
            selectboost_labels = selectboost_labels,
            replicate = replicate,
            status = "completed",
            B = if (identical(spec$perturbation_type, "stability_selection")) stability_B else selectboost_B,
            steps_seq = if (identical(spec$perturbation_type, "stability_selection")) NA_character_ else steps_label(selectboost_steps),
            elapsed = elapsed,
            user = user,
            system = system,
            n_warnings = length(fit_capture$warnings),
            n_failures = 0L,
            warning_messages = warning_messages,
            fit_object_size_mb = focused_object_size_mb(fit)
          )

          metrics <- evaluate_method_fit(
            fit = fit,
            sim = sim,
            spec = spec,
            simulate_labels = simulate_labels,
            selectboost_labels = selectboost_labels,
            replicate = replicate,
            levels = levels
          )
          if (nrow(metrics) > 0L) {
            metrics$method_elapsed <- elapsed
            metrics$method_user <- user
            metrics$method_system <- system
            metrics$n_warnings <- length(fit_capture$warnings)
            metrics$n_failures <- 0L
            metrics$warning_messages <- warning_messages
            metrics$fit_object_size_mb <- focused_object_size_mb(fit)
            metrics$B <- if (identical(spec$perturbation_type, "stability_selection")) stability_B else selectboost_B
            metrics[["steps.seq"]] <- if (identical(spec$perturbation_type, "stability_selection")) NA_character_ else steps_label(selectboost_steps)
            row_index <- row_index + 1L
            metric_rows[[row_index]] <- metrics
          }
        }
      }
    }
  }

  metrics <- bind_rows_fill(metric_rows)
  runtime <- bind_rows_fill(runtime_rows)
  list(
    metrics = metrics,
    summary = build_method_comparison_summary(metrics, specs),
    runtime = runtime,
    assessment_table = build_assessment_method_comparison_table(metrics, runtime, specs)
  )
}

build_method_comparison_summary <- function(metrics, specs) {
  metrics <- as.data.frame(metrics, stringsAsFactors = FALSE)
  if (nrow(metrics) == 0L) {
    return(data.frame())
  }

  best_metric_rows_fn <- get("best_metric_rows", envir = asNamespace("SelectBoost.FDA"))
  levels <- unique(metrics$level)
  best_rows <- bind_rows_fill(lapply(levels, function(level) {
    best_metric_rows_fn(
      metrics = metrics,
      level = level,
      metric = "f1",
      optimize = "max",
      select_c0 = "best"
    )
  }))
  if (nrow(best_rows) == 0L) {
    return(data.frame())
  }

  by_cols <- intersect(
    c(
      "method", "perturbation_type", "base_selector", "selector_package",
      "method_available", "method_status", "selector", "B", "steps.seq",
      "scenario", "representation",
      "family", "n", "grid_length", "noise_axis", "snr", "noise_sd",
      "confounding_strength", "active_region_scale", "local_correlation",
      "association_method", "bandwidth", "level"
    ),
    names(best_rows)
  )
  metric_cols <- intersect(
    c("precision", "recall", "specificity", "f1", "jaccard", "selection_rate", "n_selected", "tp", "fp", "fn", "tn"),
    names(best_rows)
  )
  split_keys <- interaction_key(best_rows[by_cols])

  bind_rows_fill(lapply(split(seq_len(nrow(best_rows)), split_keys), function(idx) {
    part <- best_rows[idx, , drop = FALSE]
    out <- part[1, by_cols, drop = FALSE]
    out$n_rep <- length(unique(part$replicate))
    out$n_method_rows <- nrow(part)
    if ("effective_noise_sd" %in% names(part)) {
      out$effective_noise_sd <- mean_or_na(part$effective_noise_sd)
    }
    if ("effective_snr" %in% names(part)) {
      out$effective_snr <- mean_or_na(part$effective_snr)
    }
    if ("effective_variance_snr" %in% names(part)) {
      out$effective_variance_snr <- mean_or_na(part$effective_variance_snr)
    }
    for (metric in metric_cols) {
      values <- as.numeric(part[[metric]])
      out[[paste0(metric, "_mean")]] <- mean_or_na(values)
      out[[paste0(metric, "_sd")]] <- sd_or_zero(values)
      out[[paste0(metric, "_se")]] <- out[[paste0(metric, "_sd")]] / sqrt(pmax(out$n_method_rows, 1L))
    }
    out
  }))
}

build_assessment_method_comparison_table <- function(metrics, runtime, specs, level = "feature") {
  summary <- build_method_comparison_summary(metrics, specs)
  summary <- summary[summary$level == level, , drop = FALSE]

  rows <- lapply(seq_len(nrow(specs)), function(i) {
    spec <- specs[i, , drop = FALSE]
    part <- summary[summary$method == spec$method, , drop = FALSE]
    run_part <- runtime[runtime$method == spec$method, , drop = FALSE]
    out <- data.frame(
      method = spec$method,
      perturbation_type = spec$perturbation_type,
      base_selector = spec$base_selector,
      selector_package = spec$selector_package,
      selector = spec$base_selector,
      B = if (nrow(run_part) > 0L) stats::median(run_part$B, na.rm = TRUE) else NA_real_,
      steps.seq = if (nrow(run_part) > 0L) run_part[["steps.seq"]][which(!is.na(run_part[["steps.seq"]]))[1L]] %||% NA_character_ else NA_character_,
      method_available = spec$method_available,
      skip_reason = spec$skip_reason,
      level = level,
      n_completed_fits = sum(run_part$method_status == "completed", na.rm = TRUE),
      n_failed_fits = sum(run_part$method_status == "failed", na.rm = TRUE),
      n_skipped_fits = sum(run_part$method_status == "skipped", na.rm = TRUE),
      n_warnings = sum(run_part$n_warnings, na.rm = TRUE),
      n_failures = sum(run_part$n_failures, na.rm = TRUE),
      runtime_user_mean = mean_or_na(run_part$method_user),
      runtime_system_mean = mean_or_na(run_part$method_system),
      runtime_elapsed_mean = mean_or_na(run_part$method_elapsed),
      memory_mb_mean = mean_or_na(run_part$fit_object_size_mb),
      memory_mb_max = max_or_na(run_part$fit_object_size_mb),
      stringsAsFactors = FALSE
    )
    out$f1_mean <- if (nrow(part) > 0L) mean_or_na(part$f1_mean) else NA_real_
    out$f1_sd <- if (nrow(part) > 1L) stats::sd(part$f1_mean, na.rm = TRUE) else if (nrow(part) == 1L) 0 else NA_real_
    out$precision_mean <- if (nrow(part) > 0L) mean_or_na(part$precision_mean) else NA_real_
    out$recall_mean <- if (nrow(part) > 0L) mean_or_na(part$recall_mean) else NA_real_
    out$selection_rate_mean <- if (nrow(part) > 0L) mean_or_na(part$selection_rate_mean) else NA_real_
    out$n_summary_settings <- nrow(part)
    out$assessment_label <- paste(spec$perturbation_type, spec$base_selector, sep = " / ")
    out
  })
  bind_rows_fill(rows)
}

surface_scenario_grid <- function() {
  data.frame(
    surface_scenario_type = c(
      "localized_dense",
      "confounded_blocks",
      "smooth_sparse",
      "basis_block_signal",
      "fpca_low_rank_signal",
      "null_signal",
      "mislocalized_signal"
    ),
    scenario = c(
      "localized_dense",
      "confounded_blocks",
      "smooth_sparse",
      "basis_block_signal",
      "fpca_low_rank_signal",
      "null_signal",
      "mislocalized_signal"
    ),
    representation = c("grid", "grid", "grid", "bspline", "fpca", "grid", "grid"),
    confounding_strength = c(0.8, 1.0, 0.4, 0.3, 0.2, 0.0, 0.6),
    active_region_scale = c(0.7, 0.5, 0.6, 1.0, 1.0, 1.0, 0.5),
    local_correlation = c(1.5, 2.0, 2.0, 1.5, 1.0, 2.0, 2.0),
    association_method = "hybrid",
    bandwidth = 4,
    stringsAsFactors = FALSE
  )
}

filtered_surface_scenario_grid <- function(scenario_grid = NULL, representation_grid = NULL) {
  grid <- surface_scenario_grid()
  if (!is.null(scenario_grid)) {
    grid <- grid[grid$scenario %in% scenario_grid, , drop = FALSE]
    missing <- setdiff(scenario_grid, grid$scenario)
    if (length(missing) > 0L) {
      extras <- data.frame(
        surface_scenario_type = missing,
        scenario = missing,
        representation = "grid",
        confounding_strength = 0.4,
        active_region_scale = 1.0,
        local_correlation = 1.0,
        association_method = "hybrid",
        bandwidth = 4,
        stringsAsFactors = FALSE
      )
      extras$confounding_strength[extras$scenario == "null_signal"] <- 0
      grid <- rbind(grid, extras)
    }
  }
  if (!is.null(representation_grid)) {
    grid <- grid[grid$representation %in% representation_grid, , drop = FALSE]
  }
  if (nrow(grid) == 0L) {
    grid <- utils::head(surface_scenario_grid(), 1L)
  }
  rownames(grid) <- NULL
  grid
}

add_surface_labels <- function(data, labels) {
  data <- as.data.frame(data, stringsAsFactors = FALSE)
  for (name in names(labels)) {
    value <- labels[[name]]
    if (is.null(value) || length(value) != 1L) {
      next
    }
    if (is.factor(value)) {
      value <- as.character(value)
    }
    data[[name]] <- rep(value, nrow(data))
  }
  data
}

focused_next_seed <- function(seed, i) {
  if (is.null(seed)) {
    return(NULL)
  }
  as.integer(seed) + as.integer(i) - 1L
}

fixed_threshold_rows <- function(precision_recall_paths,
                                 thresholds = c(0.5, 0.75, 0.9)) {
  data <- as.data.frame(precision_recall_paths, stringsAsFactors = FALSE)
  if (nrow(data) == 0L || !"threshold" %in% names(data)) {
    data$threshold_type <- character()
    return(data)
  }

  keep <- vapply(data$threshold, function(value) {
    any(abs(value - thresholds) < 1e-8)
  }, logical(1))
  out <- data[keep, , drop = FALSE]
  out$threshold_type <- paste0("fixed_", as.character(out$threshold))
  out
}

build_assessment_surface_artifacts <- function(surface_grid,
                                           sim_n,
                                           grid_length,
                                           noise_axis = "default",
                                           snr = NA_real_,
                                           noise_sd = NA_real_,
                                           surface_design_source = "quick_diagnostic",
                                           surface_inherits_main_n = FALSE,
                                           surface_inherits_main_grid_length = FALSE,
                                           surface_inherits_main_noise = FALSE,
                                           q_grid,
                                           c0_grid,
                                           B,
                                           selectboost_B,
                                           seed,
                                           selector = "msgps",
                                           threshold_grid = unique(sort(c(seq(0, 1, by = 0.05), 0.5, 0.75, 0.9))),
                                           fixed_thresholds = c(0.5, 0.75, 0.9)) {
  surface_rows <- vector("list", nrow(surface_grid))
  monotonicity_rows <- vector("list", nrow(surface_grid))
  precision_recall_rows <- vector("list", nrow(surface_grid))
  threshold_rows <- vector("list", nrow(surface_grid))
  warning_rows <- vector("list", nrow(surface_grid))
  fits <- vector("list", nrow(surface_grid))

  for (i in seq_len(nrow(surface_grid))) {
    setting <- surface_grid[i, , drop = FALSE]
    labels <- as.list(setting)
    labels$surface_index <- i
    labels$replicate <- "surface"
    labels$method <- "selectboost_surface"
    labels$selector <- selector
    labels$B <- B
    labels$selectboost_B <- selectboost_B
    labels$steps.seq <- paste(c0_grid, collapse = ";")
    labels$n <- sim_n
    labels$grid_length <- grid_length
    labels$noise_axis <- noise_axis
    labels$snr <- snr
    labels$noise_sd <- noise_sd
    labels$surface_design_source <- surface_design_source
    labels$surface_inherits_main_n <- surface_inherits_main_n
    labels$surface_inherits_main_grid_length <- surface_inherits_main_grid_length
    labels$surface_inherits_main_noise <- surface_inherits_main_noise
    labels$q_grid <- paste(q_grid, collapse = ";")
    labels$c0_grid <- paste(c0_grid, collapse = ";")

    sim <- tryCatch(
      simulate_fda_scenario(
        n = sim_n,
        grid_length = grid_length,
        scenario = setting$scenario,
        representation = setting$representation,
        noise_axis = noise_axis,
        snr = if (is.na(snr)) NULL else snr,
        noise_sd = if (is.na(noise_sd)) 0.4 else noise_sd,
        confounding_strength = setting$confounding_strength,
        active_region_scale = setting$active_region_scale,
        local_correlation = setting$local_correlation,
        include_scalar = FALSE,
        seed = focused_next_seed(seed, i)
      ),
      error = function(e) e
    )
    if (inherits(sim, "error")) {
      warning_rows[[i]] <- add_surface_labels(
        data.frame(message = conditionMessage(sim), stringsAsFactors = FALSE),
        labels
      )
      next
    }

    fit <- tryCatch(
      fit_perturbation_grid(
        sim$design,
        q_grid = q_grid,
        c0_grid = c0_grid,
        B = B,
        selectboost_B = selectboost_B,
        selector = selector,
        association_method = setting$association_method,
        bandwidth = setting$bandwidth,
        levels = c("feature", "group"),
        seed = focused_next_seed(seed + 1000L, i)
      ),
      error = function(e) e
    )
    if (inherits(fit, "error")) {
      warning_rows[[i]] <- add_surface_labels(
        data.frame(message = conditionMessage(fit), stringsAsFactors = FALSE),
        labels
      )
      next
    }
    fit$truth <- sim$truth
    fits[[i]] <- fit

    surface_summary <- summarise_perturbation_grid(fit)
    surface_summary$n_surface_warnings <- nrow(fit$warnings)
    surface_rows[[i]] <- add_surface_labels(surface_summary, labels)

    mono_c0 <- summarise_monotonicity(
      fit,
      axis = "c0",
      direction = "nonincreasing",
      level = "feature"
    )
    mono_c0$expected_direction <- "nonincreasing"
    mono_q <- summarise_monotonicity(
      fit,
      axis = "q",
      direction = "nondecreasing",
      level = "feature"
    )
    mono_q$expected_direction <- "nondecreasing"
    monotonicity_rows[[i]] <- add_surface_labels(bind_rows_fill(list(mono_c0, mono_q)), labels)

    pr <- precision_recall_curve_fda(
      fit,
      truth = sim,
      level = "feature",
      threshold_grid = threshold_grid
    )
    pr <- add_surface_labels(pr, labels)
    precision_recall_rows[[i]] <- pr

    best <- best_threshold_fda(pr, metric = "f1")
    best$threshold_type <- if (nrow(best) > 0L) "best_f1" else character()
    fixed <- fixed_threshold_rows(pr, thresholds = fixed_thresholds)
    threshold_rows[[i]] <- add_surface_labels(bind_rows_fill(list(best, fixed)), labels)

    if (nrow(fit$warnings) > 0L) {
      warning_rows[[i]] <- add_surface_labels(fit$warnings, labels)
    }
  }

  list(
    surface_summary = bind_rows_fill(surface_rows),
    monotonicity_summary = bind_rows_fill(monotonicity_rows),
    precision_recall_paths = bind_rows_fill(precision_recall_rows),
    best_thresholds = bind_rows_fill(threshold_rows),
    warnings = bind_rows_fill(warning_rows),
    fits = fits
  )
}

mean_or_na <- function(values) {
  values <- as.numeric(values)
  if (all(is.na(values))) {
    return(NA_real_)
  }
  mean(values, na.rm = TRUE)
}

max_or_na <- function(values) {
  values <- as.numeric(values)
  if (all(is.na(values))) {
    return(NA_real_)
  }
  max(values, na.rm = TRUE)
}

sd_or_zero <- function(values) {
  values <- as.numeric(values)
  values <- values[!is.na(values)]
  if (length(values) <= 1L) {
    return(0)
  }
  stats::sd(values)
}

interaction_key <- function(data) {
  data <- as.data.frame(data, stringsAsFactors = FALSE)
  for (name in names(data)) {
    values <- data[[name]]
    if (is.factor(values)) {
      values <- as.character(values)
    }
    values <- as.character(values)
    values[is.na(values)] <- "<NA>"
    data[[name]] <- values
  }
  interaction(data, drop = TRUE, lex.order = TRUE)
}

build_scenario_summary <- function(summary_by_setting) {
  data <- as.data.frame(summary_by_setting, stringsAsFactors = FALSE)
  if (nrow(data) == 0L) {
    return(data.frame())
  }

  by_cols <- intersect(c("noise_axis", "snr", "noise_sd", "scenario", "method", "level"), names(data))
  metric_bases <- c(
    "precision", "recall", "specificity", "f1", "jaccard",
    "selection_rate", "n_selected", "fp"
  )
  metric_bases <- metric_bases[paste0(metric_bases, "_mean") %in% names(data)]
  split_keys <- interaction_key(data[by_cols])

  do.call(rbind, lapply(split(seq_len(nrow(data)), split_keys), function(idx) {
    part <- data[idx, , drop = FALSE]
    out <- part[1, by_cols, drop = FALSE]
    out$n_settings <- nrow(part)
    if ("effective_snr_mean" %in% names(part)) {
      out$effective_snr <- mean_or_na(part$effective_snr_mean)
    }
    if ("effective_variance_snr_mean" %in% names(part)) {
      out$effective_variance_snr <- mean_or_na(part$effective_variance_snr_mean)
    }
    for (metric in metric_bases) {
      values <- part[[paste0(metric, "_mean")]]
      out[[paste0(metric, "_mean")]] <- mean_or_na(values)
      out[[paste0(metric, "_sd")]] <- sd_or_zero(values)
      out[[paste0(metric, "_se")]] <- out[[paste0(metric, "_sd")]] / sqrt(pmax(out$n_settings, 1L))
    }
    out
  }))
}

build_size_resolution_summary <- function(summary_by_setting) {
  data <- as.data.frame(summary_by_setting, stringsAsFactors = FALSE)
  if (nrow(data) == 0L || !all(c("n", "grid_length") %in% names(data))) {
    return(data.frame())
  }

  by_cols <- intersect(c("n", "grid_length", "noise_axis", "snr", "noise_sd", "representation", "method", "level"), names(data))
  metric_bases <- c(
    "precision", "recall", "specificity", "f1", "jaccard",
    "selection_rate", "n_selected", "fp"
  )
  metric_bases <- metric_bases[paste0(metric_bases, "_mean") %in% names(data)]
  split_keys <- interaction_key(data[by_cols])

  do.call(rbind, lapply(split(seq_len(nrow(data)), split_keys), function(idx) {
    part <- data[idx, , drop = FALSE]
    out <- part[1, by_cols, drop = FALSE]
    out$n_settings <- nrow(part)
    if ("effective_snr_mean" %in% names(part)) {
      out$effective_snr <- mean_or_na(part$effective_snr_mean)
    }
    if ("effective_variance_snr_mean" %in% names(part)) {
      out$effective_variance_snr <- mean_or_na(part$effective_variance_snr_mean)
    }
    for (metric in metric_bases) {
      values <- part[[paste0(metric, "_mean")]]
      out[[paste0(metric, "_mean")]] <- mean_or_na(values)
      out[[paste0(metric, "_sd")]] <- sd_or_zero(values)
      out[[paste0(metric, "_se")]] <- out[[paste0(metric, "_sd")]] / sqrt(pmax(out$n_settings, 1L))
    }
    out
  }))
}

build_noise_summary <- function(summary_by_setting) {
  data <- as.data.frame(summary_by_setting, stringsAsFactors = FALSE)
  if (nrow(data) == 0L || !"noise_axis" %in% names(data)) {
    return(data.frame())
  }

  by_cols <- intersect(
    c("noise_axis", "snr", "noise_sd", "scenario", "representation", "method", "level"),
    names(data)
  )
  metric_bases <- c(
    "precision", "recall", "specificity", "f1", "jaccard",
    "selection_rate", "n_selected", "fp"
  )
  metric_bases <- metric_bases[paste0(metric_bases, "_mean") %in% names(data)]
  split_keys <- interaction_key(data[by_cols])

  do.call(rbind, lapply(split(seq_len(nrow(data)), split_keys), function(idx) {
    part <- data[idx, , drop = FALSE]
    out <- part[1, by_cols, drop = FALSE]
    out$n_settings <- nrow(part)
    if ("effective_snr_mean" %in% names(part)) {
      out$effective_snr <- mean_or_na(part$effective_snr_mean)
    }
    if ("effective_variance_snr_mean" %in% names(part)) {
      out$effective_variance_snr <- mean_or_na(part$effective_variance_snr_mean)
    }
    for (metric in metric_bases) {
      values <- part[[paste0(metric, "_mean")]]
      out[[paste0(metric, "_mean")]] <- mean_or_na(values)
      out[[paste0(metric, "_sd")]] <- sd_or_zero(values)
      out[[paste0(metric, "_se")]] <- out[[paste0(metric, "_sd")]] / sqrt(pmax(out$n_settings, 1L))
    }
    out
  }))
}

build_noise_f1_gain_panel <- function(paired_gain_summary,
                                      level = "feature") {
  data <- as.data.frame(paired_gain_summary, stringsAsFactors = FALSE)
  if (nrow(data) == 0L || !"noise_axis" %in% names(data) ||
      !"paired_gain_mean" %in% names(data)) {
    return(data.frame())
  }

  if ("level" %in% names(data)) {
    data <- data[data$level == level, , drop = FALSE]
  }
  if ("reference" %in% names(data)) {
    data <- data[data$reference == "plain_selectboost", , drop = FALSE]
  }
  if (nrow(data) == 0L) {
    return(data.frame())
  }

  by_cols <- intersect(
    c("noise_axis", "snr", "noise_sd", "scenario", "representation", "level", "target", "reference", "metric"),
    names(data)
  )
  split_keys <- interaction_key(data[by_cols])

  do.call(rbind, lapply(split(seq_len(nrow(data)), split_keys), function(idx) {
    part <- data[idx, , drop = FALSE]
    out <- part[1, by_cols, drop = FALSE]
    out$n_settings <- nrow(part)
    if ("effective_snr" %in% names(part)) {
      out$effective_snr <- mean_or_na(part$effective_snr)
    }
    if ("effective_variance_snr" %in% names(part)) {
      out$effective_variance_snr <- mean_or_na(part$effective_variance_snr)
    }
    out$f1_gain_mean <- mean_or_na(part$paired_gain_mean)
    out$f1_gain_sd <- sd_or_zero(part$paired_gain_mean)
    out$f1_gain_se <- out$f1_gain_sd / sqrt(pmax(out$n_settings, 1L))
    out$win_rate_mean <- mean_or_na(part$win_rate)
    out$target_f1_mean <- mean_or_na(part$target_value_mean)
    out$reference_f1_mean <- mean_or_na(part$reference_value_mean)
    out
  }))
}

build_runtime_by_size_resolution <- function(metrics) {
  data <- as.data.frame(metrics, stringsAsFactors = FALSE)
  required <- c("n", "grid_length", "simulation_elapsed", "benchmark_elapsed", "setting_elapsed")
  if (nrow(data) == 0L || !all(required %in% names(data))) {
    return(data.frame())
  }

  setting_cols <- intersect(
    c(
      "replicate", "n", "grid_length", "noise_axis", "snr", "noise_sd",
      "scenario", "representation",
      "association_method", "bandwidth", "simulation_seed", "benchmark_seed",
      "simulation_elapsed", "benchmark_elapsed", "setting_elapsed"
    ),
    names(data)
  )
  settings <- unique(data[setting_cols])
  by_cols <- intersect(
    c("n", "grid_length", "noise_axis", "snr", "noise_sd", "scenario", "representation", "association_method", "bandwidth"),
    names(settings)
  )
  split_keys <- interaction_key(settings[by_cols])
  metric_bases <- c("simulation_elapsed", "benchmark_elapsed", "setting_elapsed")

  do.call(rbind, lapply(split(seq_len(nrow(settings)), split_keys), function(idx) {
    part <- settings[idx, , drop = FALSE]
    out <- part[1, by_cols, drop = FALSE]
    out$n_settings <- nrow(part)
    out$n_rep <- length(unique(part$replicate))
    for (metric in metric_bases) {
      values <- as.numeric(part[[metric]])
      out[[paste0(metric, "_mean")]] <- mean_or_na(values)
      out[[paste0(metric, "_sd")]] <- sd_or_zero(values)
      out[[paste0(metric, "_se")]] <- out[[paste0(metric, "_sd")]] / sqrt(pmax(out$n_settings, 1L))
      out[[paste0(metric, "_total")]] <- sum(values, na.rm = TRUE)
    }
    out
  }))
}

first_or_na <- function(values) {
  if (is.null(values) || length(values) == 0L) {
    return(NA)
  }
  values <- values[!is.na(values)]
  if (length(values) == 0L) {
    return(NA)
  }
  values[[1L]]
}

build_runtime_by_setting <- function(metrics) {
  data <- as.data.frame(metrics, stringsAsFactors = FALSE)
  if (nrow(data) == 0L || !"setting_elapsed" %in% names(data)) {
    return(data.frame())
  }

  feature_rows <- if ("level" %in% names(data)) {
    rows <- data[data$level == "feature", , drop = FALSE]
    if (nrow(rows) == 0L) data else rows
  } else {
    data
  }

  defaults <- list(
    runtime_status = "completed",
    n_warnings = 0L,
    n_failures = 0L,
    warning_messages = NA_character_,
    error_message = NA_character_,
    failure_stage = NA_character_,
    simulation_user = NA_real_,
    simulation_system = NA_real_,
    benchmark_user = NA_real_,
    benchmark_system = NA_real_,
    setting_user = NA_real_,
    setting_system = NA_real_,
    result_size_mb = NA_real_,
    n_selected = NA_real_
  )
  for (name in names(defaults)) {
    if (!name %in% names(feature_rows)) {
      feature_rows[[name]] <- defaults[[name]]
    }
  }

  by_cols <- intersect(
    c(
      "replicate", "method", "scenario", "representation", "family",
      "n", "grid_length", "noise_axis", "snr", "noise_sd",
      "confounding_strength", "active_region_scale", "local_correlation",
      "association_method", "bandwidth", "simulation_seed", "benchmark_seed",
      "selector", "B", "steps.seq"
    ),
    names(feature_rows)
  )
  split_keys <- interaction_key(feature_rows[by_cols])

  bind_rows_fill(lapply(split(seq_len(nrow(feature_rows)), split_keys), function(idx) {
    part <- feature_rows[idx, , drop = FALSE]
    out <- part[1, by_cols, drop = FALSE]
    out$runtime_source <- "main_benchmark"
    out$n_runtime_rows <- nrow(part)
    out$runtime_status <- if (any(part$runtime_status == "failed", na.rm = TRUE)) "failed" else "completed"
    out$n_failures <- sum(as.numeric(part$n_failures), na.rm = TRUE)
    warning_counts <- as.numeric(part$n_warnings)
    out$n_warnings <- if (all(is.na(warning_counts))) NA_real_ else max(warning_counts, na.rm = TRUE)
    out$warning_messages <- paste(unique(stats::na.omit(part$warning_messages)), collapse = " | ")
    if (!nzchar(out$warning_messages)) {
      out$warning_messages <- NA_character_
    }
    out$error_message <- paste(unique(stats::na.omit(part$error_message)), collapse = " | ")
    if (!nzchar(out$error_message)) {
      out$error_message <- NA_character_
    }
    out$failure_stage <- first_or_na(part$failure_stage)
    out$simulation_user <- as.numeric(first_or_na(part$simulation_user))
    out$simulation_system <- as.numeric(first_or_na(part$simulation_system))
    out$simulation_elapsed <- as.numeric(first_or_na(part$simulation_elapsed))
    out$benchmark_user <- as.numeric(first_or_na(part$benchmark_user))
    out$benchmark_system <- as.numeric(first_or_na(part$benchmark_system))
    out$benchmark_elapsed <- as.numeric(first_or_na(part$benchmark_elapsed))
    out$setting_user <- as.numeric(first_or_na(part$setting_user))
    out$setting_system <- as.numeric(first_or_na(part$setting_system))
    out$setting_elapsed <- as.numeric(first_or_na(part$setting_elapsed))
    out$n_selected_features_mean <- mean_or_na(part$n_selected)
    out$n_selected_features_max <- max_or_na(part$n_selected)
    out$memory_mb <- as.numeric(first_or_na(part$result_size_mb))
    out
  }))
}

build_runtime_by_method <- function(runtime_by_setting,
                                    method_runtime,
                                    method_comparison_summary = data.frame()) {
  canonical_rows <- list()
  row_index <- 0L

  setting <- as.data.frame(runtime_by_setting, stringsAsFactors = FALSE)
  if (nrow(setting) > 0L) {
    row_index <- row_index + 1L
    canonical_rows[[row_index]] <- data.frame(
      runtime_source = "main_benchmark",
      method = setting$method,
      perturbation_type = NA_character_,
      base_selector = NA_character_,
      selector_package = NA_character_,
      selector = setting$selector %||% NA_character_,
      status = setting$runtime_status,
      user = setting$setting_user,
      system = setting$setting_system,
      elapsed = setting$setting_elapsed,
      n_warnings = setting$n_warnings,
      n_failures = setting$n_failures,
      n_selected_features = setting$n_selected_features_mean,
      memory_mb = setting$memory_mb,
      stringsAsFactors = FALSE
    )
  }

  method_runtime <- as.data.frame(method_runtime, stringsAsFactors = FALSE)
  if (nrow(method_runtime) > 0L) {
    selected_summary <- as.data.frame(method_comparison_summary, stringsAsFactors = FALSE)
    if (nrow(selected_summary) > 0L && all(c("method", "level", "n_selected_mean") %in% names(selected_summary))) {
      selected_summary <- selected_summary[selected_summary$level == "feature", , drop = FALSE]
      selected_by_method <- aggregate(
        n_selected_mean ~ method,
        data = selected_summary,
        FUN = function(x) mean_or_na(x)
      )
    } else {
      selected_by_method <- data.frame(method = unique(method_runtime$method), n_selected_mean = NA_real_)
    }
    method_part <- merge(method_runtime, selected_by_method, by = "method", all.x = TRUE, sort = FALSE)
    row_index <- row_index + 1L
    canonical_rows[[row_index]] <- data.frame(
      runtime_source = "method_comparison",
      method = method_part$method,
      perturbation_type = method_part$perturbation_type %||% NA_character_,
      base_selector = method_part$base_selector %||% NA_character_,
      selector_package = method_part$selector_package %||% NA_character_,
      selector = method_part$selector %||% NA_character_,
      status = method_part$method_status,
      user = method_part$method_user,
      system = method_part$method_system,
      elapsed = method_part$method_elapsed,
      n_warnings = method_part$n_warnings,
      n_failures = method_part$n_failures,
      n_selected_features = method_part$n_selected_mean,
      memory_mb = method_part$fit_object_size_mb,
      stringsAsFactors = FALSE
    )
  }

  canonical <- bind_rows_fill(canonical_rows)
  if (nrow(canonical) == 0L) {
    return(data.frame())
  }

  by_cols <- c("runtime_source", "method", "perturbation_type", "base_selector", "selector_package", "selector")
  split_keys <- interaction_key(canonical[by_cols])
  bind_rows_fill(lapply(split(seq_len(nrow(canonical)), split_keys), function(idx) {
    part <- canonical[idx, , drop = FALSE]
    out <- part[1, by_cols, drop = FALSE]
    out$n_settings <- nrow(part)
    out$n_completed <- sum(part$status == "completed", na.rm = TRUE)
    out$n_failed <- sum(part$status == "failed", na.rm = TRUE)
    out$n_skipped <- sum(part$status == "skipped", na.rm = TRUE)
    out$n_failures <- sum(as.numeric(part$n_failures), na.rm = TRUE)
    out$n_warnings <- sum(as.numeric(part$n_warnings), na.rm = TRUE)
    out$elapsed_mean <- mean_or_na(part$elapsed)
    out$elapsed_sd <- sd_or_zero(part$elapsed)
    out$elapsed_se <- out$elapsed_sd / sqrt(pmax(sum(!is.na(part$elapsed)), 1L))
    out$elapsed_total <- sum(as.numeric(part$elapsed), na.rm = TRUE)
    out$user_mean <- mean_or_na(part$user)
    out$user_total <- sum(as.numeric(part$user), na.rm = TRUE)
    out$system_mean <- mean_or_na(part$system)
    out$system_total <- sum(as.numeric(part$system), na.rm = TRUE)
    out$n_selected_features_mean <- mean_or_na(part$n_selected_features)
    out$n_selected_features_max <- max_or_na(part$n_selected_features)
    out$memory_mb_mean <- mean_or_na(part$memory_mb)
    out$memory_mb_max <- max_or_na(part$memory_mb)
    out
  }))
}

build_assessment_representation_table <- function(representation_summary,
                                              paired_gain_summary,
                                              level = "feature") {
  summary <- as.data.frame(representation_summary, stringsAsFactors = FALSE)
  summary <- summary[summary$level == level, , drop = FALSE]
  if (nrow(summary) == 0L) {
    return(data.frame())
  }

  join_cols <- intersect(c("representation", "noise_axis", "snr", "noise_sd"), names(summary))
  fda <- summary[summary$method == "selectboost", c(join_cols, "f1_mean", "f1_sd"), drop = FALSE]
  plain <- summary[summary$method == "plain_selectboost", c(join_cols, "f1_mean", "f1_sd"), drop = FALSE]
  names(fda)[names(fda) == "f1_mean"] <- "selectboost_f1_mean"
  names(fda)[names(fda) == "f1_sd"] <- "selectboost_f1_sd"
  names(plain)[names(plain) == "f1_mean"] <- "plain_selectboost_f1_mean"
  names(plain)[names(plain) == "f1_sd"] <- "plain_selectboost_f1_sd"

  out <- merge(fda, plain, by = join_cols, all = TRUE, sort = FALSE)

  gain <- as.data.frame(paired_gain_summary, stringsAsFactors = FALSE)
  gain <- gain[gain$level == level & gain$reference == "plain_selectboost", , drop = FALSE]
  if (nrow(gain) > 0L) {
    gain_cols <- intersect(c("representation", "noise_axis", "snr", "noise_sd"), names(gain))
    gain_keys <- interaction_key(gain[gain_cols])
    gain_summary <- do.call(rbind, lapply(split(seq_len(nrow(gain)), gain_keys), function(idx) {
      part <- gain[idx, , drop = FALSE]
      out <- part[1, gain_cols, drop = FALSE]
      data.frame(
        out,
        delta_mean = mean(part$paired_gain_mean, na.rm = TRUE),
        delta_sd = if (nrow(part) > 1L) stats::sd(part$paired_gain_mean, na.rm = TRUE) else 0,
        win_rate = mean(part$win_rate, na.rm = TRUE),
        n_settings = nrow(part),
        stringsAsFactors = FALSE
      )
    }))
    out <- merge(out, gain_summary, by = intersect(join_cols, names(gain_summary)), all.x = TRUE, sort = FALSE)
  }

  out$level <- level
  out$representation_label <- ifelse(
    out$representation == "bspline",
    "B-spline",
    ifelse(out$representation == "fpca", "FPCA", "Grid")
  )
  out[, unique(c(
    "representation", "representation_label", "level", "n_settings",
    "noise_axis", "snr", "noise_sd",
    "selectboost_f1_mean", "selectboost_f1_sd",
    "plain_selectboost_f1_mean", "plain_selectboost_f1_sd",
    "delta_mean", "delta_sd", "win_rate"
  )), drop = FALSE]
}

args <- parse_cli_args(commandArgs(trailingOnly = TRUE))
if (!isTRUE(args$assessment_summary)) {
  args$save_surfaces <- FALSE
  args$save_association_diagnostics <- FALSE
}
project_root <- load_package_from_script()
package_version <- as.character(utils::packageVersion("SelectBoost.FDA"))
git_commit <- detect_git_commit(project_root)
rng_backend <- if (isTRUE(args$deterministic_rng)) {
  "base_r_deterministic_vmf_shim"
} else {
  "upstream_rfast_rvmf"
}
restore_selectboost_rng <- install_deterministic_selectboost_rng(args$deterministic_rng)
on.exit(restore_selectboost_rng(), add = TRUE)

if (!nzchar(args$output_dir)) {
  env_dir <- Sys.getenv("SELECTBOOST_FDA_BENCHMARK_DIR", unset = "")
  args$output_dir <- if (nzchar(env_dir)) {
    env_dir
  } else {
    file.path(tempdir(), "selectboost_fda_focused_benchmark")
  }
}
dir.create(args$output_dir, recursive = TRUE, showWarnings = FALSE)
guard_run_markers(args$output_dir, resume = args$resume)
run_start_time <- Sys.time()
run_id <- make_run_id()
write_run_metadata(
  output_dir = args$output_dir,
  run_id = run_id,
  start_time = run_start_time,
  package_version = package_version,
  git_commit = git_commit,
  args = args
)
write_running_marker(args$output_dir, run_id = run_id, start_time = run_start_time)

methods <- method_names_for_existing_api(args$methods)
if (length(methods) == 0L) {
  stop("No supported methods were requested.", call. = FALSE)
}

quick <- isTRUE(args$quick)
simulate_base_grid <- apply_scenario_grid(
  default_simulate_base_grid(quick),
  args$scenario_grid
)

selectboost_grid <- build_selectboost_grid_from_cli(
  quick = quick,
  association_grid = args$association_grid,
  bandwidth_grid = args$bandwidth_grid
)

selectboost_steps <- args$c0_grid %||% if (quick) c(0.7, 0.4) else c(0.9, 0.7, 0.5, 0.3)
selectboost_reps <- if (quick) 2L else 4L
stability_reps <- if (quick) 4L else 8L
method_comparison_reps <- if (quick) 1L else min(3L, args$n_replicates)
method_comparison_selectboost_reps <- if (quick) 1L else 2L
method_comparison_stability_reps <- if (quick) 2L else 4L
sim_n <- if (quick) 24L else 50L
grid_length <- if (quick) 16L else 30L
if (is.null(args$n_grid)) {
  args$n_grid <- sim_n
}
if (is.null(args$grid_length_grid)) {
  args$grid_length_grid <- grid_length
}

simulate_size_base_grid <- expand.grid(
  representation = args$representation_grid,
  n = args$n_grid,
  grid_length = args$grid_length_grid,
  stringsAsFactors = FALSE
)
noise_grid <- data.frame(
  noise_axis = "default",
  snr = NA_real_,
  noise_sd = NA_real_,
  stringsAsFactors = FALSE
)
if (!is.null(args$snr_grid) || !is.null(args$noise_sd_grid)) {
  noise_parts <- list()
  if (!is.null(args$snr_grid)) {
    noise_parts[[length(noise_parts) + 1L]] <- data.frame(
      noise_axis = "snr",
      snr = args$snr_grid,
      noise_sd = NA_real_,
      stringsAsFactors = FALSE
    )
  }
  if (!is.null(args$noise_sd_grid)) {
    noise_parts[[length(noise_parts) + 1L]] <- data.frame(
      noise_axis = "noise_sd",
      snr = NA_real_,
      noise_sd = args$noise_sd_grid,
      stringsAsFactors = FALSE
    )
  }
  noise_grid <- do.call(rbind, noise_parts)
}

simulate_size_grid <- do.call(rbind, lapply(seq_len(nrow(noise_grid)), function(i) {
  cbind(
    simulate_size_base_grid,
    noise_grid[rep(i, nrow(simulate_size_base_grid)), , drop = FALSE]
  )
}))
rownames(simulate_size_grid) <- NULL

simulate_grid <- do.call(rbind, lapply(seq_len(nrow(simulate_base_grid)), function(i) {
  cbind(
    simulate_size_grid,
    simulate_base_grid[rep(i, nrow(simulate_size_grid)), , drop = FALSE]
  )
}))
simulate_grid <- simulate_grid[
  ,
  c(
    "representation", "n", "grid_length", "noise_axis", "snr", "noise_sd",
    setdiff(names(simulate_grid), c("representation", "n", "grid_length", "noise_axis", "snr", "noise_sd"))
  ),
  drop = FALSE
]

progress_callback <- make_focused_progress_callback(
  output_dir = args$output_dir,
  baseline_name = baseline_name,
  package_version = package_version,
  git_commit = git_commit,
  seed = args$seed,
  rng_backend = rng_backend,
  selectboost_reps = selectboost_reps,
  stability_reps = stability_reps,
  selectboost_steps = selectboost_steps,
  checkpoint_every = args$checkpoint_every,
  resume = args$resume
)

timing <- system.time({
  study <- run_selectboost_sensitivity_study(
    n_rep = args$n_replicates,
    simulate_grid = simulate_grid,
    selectboost_grid = selectboost_grid,
    simulate_args = list(
      n = sim_n,
      grid_length = grid_length
    ),
    benchmark_args = list(
      methods = methods,
      levels = c("feature", "group", "basis"),
      stability_args = list(
        selector = "lasso",
        B = stability_reps,
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
    keep_results = FALSE,
    progress = progress_callback
  )
})

summary_by_setting <- as_benchmark_summary_data(study, select_c0 = "best")
summary_by_setting <- add_standard_errors(summary_by_setting)
feature_performance <- summarise_benchmark_performance(
  study,
  level = "feature",
  metric = "f1"
)
feature_performance <- add_standard_errors(feature_performance)
feature_advantage <- if (all(c("selectboost", "plain_selectboost") %in% unique(study$metrics$method))) {
  add_standard_errors(summarise_benchmark_advantage(
    study,
    target = "selectboost",
    reference = "plain_selectboost",
    level = "feature",
    metric = "f1"
  ))
} else {
  data.frame()
}
paired_gain <- build_paired_gain_summary(
  study,
  levels = c("feature", "group", "basis"),
  bootstrap_replicates = args$bootstrap_replicates,
  confidence = 0.95
)
paired_gain_summary <- paired_gain$summary
paired_gain_bootstrap_ci <- paired_gain$bootstrap_ci
representation_summary <- add_standard_errors(build_representation_summary(summary_by_setting))
scenario_summary <- build_scenario_summary(summary_by_setting)
size_resolution_summary <- build_size_resolution_summary(summary_by_setting)
noise_summary <- build_noise_summary(summary_by_setting)
runtime_by_size_resolution <- build_runtime_by_size_resolution(study$metrics)
assessment_representation_table <- build_assessment_representation_table(
  representation_summary = representation_summary,
  paired_gain_summary = paired_gain_summary,
  level = "feature"
)
noise_f1_gain_panel <- build_noise_f1_gain_panel(paired_gain_summary, level = "feature")
assessment_top_positive_settings <- build_assessment_top_positive_settings(paired_gain_summary, level = "feature")
assessment_negative_gain_settings <- build_assessment_negative_gain_settings(paired_gain_summary, level = "feature")
assessment_all_setting_summary <- build_assessment_all_setting_summary(paired_gain_summary, level = "feature")
assessment_failure_modes <- build_assessment_failure_modes(paired_gain_summary, level = "feature")
best_settings <- add_standard_errors(make_best_settings(feature_advantage, feature_performance))
precision_recall_paths <- as_precision_recall_path_data(study)
method_comparison_grid <- method_comparison_simulation_grid(
  simulate_grid = simulate_grid,
  sim_n = sim_n,
  grid_length = grid_length,
  quick = quick
)
method_comparison_artifacts <- run_method_comparison_study(
  simulate_grid = method_comparison_grid,
  selectboost_grid = selectboost_grid,
  simulate_args = list(
    n = sim_n,
    grid_length = grid_length
  ),
  selectboost_steps = selectboost_steps,
  n_rep = method_comparison_reps,
  seed = args$seed + 3000L,
  selectboost_B = method_comparison_selectboost_reps,
  stability_B = method_comparison_stability_reps,
  stability_cutoff = 0.5,
  levels = c("feature", "group", "basis")
)
method_comparison_summary <- method_comparison_artifacts$summary
method_comparison_runtime <- method_comparison_artifacts$runtime
assessment_method_comparison_table <- method_comparison_artifacts$assessment_table
association_artifacts <- build_association_diagnostic_artifacts(
  simulate_grid = simulate_grid,
  selectboost_grid = selectboost_grid,
  simulate_args = list(
    n = sim_n,
    grid_length = grid_length
  ),
  c0_grid = selectboost_steps,
  seed = args$seed + 2000L,
  within_blocks = TRUE
)
if (!isTRUE(args$save_association_diagnostics)) {
  association_artifacts <- list(
    diagnostics = data.frame(),
    group_sizes = data.frame(),
    assessment_table = data.frame()
  )
}
association_diagnostics <- association_artifacts$diagnostics
association_group_size_summary <- association_artifacts$group_sizes
assessment_association_comparison_table <- association_artifacts$assessment_table

surface_q_grid <- args$q_grid %||% if (quick) c(0.5, 0.8) else c(0.5, 0.632, 0.8)
surface_c0_grid <- args$c0_grid %||% if (quick) c(0.7, 0.4) else c(0.9, 0.7, 0.5, 0.3)
surface_reps <- if (quick) 1L else 3L
surface_selectboost_reps <- 1L
main_surface_row <- simulate_grid[1L, , drop = FALSE]
surface_sim_n <- if (isTRUE(args$surface_use_main_settings)) {
  as.integer(main_surface_row$n)
} else {
  sim_n
}
surface_grid_length <- if (isTRUE(args$surface_use_main_settings)) {
  as.integer(main_surface_row$grid_length)
} else {
  grid_length
}
surface_noise_axis <- if (isTRUE(args$surface_use_main_settings)) {
  as.character(main_surface_row$noise_axis)
} else {
  "default"
}
surface_snr <- if (isTRUE(args$surface_use_main_settings)) {
  suppressWarnings(as.numeric(main_surface_row$snr))
} else {
  NA_real_
}
surface_noise_sd <- if (isTRUE(args$surface_use_main_settings)) {
  suppressWarnings(as.numeric(main_surface_row$noise_sd))
} else {
  NA_real_
}
surface_design_source <- if (isTRUE(args$surface_use_main_settings)) {
  "main_grid_representative"
} else {
  "quick_diagnostic"
}
surface_inherits_main_n <- identical(as.integer(surface_sim_n), as.integer(main_surface_row$n))
surface_inherits_main_grid_length <- identical(as.integer(surface_grid_length), as.integer(main_surface_row$grid_length))
surface_inherits_main_noise <- identical(as.character(surface_noise_axis), as.character(main_surface_row$noise_axis)) &&
  identical(as.numeric(surface_snr), as.numeric(main_surface_row$snr)) &&
  identical(as.numeric(surface_noise_sd), as.numeric(main_surface_row$noise_sd))
surface_artifacts <- if (isTRUE(args$save_surfaces)) {
  build_assessment_surface_artifacts(
    surface_grid = filtered_surface_scenario_grid(
      scenario_grid = args$scenario_grid,
      representation_grid = args$representation_grid
    ),
    sim_n = surface_sim_n,
    grid_length = surface_grid_length,
    noise_axis = surface_noise_axis,
    snr = surface_snr,
    noise_sd = surface_noise_sd,
    surface_design_source = surface_design_source,
    surface_inherits_main_n = surface_inherits_main_n,
    surface_inherits_main_grid_length = surface_inherits_main_grid_length,
    surface_inherits_main_noise = surface_inherits_main_noise,
    q_grid = surface_q_grid,
    c0_grid = surface_c0_grid,
    B = surface_reps,
    selectboost_B = surface_selectboost_reps,
    seed = args$seed + 1000L
  )
} else {
  list(
    surface_summary = data.frame(),
    monotonicity_summary = data.frame(),
    precision_recall_paths = data.frame(),
    best_thresholds = data.frame(),
    warnings = data.frame(),
    fits = list()
  )
}
assessment_surface_summary <- surface_artifacts$surface_summary
assessment_monotonicity_summary <- surface_artifacts$monotonicity_summary
assessment_precision_recall_paths <- surface_artifacts$precision_recall_paths
assessment_best_thresholds <- surface_artifacts$best_thresholds
assessment_surface_warnings <- surface_artifacts$warnings
valid_surface_fits <- Filter(function(x) inherits(x, "fda_perturbation_grid"), surface_artifacts$fits)
surface_fit <- if (length(valid_surface_fits) > 0L) valid_surface_fits[[1L]] else NULL
monotonicity_summary <- assessment_monotonicity_summary
precision_recall_paths <- bind_rows_fill(list(precision_recall_paths, assessment_precision_recall_paths))

runtime_summary <- data.frame(
  baseline_name = baseline_name,
  package_version = package_version,
  git_commit = git_commit,
  seed = args$seed,
  n_replicates = args$n_replicates,
  run_profile = args$profile,
  rng_backend = rng_backend,
  user = unname(timing[["user.self"]]),
  system = unname(timing[["sys.self"]]),
  elapsed = unname(timing[["elapsed"]]),
  n_failures = nrow(assessment_surface_warnings),
  stringsAsFactors = FALSE
)

study$metrics <- add_benchmark_metadata(
  study$metrics, baseline_name, package_version, git_commit, args$seed,
  selectboost_reps, stability_reps, selectboost_steps, rng_backend
)
summary_by_setting <- add_benchmark_metadata(
  summary_by_setting, baseline_name, package_version, git_commit, args$seed,
  selectboost_reps, stability_reps, selectboost_steps, rng_backend,
  default_replicate = "all"
)
best_settings <- add_benchmark_metadata(
  best_settings, baseline_name, package_version, git_commit, args$seed,
  selectboost_reps, stability_reps, selectboost_steps, rng_backend,
  default_method = "selectboost_vs_plain_selectboost",
  default_replicate = "all"
)
paired_gain_summary <- add_benchmark_metadata(
  paired_gain_summary, baseline_name, package_version, git_commit, args$seed,
  selectboost_reps, stability_reps, selectboost_steps, rng_backend,
  default_method = "selectboost_vs_plain_selectboost",
  default_replicate = "all"
)
paired_gain_bootstrap_ci <- add_benchmark_metadata(
  paired_gain_bootstrap_ci, baseline_name, package_version, git_commit, args$seed,
  selectboost_reps, stability_reps, selectboost_steps, rng_backend,
  default_method = "selectboost_vs_plain_selectboost",
  default_replicate = "all"
)
assessment_top_positive_settings <- add_benchmark_metadata(
  assessment_top_positive_settings, baseline_name, package_version, git_commit, args$seed,
  selectboost_reps, stability_reps, selectboost_steps, rng_backend,
  default_method = "selectboost_vs_plain_selectboost",
  default_replicate = "all"
)
assessment_negative_gain_settings <- add_benchmark_metadata(
  assessment_negative_gain_settings, baseline_name, package_version, git_commit, args$seed,
  selectboost_reps, stability_reps, selectboost_steps, rng_backend,
  default_method = "selectboost_vs_plain_selectboost",
  default_replicate = "all"
)
assessment_all_setting_summary <- add_benchmark_metadata(
  assessment_all_setting_summary, baseline_name, package_version, git_commit, args$seed,
  selectboost_reps, stability_reps, selectboost_steps, rng_backend,
  default_method = "selectboost_vs_plain_selectboost",
  default_scenario = "all",
  default_representation = "all",
  default_association = "all",
  default_replicate = "all"
)
assessment_failure_modes <- add_benchmark_metadata(
  assessment_failure_modes, baseline_name, package_version, git_commit, args$seed,
  selectboost_reps, stability_reps, selectboost_steps, rng_backend,
  default_method = "selectboost_vs_plain_selectboost",
  default_replicate = "all"
)
assessment_surface_summary <- add_benchmark_metadata(
  assessment_surface_summary, baseline_name, package_version, git_commit, args$seed,
  selectboost_reps, stability_reps, selectboost_steps, rng_backend,
  default_method = "selectboost_surface",
  default_replicate = "all"
)
assessment_monotonicity_summary <- add_benchmark_metadata(
  assessment_monotonicity_summary, baseline_name, package_version, git_commit, args$seed,
  selectboost_reps, stability_reps, selectboost_steps, rng_backend,
  default_method = "selectboost_surface",
  default_replicate = "all"
)
assessment_precision_recall_paths <- add_benchmark_metadata(
  assessment_precision_recall_paths, baseline_name, package_version, git_commit, args$seed,
  selectboost_reps, stability_reps, selectboost_steps, rng_backend,
  default_method = "selectboost_surface"
)
assessment_best_thresholds <- add_benchmark_metadata(
  assessment_best_thresholds, baseline_name, package_version, git_commit, args$seed,
  selectboost_reps, stability_reps, selectboost_steps, rng_backend,
  default_method = "selectboost_surface",
  default_replicate = "all"
)
association_diagnostics <- add_benchmark_metadata(
  association_diagnostics, baseline_name, package_version, git_commit, args$seed,
  selectboost_reps, stability_reps, selectboost_steps, rng_backend,
  default_method = "association_diagnostic",
  default_replicate = "diagnostic"
)
association_group_size_summary <- add_benchmark_metadata(
  association_group_size_summary, baseline_name, package_version, git_commit, args$seed,
  selectboost_reps, stability_reps, selectboost_steps, rng_backend,
  default_method = "association_group_size",
  default_replicate = "diagnostic"
)
assessment_association_comparison_table <- add_benchmark_metadata(
  assessment_association_comparison_table, baseline_name, package_version, git_commit, args$seed,
  selectboost_reps, stability_reps, selectboost_steps, rng_backend,
  default_method = "association_comparison",
  default_scenario = "all",
  default_n = "all",
  default_grid_length = "all",
  default_noise_axis = "all",
  default_association = "all",
  default_replicate = "diagnostic"
)
method_comparison_summary <- add_benchmark_metadata(
  method_comparison_summary, baseline_name, package_version, git_commit, args$seed,
  selectboost_reps, stability_reps, selectboost_steps, rng_backend,
  default_method = "method_comparison",
  default_replicate = "all"
)
method_comparison_runtime <- add_benchmark_metadata(
  method_comparison_runtime, baseline_name, package_version, git_commit, args$seed,
  selectboost_reps, stability_reps, selectboost_steps, rng_backend,
  default_method = "method_comparison",
  default_replicate = "all"
)
assessment_method_comparison_table <- add_benchmark_metadata(
  assessment_method_comparison_table, baseline_name, package_version, git_commit, args$seed,
  selectboost_reps, stability_reps, selectboost_steps, rng_backend,
  default_method = "method_comparison",
  default_scenario = "all",
  default_representation = "all",
  default_n = "all",
  default_grid_length = "all",
  default_noise_axis = "all",
  default_association = "all",
  default_replicate = "all"
)
runtime_by_setting <- build_runtime_by_setting(study$metrics)
runtime_by_method <- build_runtime_by_method(
  runtime_by_setting = runtime_by_setting,
  method_runtime = method_comparison_runtime,
  method_comparison_summary = method_comparison_summary
)
runtime_summary$n_failures <- if ("n_failures" %in% names(runtime_by_setting)) {
  sum(as.numeric(runtime_by_setting$n_failures), na.rm = TRUE) + nrow(assessment_surface_warnings)
} else {
  nrow(assessment_surface_warnings)
}
runtime_summary$n_warnings <- if ("n_warnings" %in% names(runtime_by_setting)) {
  sum(as.numeric(runtime_by_setting$n_warnings), na.rm = TRUE) + nrow(assessment_surface_warnings)
} else {
  nrow(assessment_surface_warnings)
}
runtime_summary$n_selected_features_mean <- if ("n_selected_features_mean" %in% names(runtime_by_setting)) {
  mean_or_na(runtime_by_setting$n_selected_features_mean)
} else {
  NA_real_
}
runtime_summary$n_selected_features_max <- if ("n_selected_features_max" %in% names(runtime_by_setting)) {
  max_or_na(runtime_by_setting$n_selected_features_max)
} else {
  NA_real_
}
runtime_summary$memory_mb_mean <- if ("memory_mb" %in% names(runtime_by_setting)) {
  mean_or_na(runtime_by_setting$memory_mb)
} else {
  NA_real_
}
runtime_summary$memory_mb_max <- if ("memory_mb" %in% names(runtime_by_setting)) {
  max_or_na(runtime_by_setting$memory_mb)
} else {
  NA_real_
}
runtime_by_setting <- add_benchmark_metadata(
  runtime_by_setting, baseline_name, package_version, git_commit, args$seed,
  selectboost_reps, stability_reps, selectboost_steps, rng_backend
)
runtime_by_method <- add_benchmark_metadata(
  runtime_by_method, baseline_name, package_version, git_commit, args$seed,
  selectboost_reps, stability_reps, selectboost_steps, rng_backend,
  default_method = "runtime_by_method",
  default_scenario = "all",
  default_representation = "all",
  default_n = "all",
  default_grid_length = "all",
  default_noise_axis = "all",
  default_association = "all",
  default_replicate = "all"
)
precision_recall_paths <- add_benchmark_metadata(
  precision_recall_paths, baseline_name, package_version, git_commit, args$seed,
  selectboost_reps, stability_reps, selectboost_steps, rng_backend
)
monotonicity_summary <- add_benchmark_metadata(
  monotonicity_summary, baseline_name, package_version, git_commit, args$seed,
  selectboost_reps, stability_reps, selectboost_steps, rng_backend,
  default_replicate = "all"
)
runtime_summary <- add_benchmark_metadata(
  runtime_summary, baseline_name, package_version, git_commit, args$seed,
  selectboost_reps, stability_reps, selectboost_steps, rng_backend,
  default_noise_axis = "all",
  default_replicate = "all"
)
runtime_by_size_resolution <- add_benchmark_metadata(
  runtime_by_size_resolution, baseline_name, package_version, git_commit, args$seed,
  selectboost_reps, stability_reps, selectboost_steps, rng_backend,
  default_method = "all",
  default_replicate = "all"
)
feature_advantage <- add_benchmark_metadata(
  feature_advantage, baseline_name, package_version, git_commit, args$seed,
  selectboost_reps, stability_reps, selectboost_steps, rng_backend,
  default_method = "selectboost_vs_plain_selectboost",
  default_replicate = "all"
)
representation_summary <- add_benchmark_metadata(
  representation_summary, baseline_name, package_version, git_commit, args$seed,
  selectboost_reps, stability_reps, selectboost_steps, rng_backend,
  default_scenario = "all",
  default_association = "all",
  default_replicate = "all"
)
scenario_summary <- add_benchmark_metadata(
  scenario_summary, baseline_name, package_version, git_commit, args$seed,
  selectboost_reps, stability_reps, selectboost_steps, rng_backend,
  default_association = "all",
  default_replicate = "all"
)
size_resolution_summary <- add_benchmark_metadata(
  size_resolution_summary, baseline_name, package_version, git_commit, args$seed,
  selectboost_reps, stability_reps, selectboost_steps, rng_backend,
  default_scenario = "all",
  default_association = "all",
  default_replicate = "all"
)
noise_summary <- add_benchmark_metadata(
  noise_summary, baseline_name, package_version, git_commit, args$seed,
  selectboost_reps, stability_reps, selectboost_steps, rng_backend,
  default_association = "all",
  default_replicate = "all"
)
noise_f1_gain_panel <- add_benchmark_metadata(
  noise_f1_gain_panel, baseline_name, package_version, git_commit, args$seed,
  selectboost_reps, stability_reps, selectboost_steps, rng_backend,
  default_method = "selectboost_vs_plain_selectboost",
  default_association = "all",
  default_replicate = "all"
)
assessment_representation_table <- add_benchmark_metadata(
  assessment_representation_table, baseline_name, package_version, git_commit, args$seed,
  selectboost_reps, stability_reps, selectboost_steps, rng_backend,
  default_method = "selectboost_vs_plain_selectboost",
  default_scenario = "all",
  default_association = "all",
  default_replicate = "all"
)

write_baseline_config(
  file.path(args$output_dir, "benchmark_config_baseline.yml"),
  baseline_name = baseline_name,
  args = args,
  package_version = package_version,
  git_commit = git_commit,
  quick = quick,
  methods = methods,
  simulate_grid = simulate_grid,
  selectboost_grid = selectboost_grid,
  sim_n = sim_n,
  grid_length = grid_length,
  representation_grid = args$representation_grid,
  n_grid = args$n_grid,
  grid_length_grid = args$grid_length_grid,
  snr_grid = args$snr_grid,
  noise_sd_grid = args$noise_sd_grid,
  selectboost_steps = selectboost_steps,
  selectboost_reps = selectboost_reps,
  stability_reps = stability_reps,
  method_comparison_reps = method_comparison_reps,
  method_comparison_selectboost_reps = method_comparison_selectboost_reps,
  method_comparison_stability_reps = method_comparison_stability_reps,
  surface_q_grid = surface_q_grid,
  surface_c0_grid = surface_c0_grid,
  surface_reps = surface_reps,
  surface_selectboost_reps = surface_selectboost_reps,
  rng_backend = rng_backend,
  output_dir = args$output_dir
)
invisible(file.copy(
  file.path(args$output_dir, "benchmark_config_baseline.yml"),
  file.path(args$output_dir, "config.yml"),
  overwrite = TRUE
))

utils::write.csv(study$metrics, file.path(args$output_dir, "benchmark_raw_metrics.csv"), row.names = FALSE)
utils::write.csv(summary_by_setting, file.path(args$output_dir, "benchmark_summary_by_setting.csv"), row.names = FALSE)
utils::write.csv(
  summary_by_setting,
  file.path(args$output_dir, paste0("benchmark_summary_n", args$n_replicates, ".csv")),
  row.names = FALSE
)
if (args$n_replicates %in% c(50L, 100L)) {
  utils::write.csv(
    summary_by_setting,
    file.path(args$output_dir, "benchmark_summary_n50_or_n100.csv"),
    row.names = FALSE
  )
}
utils::write.csv(best_settings, file.path(args$output_dir, "benchmark_best_settings.csv"), row.names = FALSE)
utils::write.csv(paired_gain_summary, file.path(args$output_dir, "paired_gain_summary.csv"), row.names = FALSE)
utils::write.csv(paired_gain_bootstrap_ci, file.path(args$output_dir, "paired_gain_bootstrap_ci.csv"), row.names = FALSE)
utils::write.csv(assessment_top_positive_settings, file.path(args$output_dir, "assessment_top_positive_settings.csv"), row.names = FALSE)
utils::write.csv(assessment_negative_gain_settings, file.path(args$output_dir, "assessment_negative_gain_settings.csv"), row.names = FALSE)
utils::write.csv(assessment_all_setting_summary, file.path(args$output_dir, "assessment_all_setting_summary.csv"), row.names = FALSE)
utils::write.csv(assessment_failure_modes, file.path(args$output_dir, "assessment_failure_modes.csv"), row.names = FALSE)
utils::write.csv(assessment_surface_summary, file.path(args$output_dir, "assessment_surface_summary.csv"), row.names = FALSE)
utils::write.csv(assessment_monotonicity_summary, file.path(args$output_dir, "assessment_monotonicity_summary.csv"), row.names = FALSE)
utils::write.csv(assessment_precision_recall_paths, file.path(args$output_dir, "assessment_precision_recall_paths.csv"), row.names = FALSE)
utils::write.csv(assessment_best_thresholds, file.path(args$output_dir, "assessment_best_thresholds.csv"), row.names = FALSE)
utils::write.csv(association_diagnostics, file.path(args$output_dir, "association_diagnostics.csv"), row.names = FALSE)
utils::write.csv(association_group_size_summary, file.path(args$output_dir, "association_group_size_summary.csv"), row.names = FALSE)
utils::write.csv(assessment_association_comparison_table, file.path(args$output_dir, "assessment_association_comparison_table.csv"), row.names = FALSE)
utils::write.csv(method_comparison_summary, file.path(args$output_dir, "method_comparison_summary.csv"), row.names = FALSE)
utils::write.csv(method_comparison_runtime, file.path(args$output_dir, "method_comparison_runtime.csv"), row.names = FALSE)
utils::write.csv(assessment_method_comparison_table, file.path(args$output_dir, "assessment_method_comparison_table.csv"), row.names = FALSE)
utils::write.csv(runtime_by_setting, file.path(args$output_dir, "runtime_by_setting.csv"), row.names = FALSE)
utils::write.csv(runtime_by_method, file.path(args$output_dir, "runtime_by_method.csv"), row.names = FALSE)
utils::write.csv(precision_recall_paths, file.path(args$output_dir, "benchmark_precision_recall_paths.csv"), row.names = FALSE)
utils::write.csv(monotonicity_summary, file.path(args$output_dir, "benchmark_monotonicity_summary.csv"), row.names = FALSE)
utils::write.csv(runtime_summary, file.path(args$output_dir, "benchmark_runtime_summary.csv"), row.names = FALSE)
utils::write.csv(runtime_by_size_resolution, file.path(args$output_dir, "benchmark_runtime_by_size_resolution.csv"), row.names = FALSE)
utils::write.csv(feature_advantage, file.path(args$output_dir, "benchmark_feature_advantage.csv"), row.names = FALSE)
utils::write.csv(representation_summary, file.path(args$output_dir, "benchmark_representation_summary.csv"), row.names = FALSE)
utils::write.csv(scenario_summary, file.path(args$output_dir, "benchmark_scenario_summary.csv"), row.names = FALSE)
utils::write.csv(size_resolution_summary, file.path(args$output_dir, "benchmark_size_resolution_summary.csv"), row.names = FALSE)
utils::write.csv(noise_summary, file.path(args$output_dir, "benchmark_noise_summary.csv"), row.names = FALSE)
utils::write.csv(noise_f1_gain_panel, file.path(args$output_dir, "benchmark_noise_f1_gain_panel.csv"), row.names = FALSE)
utils::write.csv(assessment_representation_table, file.path(args$output_dir, "assessment_representation_table.csv"), row.names = FALSE)
saveRDS(
  list(
    study = study,
    surface_fit = surface_fit,
    summary_by_setting = summary_by_setting,
    best_settings = best_settings,
    paired_gain_summary = paired_gain_summary,
    paired_gain_bootstrap_ci = paired_gain_bootstrap_ci,
    paired_gain_differences = paired_gain$differences,
    assessment_top_positive_settings = assessment_top_positive_settings,
    assessment_negative_gain_settings = assessment_negative_gain_settings,
    assessment_all_setting_summary = assessment_all_setting_summary,
    assessment_failure_modes = assessment_failure_modes,
    assessment_surface_summary = assessment_surface_summary,
    assessment_monotonicity_summary = assessment_monotonicity_summary,
    assessment_precision_recall_paths = assessment_precision_recall_paths,
    assessment_best_thresholds = assessment_best_thresholds,
    assessment_surface_warnings = assessment_surface_warnings,
    assessment_surface_fits = surface_artifacts$fits,
    association_diagnostics = association_diagnostics,
    association_group_size_summary = association_group_size_summary,
    assessment_association_comparison_table = assessment_association_comparison_table,
    method_comparison_summary = method_comparison_summary,
    method_comparison_runtime = method_comparison_runtime,
    assessment_method_comparison_table = assessment_method_comparison_table,
    runtime_by_setting = runtime_by_setting,
    runtime_by_method = runtime_by_method,
    representation_summary = representation_summary,
    scenario_summary = scenario_summary,
    size_resolution_summary = size_resolution_summary,
    noise_summary = noise_summary,
    noise_f1_gain_panel = noise_f1_gain_panel,
    runtime_by_size_resolution = runtime_by_size_resolution,
    assessment_representation_table = assessment_representation_table,
    precision_recall_paths = precision_recall_paths,
    monotonicity_summary = monotonicity_summary,
    runtime_summary = runtime_summary,
    baseline_name = baseline_name,
    package_version = package_version,
    git_commit = git_commit,
    args = args
  ),
  file.path(args$output_dir, "benchmark_results.rds"),
  version = 2
)

writeLines(capture.output(utils::sessionInfo()), file.path(args$output_dir, "session_info.txt"), useBytes = TRUE)

write_completed_marker(args$output_dir, run_id = run_id, start_time = run_start_time, end_time = Sys.time())
unlink(file.path(args$output_dir, "RUNNING"))

cat("Saved benchmark artifacts to:\n")
cat("  ", args$output_dir, "\n", sep = "")
cat("Best settings:\n")
print(utils::head(best_settings, 10L), row.names = FALSE)

runtime_status_counts <- if ("runtime_status" %in% names(study$metrics)) {
  table(study$metrics$runtime_status, useNA = "ifany")
} else {
  integer()
}
checkpoint_files <- list.files(file.path(args$output_dir, "checkpoints"), pattern = "[.]csv$", full.names = TRUE)
cat("Run audit:\n")
cat("  raw rows: ", nrow(study$metrics), "\n", sep = "")
cat(
  "  runtime statuses: ",
  if (length(runtime_status_counts) == 0L) {
    "none"
  } else {
    paste(paste0(names(runtime_status_counts), "=", as.integer(runtime_status_counts)), collapse = ", ")
  },
  "\n",
  sep = ""
)
cat("  scenarios: ", paste(unique(study$metrics$scenario), collapse = ", "), "\n", sep = "")
cat("  representations: ", paste(unique(study$metrics$representation), collapse = ", "), "\n", sep = "")
cat("  methods: ", paste(unique(study$metrics$method), collapse = ", "), "\n", sep = "")
cat("  levels: ", paste(unique(study$metrics$level), collapse = ", "), "\n", sep = "")
cat("  checkpoint files: ", length(checkpoint_files), "\n", sep = "")
cat("  output dir: ", args$output_dir, "\n", sep = "")
