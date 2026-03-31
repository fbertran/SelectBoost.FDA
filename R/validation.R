resolve_plain_grouping_function <- function(association = NULL,
                                            method = c("threshold", "community")) {
  method <- match.arg(method)
  fixed_association <- if (is.null(association)) NULL else abs(as.matrix(association))

  function(absXcor, c0) {
    current_association <- fixed_association %||% abs(absXcor)
    diag(current_association) <- 1

    if (identical(method, "threshold")) {
      return(SelectBoost::group_func_1(current_association, c0 = c0))
    }

    SelectBoost::group_func_2(current_association, c0 = c0)
  }
}

metric_row <- function(predicted, active, universe, level) {
  universe <- unique(as.character(universe))

  if (length(universe) == 0L) {
    return(data.frame(
      level = level,
      n_universe = 0L,
      n_truth = 0L,
      n_selected = 0L,
      tp = NA_integer_,
      fp = NA_integer_,
      fn = NA_integer_,
      tn = NA_integer_,
      precision = NA_real_,
      recall = NA_real_,
      specificity = NA_real_,
      f1 = NA_real_,
      jaccard = NA_real_,
      selection_rate = NA_real_,
      stringsAsFactors = FALSE
    ))
  }

  active <- intersect(unique(as.character(active)), universe)
  predicted <- intersect(unique(as.character(predicted)), universe)

  truth_mask <- universe %in% active
  pred_mask <- universe %in% predicted
  tp <- sum(truth_mask & pred_mask)
  fp <- sum(!truth_mask & pred_mask)
  fn <- sum(truth_mask & !pred_mask)
  tn <- sum(!truth_mask & !pred_mask)

  precision <- if ((tp + fp) == 0L) NA_real_ else tp / (tp + fp)
  recall <- if ((tp + fn) == 0L) NA_real_ else tp / (tp + fn)
  specificity <- if ((tn + fp) == 0L) NA_real_ else tn / (tn + fp)
  f1 <- if (is.na(precision) || is.na(recall) || (precision + recall) == 0) {
    NA_real_
  } else {
    2 * precision * recall / (precision + recall)
  }
  jaccard <- if ((tp + fp + fn) == 0L) NA_real_ else tp / (tp + fp + fn)

  data.frame(
    level = level,
    n_universe = length(universe),
    n_truth = length(active),
    n_selected = length(predicted),
    tp = tp,
    fp = fp,
    fn = fn,
    tn = tn,
    precision = precision,
    recall = recall,
    specificity = specificity,
    f1 = f1,
    jaccard = jaccard,
    selection_rate = length(predicted) / length(universe),
    stringsAsFactors = FALSE
  )
}

resolve_truth_object <- function(truth) {
  if (inherits(truth, "fda_simulation_data")) {
    return(truth$truth)
  }
  if (is.list(truth) && all(c("active_features", "feature_universe") %in% names(truth))) {
    return(truth)
  }
  stop("`truth` must be an `fda_simulation_data` object or a truth list created from one.", call. = FALSE)
}

truth_targets_for_fit <- function(fit, truth, level = c("feature", "group", "basis")) {
  level <- match.arg(level)
  truth <- resolve_truth_object(truth)
  feature_universe <- colnames(fit$x$x)
  active_features <- intersect(truth$active_features, feature_universe)

  if (identical(level, "feature")) {
    return(list(
      active = active_features,
      universe = feature_universe
    ))
  }

  if (identical(level, "group")) {
    members <- split_groups(fit$groups)
    labels <- group_names(fit$groups)
    active_idx <- match(active_features, feature_universe, nomatch = 0L)
    active_idx <- active_idx[active_idx > 0L]
    active_groups <- labels[vapply(members, function(idx) {
      any(idx %in% active_idx)
    }, logical(1))]

    return(list(
      active = active_groups,
      universe = labels
    ))
  }

  feature_map <- fit$x$feature_map
  active_mask <- feature_map$feature %in% active_features & feature_map$representation == "basis"
  list(
    active = unique(feature_map$predictor[active_mask]),
    universe = unique(feature_map$predictor[feature_map$representation == "basis"])
  )
}

selection_targets_for_map <- function(map,
                                      level = c("feature", "group", "basis"),
                                      threshold = 0,
                                      value = c("max", "mean")) {
  level <- match.arg(level)
  value <- match.arg(value)

  if (identical(level, "feature")) {
    return(map$feature[map$selection > threshold])
  }

  if (identical(level, "group")) {
    metric <- if (identical(value, "mean")) map$mean_selection else map$max_selection
    return(map$group[metric > threshold])
  }

  metric <- if (identical(value, "mean")) map$mean_selection else map$max_selection
  map$predictor[metric > threshold]
}

summarise_simulation_metrics <- function(metrics) {
  if (is.null(metrics) || nrow(metrics) == 0L) {
    return(data.frame())
  }

  by_cols <- intersect(c("method", "level", "c0", "width"), names(metrics))
  numeric_cols <- intersect(c(
    "n_truth", "n_selected", "tp", "fp", "fn", "tn",
    "precision", "recall", "specificity", "f1", "jaccard", "selection_rate"
  ), names(metrics))

  if (length(by_cols) == 0L) {
    by_cols <- "level"
  }

  split_keys <- interaction(metrics[by_cols], drop = TRUE, lex.order = TRUE)
  do.call(rbind, lapply(split(seq_len(nrow(metrics)), split_keys), function(idx) {
    part <- metrics[idx, , drop = FALSE]
    out <- part[1, by_cols, drop = FALSE]
    out$n_rep <- nrow(part)

    for (name in numeric_cols) {
      values <- part[[name]]
      out[[paste0(name, "_mean")]] <- mean(values, na.rm = TRUE)
      out[[paste0(name, "_sd")]] <- if (length(values) > 1L) stats::sd(values, na.rm = TRUE) else 0
    }

    out
  }))
}

build_truth_from_design <- function(design,
                                    active_functional = NULL,
                                    active_scalar = NULL) {
  feature_map <- design$feature_map
  active_mask <- rep(FALSE, nrow(feature_map))

  if (!is.null(active_functional) && nrow(active_functional) > 0L) {
    for (i in seq_len(nrow(active_functional))) {
      row <- active_functional[i, , drop = FALSE]
      active_mask <- active_mask | (
        feature_map$source_predictor == row$predictor &
          feature_map$source_position_start <= row$end_position &
          feature_map$source_position_end >= row$start_position
      )
    }
  }

  if (!is.null(active_scalar) && nrow(active_scalar) > 0L) {
    for (i in seq_len(nrow(active_scalar))) {
      row <- active_scalar[i, , drop = FALSE]
      active_mask <- active_mask | feature_map$predictor == row$predictor
    }
  }

  active_features <- feature_map$feature[active_mask]
  active_predictors <- unique(feature_map$predictor[active_mask])

  list(
    active_functional = active_functional,
    active_scalar = active_scalar,
    active_features = active_features,
    feature_universe = feature_map$feature,
    active_predictors = active_predictors,
    predictor_universe = unique(feature_map$predictor)
  )
}

#' Plain SelectBoost Baseline for Functional Predictors
#'
#' Runs `SelectBoost` directly on the flattened predictor matrix without the
#' FDA-specific grouping heuristics used by [selectboost_fda()]. This is useful
#' as a benchmark against the FDA-aware variant.
#'
#' @inheritParams selectboost_fda
#' @param association Optional absolute association matrix used directly by the
#'   raw SelectBoost grouping function.
#'
#' @returns An object of class `plain_selectboost_result`.
#' @export
plain_selectboost <- function(x,
                              y = NULL,
                              mode = c("fast", "auto"),
                              selector = "msgps",
                              selector_fun = NULL,
                              selector_args = list(),
                              groups = NULL,
                              family = c("gaussian", "binomial"),
                              association = NULL,
                              group_method = c("threshold", "community"),
                              ...) {
  family_input <- if (missing(family)) NULL else family
  input <- resolve_fit_input(x = x, y = y, family = family_input)
  fda_x <- input$x
  y <- input$y
  family <- input$family
  mode <- match.arg(mode)
  group_method <- match.arg(group_method)

  if (!is.null(association)) {
    association <- abs(as.matrix(association))
    if (!identical(dim(association), c(ncol(fda_x$x), ncol(fda_x$x)))) {
      stop("`association` must be a square matrix with one row and column per feature.", call. = FALSE)
    }
  }

  groups <- normalize_groups(
    groups %||% if (length(unique(fda_x$blocks)) > 1L) fda_x$blocks else NULL,
    p = ncol(fda_x$x)
  )
  selector_fn <- resolve_selectboost_selector(
    selector = selector,
    selector_fun = selector_fun,
    groups = groups,
    family = family,
    selector_args = selector_args
  )
  group_fn <- resolve_plain_grouping_function(
    association = association,
    method = group_method
  )

  result <- if (identical(mode, "fast")) {
    SelectBoost::fastboost(
      X = fda_x$x,
      Y = y,
      group = group_fn,
      func = selector_fn,
      ...
    )
  } else {
    SelectBoost::autoboost(
      X = fda_x$x,
      Y = y,
      group = group_fn,
      func = selector_fn,
      ...
    )
  }

  feature_selection <- t(as.matrix(result))
  rownames(feature_selection) <- colnames(fda_x$x)
  colnames(feature_selection) <- rownames(as.matrix(result))

  output <- list(
    call = match.call(),
    result = result,
    x = fda_x,
    design = input$design,
    groups = groups,
    family = family,
    mode = mode,
    group_method = group_method,
    association = association,
    feature_selection = feature_selection
  )
  class(output) <- c("plain_selectboost_result", "selectboost_fda_result", "fda_selection_fit")
  output
}

#' @export
print.plain_selectboost_result <- function(x, ...) {
  cat("Plain SelectBoost result\n")
  cat("  family:", x$family, "\n")
  cat("  mode:", x$mode, "\n")
  cat("  features:", nrow(x$feature_selection), "\n")
  cat("  groups:", length(group_names(x$groups)), "\n")
  cat("  c0 values:", ncol(x$feature_selection), "\n")
  invisible(x)
}

#' @export
summary.plain_selectboost_result <- function(object, ...) {
  counts <- colSums(object$feature_selection > 0)
  meta <- selection_fit_metadata(object)
  result <- list(
    method = "plain_selectboost",
    family = meta$family,
    n_features = meta$n_features,
    n_groups = meta$n_groups,
    n_predictors = meta$n_predictors,
    mode = object$mode,
    n_c0 = ncol(object$feature_selection),
    selected_by_c0 = counts
  )
  class(result) <- "summary.plain_selectboost_result"
  result
}

#' @export
print.summary.plain_selectboost_result <- function(x, ...) {
  cat("Plain SelectBoost summary\n")
  cat("  family:", x$family, "\n")
  cat("  predictors:", x$n_predictors, "\n")
  cat("  mode:", x$mode, "\n")
  cat("  features:", x$n_features, "\n")
  cat("  groups:", x$n_groups, "\n")
  cat("  c0 values:", x$n_c0, "\n")
  invisible(x)
}

#' Simulate an FDA Benchmark Scenario
#'
#' Generates raw functional predictors, scalar covariates, a response, and the
#' mapped ground truth for the transformed design matrix.
#'
#' @param n Number of observations.
#' @param grid_length Number of grid points per functional predictor.
#' @param family Model family used to generate the response.
#' @param representation Representation used when building the returned
#'   [fda_design()]: `"grid"` keeps the raw curves, `"basis"` applies a
#'   spline-basis transform, and `"fpca"` applies FPCA scores.
#' @param transforms Optional transform list passed to [fda_design()]. When
#'   omitted, a sensible default is chosen from `representation`.
#' @param basis_df Degrees of freedom used when `representation = "basis"`.
#' @param n_components Number of FPCA components used when
#'   `representation = "fpca"`.
#' @param include_scalar Should scalar covariates be included in the design and
#'   truth object?
#' @param noise_sd Observation noise level.
#' @param seed Optional random seed.
#'
#' @returns An object of class `fda_simulation_data`.
#' @examples
#' sim <- simulate_fda_scenario(n = 24, grid_length = 16, seed = 1)
#' sim
#' head(sim$truth$active_features)
#' @export
simulate_fda_scenario <- function(n = 80L,
                                  grid_length = 60L,
                                  family = c("gaussian", "binomial"),
                                  representation = c("grid", "basis", "fpca"),
                                  transforms = NULL,
                                  basis_df = 7L,
                                  n_components = 5L,
                                  include_scalar = TRUE,
                                  noise_sd = 0.4,
                                  seed = NULL) {
  if (!is.null(seed)) {
    set.seed(seed)
  }

  family <- match.arg(family)
  representation <- match.arg(representation)
  n <- as.integer(n)
  grid_length <- as.integer(grid_length)
  basis_df <- as.integer(basis_df)
  n_components <- as.integer(n_components)

  grid <- seq(0, 1, length.out = grid_length)
  latent_signal_1 <- stats::rnorm(n)
  latent_signal_2 <- stats::rnorm(n)
  latent_nuisance <- stats::rnorm(n)
  signal_shape_1 <- exp(-((grid - 0.25) / 0.08) ^ 2)
  signal_shape_2 <- sin(2 * pi * grid) * exp(-((grid - 0.65) / 0.18) ^ 2)
  nuisance_shape_1 <- cos(pi * grid)
  nuisance_shape_2 <- exp(-((grid - 0.78) / 0.09) ^ 2)

  signal <- outer(latent_signal_1, signal_shape_1) +
    outer(latent_signal_2, signal_shape_2) +
    matrix(stats::rnorm(n * grid_length, sd = 0.12), nrow = n)
  nuisance <- outer(latent_nuisance, nuisance_shape_1) +
    outer(stats::rnorm(n), nuisance_shape_2) +
    matrix(stats::rnorm(n * grid_length, sd = 0.14), nrow = n)

  region_bounds <- rbind(
    c(max(1L, floor(0.15 * grid_length)), max(2L, floor(0.28 * grid_length))),
    c(max(1L, floor(0.52 * grid_length)), max(2L, floor(0.68 * grid_length)))
  )
  region_weights <- c(1.6, -1.25)
  region_effects <- vapply(seq_len(nrow(region_bounds)), function(i) {
    idx <- seq.int(region_bounds[i, 1], region_bounds[i, 2])
    rowMeans(signal[, idx, drop = FALSE]) * region_weights[i]
  }, numeric(n))

  scalar_covariates <- NULL
  scalar_truth <- NULL
  linear_predictor <- rowSums(region_effects)
  if (isTRUE(include_scalar)) {
    age <- stats::rnorm(n, mean = 50, sd = 7)
    treatment <- stats::rbinom(n, size = 1, prob = 0.45)
    scalar_covariates <- data.frame(age = age, treatment = treatment)
    linear_predictor <- linear_predictor + 0.05 * age - 0.6 * treatment
    scalar_truth <- data.frame(
      predictor = c("age", "treatment"),
      feature = c("age", "treatment"),
      weight = c(0.05, -0.6),
      stringsAsFactors = FALSE
    )
  }

  response <- if (identical(family, "gaussian")) {
    linear_predictor + stats::rnorm(n, sd = noise_sd)
  } else {
    prob <- stats::plogis(scale(linear_predictor)[, 1])
    stats::rbinom(n, size = 1, prob = prob)
  }

  predictors <- list(
    signal = fda_grid(signal, argvals = grid, name = "signal"),
    nuisance = fda_grid(nuisance, argvals = grid, name = "nuisance")
  )

  if (is.null(transforms)) {
    transforms <- switch(
      representation,
      grid = NULL,
      basis = list(
        signal = fda_bspline(df = basis_df),
        nuisance = fda_bspline(df = max(4L, basis_df - 1L))
      ),
      fpca = list(
        signal = fda_fpca(n_components = n_components),
        nuisance = fda_fpca(n_components = max(2L, n_components - 1L))
      )
    )
  }

  design <- fda_design(
    response = response,
    predictors = predictors,
    scalar_covariates = scalar_covariates,
    family = family,
    transforms = transforms,
    scalar_transform = if (isTRUE(include_scalar)) fda_standardize() else NULL
  )

  active_functional <- data.frame(
    predictor = rep("signal", nrow(region_bounds)),
    start_position = region_bounds[, 1],
    end_position = region_bounds[, 2],
    start_argval = grid[region_bounds[, 1]],
    end_argval = grid[region_bounds[, 2]],
    weight = region_weights,
    stringsAsFactors = FALSE
  )

  truth <- build_truth_from_design(
    design = design,
    active_functional = active_functional,
    active_scalar = scalar_truth
  )

  output <- list(
    grid = grid,
    response = response,
    predictors = lapply(predictors, `[[`, "values"),
    scalar_covariates = scalar_covariates,
    design = design,
    truth = truth,
    linear_predictor = linear_predictor
  )
  class(output) <- "fda_simulation_data"
  output
}

#' @export
print.fda_simulation_data <- function(x, ...) {
  cat("FDA simulation data\n")
  cat("  observations:", nrow(x$design$matrix$x), "\n")
  cat("  features:", ncol(x$design$matrix$x), "\n")
  cat("  active features:", length(x$truth$active_features), "\n")
  cat("  active predictors:", paste(x$truth$active_predictors, collapse = ", "), "\n")
  invisible(x)
}

#' Evaluate Selection Recovery Against Ground Truth
#'
#' Computes support-recovery metrics for fitted selection objects against the
#' truth generated by `simulate_fda_scenario()`.
#'
#' @param x A fitted selection object or an `fda_method_comparison`.
#' @param truth Ground-truth object, typically the value returned by
#'   `simulate_fda_scenario()`.
#' @param level Evaluation level: `"feature"`, `"group"`, or `"basis"`.
#' @param ... Additional arguments passed to the relevant method.
#'
#' @returns A data frame with recovery metrics.
#' @export
evaluate_selection <- function(x, truth, level = c("feature", "group", "basis"), ...) {
  UseMethod("evaluate_selection")
}

#' @export
evaluate_selection.fda_stability_selection <- function(x,
                                                       truth,
                                                       level = c("feature", "group", "basis"),
                                                       cutoff = x$cutoff,
                                                       ...) {
  level <- match.arg(level)
  targets <- truth_targets_for_fit(x, truth = truth, level = level)
  predicted <- if (identical(level, "feature")) {
    selected(x, level = "feature", cutoff = cutoff, ...)$feature
  } else if (identical(level, "group")) {
    selected(x, level = "group", cutoff = cutoff, ...)$group
  } else {
    selected(x, level = "basis", cutoff = cutoff, ...)$predictor
  }

  metric_row(predicted = predicted, active = targets$active, universe = targets$universe, level = level)
}

#' @export
evaluate_selection.selectboost_fda_result <- function(x,
                                                      truth,
                                                      level = c("feature", "group", "basis"),
                                                      c0 = NULL,
                                                      threshold = 0,
                                                      value = c("max", "mean"),
                                                      ...) {
  level <- match.arg(level)
  value <- match.arg(value)
  c0_values <- c0 %||% colnames(x$feature_selection)
  targets <- truth_targets_for_fit(x, truth = truth, level = level)

  rows <- lapply(c0_values, function(current_c0) {
    map <- selection_map(x, level = level, c0 = current_c0, ...)
    predicted <- selection_targets_for_map(
      map = map,
      level = level,
      threshold = threshold,
      value = value
    )
    out <- metric_row(
      predicted = predicted,
      active = targets$active,
      universe = targets$universe,
      level = level
    )
    out$c0 <- current_c0
    out
  })

  do.call(rbind, rows)
}

#' @export
evaluate_selection.fda_method_comparison <- function(x,
                                                     truth,
                                                     level = c("feature", "group", "basis"),
                                                     ...) {
  level <- match.arg(level)
  out <- lapply(names(x$fits), function(method) {
    fit <- x$fits[[method]]
    if (!inherits(fit, c("fda_stability_selection", "selectboost_fda_result"))) {
      return(NULL)
    }
    metrics <- evaluate_selection(fit, truth = truth, level = level, ...)
    metrics$method <- method
    metrics
  })

  rbind_fill_data_frames(out)
}

#' Benchmark FDA Selection Methods on Shared Ground Truth
#'
#' Runs [compare_selection_methods()] on a simulated dataset and evaluates the
#' fitted objects against the mapped truth.
#'
#' @param data An object returned by `simulate_fda_scenario()`.
#' @param methods Methods passed to [compare_selection_methods()].
#' @param levels Evaluation levels.
#' @param stability_args,interval_args,selectboost_args,plain_selectboost_args
#'   Additional arguments passed to [compare_selection_methods()].
#' @param fdboost_model,fdboost_args Optional `FDboost` inputs forwarded to
#'   [compare_selection_methods()].
#' @param keep_comparison Should the fitted comparison object be stored?
#'
#' @returns An object of class `fda_benchmark`.
#' @examples
#' sim <- simulate_fda_scenario(n = 24, grid_length = 16, seed = 1)
#' bench <- benchmark_selection_methods(
#'   sim,
#'   methods = c("selectboost", "plain_selectboost"),
#'   selectboost_args = list(B = 3, steps.seq = 0.5, c0lim = FALSE),
#'   plain_selectboost_args = list(B = 3, steps.seq = 0.5, c0lim = FALSE)
#' )
#' head(bench$metrics)
#' @export
benchmark_selection_methods <- function(data,
                                        methods = c("stability", "interval", "selectboost", "plain_selectboost"),
                                        levels = c("feature", "group"),
                                        stability_args = list(),
                                        interval_args = list(),
                                        selectboost_args = list(),
                                        plain_selectboost_args = list(),
                                        fdboost_model = NULL,
                                        fdboost_args = list(),
                                        keep_comparison = TRUE) {
  if (!inherits(data, "fda_simulation_data")) {
    stop("`data` must inherit from class `fda_simulation_data`.", call. = FALSE)
  }

  comparison <- compare_selection_methods(
    design = data$design,
    methods = methods,
    stability_args = stability_args,
    interval_args = interval_args,
    selectboost_args = selectboost_args,
    plain_selectboost_args = plain_selectboost_args,
    fdboost_model = fdboost_model,
    fdboost_args = fdboost_args
  )

  metrics <- rbind_fill_data_frames(lapply(levels, function(level) {
    out <- evaluate_selection(comparison, truth = data, level = level)
    out$level <- level
    out
  }))

  structure(
    list(
      data = data,
      comparison = if (isTRUE(keep_comparison)) comparison else NULL,
      metrics = metrics
    ),
    class = "fda_benchmark"
  )
}

#' @export
print.fda_benchmark <- function(x, ...) {
  cat("FDA benchmark\n")
  cat("  methods:", paste(unique(x$metrics$method), collapse = ", "), "\n")
  cat("  rows:", nrow(x$metrics), "\n")
  invisible(x)
}

#' @export
summary.fda_benchmark <- function(object, ...) {
  structure(
    list(
      metrics = object$metrics
    ),
    class = "summary.fda_benchmark"
  )
}

#' @export
print.summary.fda_benchmark <- function(x, ...) {
  cat("FDA benchmark summary\n")
  print(x$metrics, row.names = FALSE)
  invisible(x)
}

#' @export
selection_map.fda_benchmark <- function(x,
                                        level = c("feature", "group", "basis"),
                                        ...) {
  if (is.null(x$comparison)) {
    stop("`selection_map()` is only available when `keep_comparison = TRUE`.", call. = FALSE)
  }
  selection_map(x$comparison, level = level, ...)
}

#' @export
selected.fda_benchmark <- function(x, ...) {
  if (is.null(x$comparison)) {
    stop("`selected()` is only available when `keep_comparison = TRUE`.", call. = FALSE)
  }
  selected(x$comparison, ...)
}

#' Run a Repeated FDA Simulation Study
#'
#' Repeats `simulate_fda_scenario()` and `benchmark_selection_methods()` over
#' multiple replications and aggregates the resulting recovery metrics.
#'
#' @param n_rep Number of simulation replications.
#' @param simulate_args Named list forwarded to `simulate_fda_scenario()`.
#' @param benchmark_args Named list forwarded to `benchmark_selection_methods()`.
#' @param seed Optional seed used to derive deterministic per-replication seeds.
#' @param keep_results Should the individual benchmark objects be returned?
#'
#' @returns An object of class `fda_simulation_study`.
#' @export
run_simulation_study <- function(n_rep = 10L,
                                 simulate_args = list(),
                                 benchmark_args = list(),
                                 seed = NULL,
                                 keep_results = FALSE) {
  n_rep <- as.integer(n_rep)
  if (n_rep < 1L) {
    stop("`n_rep` must be a positive integer.", call. = FALSE)
  }

  benchmark_results <- if (isTRUE(keep_results)) vector("list", n_rep) else NULL
  metric_rows <- vector("list", n_rep)

  for (i in seq_len(n_rep)) {
    current_simulate_args <- simulate_args
    current_simulate_args$seed <- next_seed(seed, i)
    sim <- do.call(simulate_fda_scenario, current_simulate_args)
    bench <- do.call(
      benchmark_selection_methods,
      c(list(data = sim), benchmark_args)
    )
    metrics <- bench$metrics
    metrics$replicate <- i
    metric_rows[[i]] <- metrics
    if (isTRUE(keep_results)) {
      benchmark_results[[i]] <- bench
    }
  }

  metrics <- rbind_fill_data_frames(metric_rows)
  structure(
    list(
      metrics = metrics,
      summary_table = summarise_simulation_metrics(metrics),
      results = benchmark_results
    ),
    class = "fda_simulation_study"
  )
}

#' @export
print.fda_simulation_study <- function(x, ...) {
  cat("FDA simulation study\n")
  cat("  replications:", length(unique(x$metrics$replicate)), "\n")
  cat("  rows:", nrow(x$metrics), "\n")
  invisible(x)
}

#' @export
summary.fda_simulation_study <- function(object, ...) {
  structure(
    list(
      summary_table = object$summary_table
    ),
    class = "summary.fda_simulation_study"
  )
}

#' @export
print.summary.fda_simulation_study <- function(x, ...) {
  cat("FDA simulation study summary\n")
  print(x$summary_table, row.names = FALSE)
  invisible(x)
}
