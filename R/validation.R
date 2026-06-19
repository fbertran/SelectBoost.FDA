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

benchmark_setting_columns <- function(names) {
  intersect(
    c(
      "n",
      "grid_length",
      "noise_axis",
      "snr",
      "noise_sd",
      "association_method",
      "bandwidth",
      "group_method",
      "within_blocks",
      "confounding_strength",
      "active_region_scale",
      "local_correlation"
    ),
    names
  )
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

split_component_keys <- function(values) {
  values <- values[!is.na(values) & nzchar(values)]
  if (length(values) == 0L) {
    return(character())
  }
  unique(trimws(unlist(strsplit(values, ",", fixed = TRUE), use.names = FALSE)))
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
  basis_mask <- feature_map$representation == "basis"
  basis_component <- ifelse(
    is.na(feature_map$component) | !nzchar(feature_map$component),
    feature_map$argval,
    feature_map$component
  )
  component_universe <- basis_component_key(
    feature_map$predictor[basis_mask],
    feature_map$basis_type[basis_mask],
    basis_component[basis_mask]
  )
  active_components <- if (!is.null(truth$active_basis_components)) {
    intersect(truth$active_basis_components, component_universe)
  } else {
    active_mask <- feature_map$feature %in% active_features & basis_mask
    basis_component_key(
      feature_map$predictor[active_mask],
      feature_map$basis_type[active_mask],
      basis_component[active_mask]
    )
  }

  list(
    active = unique(active_components),
    universe = unique(component_universe)
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

  if ("selected_component_keys" %in% names(map)) {
    selected_keys <- split_component_keys(map$selected_component_keys)
    if (length(selected_keys) > 0L) {
      return(selected_keys)
    }
  }

  metric <- if (identical(value, "mean")) map$mean_selection else map$max_selection
  if ("component_keys" %in% names(map)) {
    return(split_component_keys(map$component_keys[metric > threshold]))
  }
  map$predictor[metric > threshold]
}

summarise_simulation_metrics <- function(metrics) {
  if (is.null(metrics) || nrow(metrics) == 0L) {
    return(data.frame())
  }

  by_cols <- intersect(
    c(
      "scenario", "representation", "family",
      benchmark_setting_columns(names(metrics)),
      "method", "level", "c0", "width"
    ),
    names(metrics)
  )
  numeric_cols <- intersect(c(
    "n_truth", "n_selected", "tp", "fp", "fn", "tn",
    "precision", "recall", "specificity", "f1", "jaccard", "selection_rate",
    "effective_snr", "effective_variance_snr"
  ), names(metrics))

  if (length(by_cols) == 0L) {
    by_cols <- "level"
  }

    split_keys <- interaction_key(metrics[by_cols])
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

benchmark_metrics_from_object <- function(x) {
  if (inherits(x, c("fda_benchmark", "fda_simulation_study"))) {
    return(x$metrics)
  }

  stop("`x` must inherit from class `fda_benchmark` or `fda_simulation_study`.", call. = FALSE)
}

best_metric_rows <- function(metrics,
                             level = c("feature", "group", "basis"),
                             metric = "f1",
                             optimize = c("max", "min"),
                             select_c0 = c("best", "all")) {
  level <- match.arg(level)
  optimize <- match.arg(optimize)
  select_c0 <- match.arg(select_c0)

  if (!metric %in% names(metrics)) {
    stop(sprintf("Metric `%s` was not found in the benchmark table.", metric), call. = FALSE)
  }

  metrics <- metrics[metrics$level == level, , drop = FALSE]
  if (nrow(metrics) == 0L || identical(select_c0, "all") || !"c0" %in% names(metrics)) {
    return(metrics)
  }

  split_cols <- intersect(
    c(
      "scenario", "representation", "family",
      benchmark_setting_columns(names(metrics)),
      "replicate", "method", "level", "width"
    ),
    names(metrics)
  )
  if (length(split_cols) == 0L) {
    split_cols <- c("method", "level")
  }

    split_keys <- interaction_key(metrics[split_cols])
  do.call(rbind, lapply(split(seq_len(nrow(metrics)), split_keys), function(idx) {
    part <- metrics[idx, , drop = FALSE]
    values <- part[[metric]]
    values[is.na(values)] <- if (identical(optimize, "max")) -Inf else Inf
    keep <- if (identical(optimize, "max")) which.max(values) else which.min(values)
    part[keep, , drop = FALSE]
  }))
}

aggregate_benchmark_rows <- function(metrics) {
  if (nrow(metrics) == 0L) {
    return(metrics)
  }

  by_cols <- intersect(
    c(
      "scenario", "representation", "family",
      benchmark_setting_columns(names(metrics)),
      "method", "level", "width"
    ),
    names(metrics)
  )
  numeric_cols <- intersect(c(
    "n_truth", "n_selected", "tp", "fp", "fn", "tn",
    "precision", "recall", "specificity", "f1", "jaccard", "selection_rate",
    "effective_snr", "effective_variance_snr"
  ), names(metrics))

    split_keys <- interaction_key(metrics[by_cols])
  do.call(rbind, lapply(split(seq_len(nrow(metrics)), split_keys), function(idx) {
    part <- metrics[idx, , drop = FALSE]
    out <- part[1, by_cols, drop = FALSE]
    out$n_rep <- length(unique(part$replicate %||% seq_len(nrow(part))))

    for (name in numeric_cols) {
      out[[paste0(name, "_mean")]] <- mean(part[[name]], na.rm = TRUE)
      out[[paste0(name, "_sd")]] <- if (nrow(part) > 1L) stats::sd(part[[name]], na.rm = TRUE) else 0
    }

    out
  }))
}

advantage_rows <- function(metrics,
                           target = "selectboost",
                           reference = c("plain_selectboost", "stability"),
                           metric = "f1") {
  if (!metric %in% names(metrics)) {
    stop(sprintf("Metric `%s` was not found in the benchmark table.", metric), call. = FALSE)
  }

  split_cols <- intersect(
    c(
      "scenario", "representation", "family",
      benchmark_setting_columns(names(metrics)),
      "replicate", "level", "width"
    ),
    names(metrics)
  )
    split_keys <- interaction_key(metrics[split_cols])
  rows <- vector("list", 0L)
  counter <- 1L

  for (idx in split(seq_len(nrow(metrics)), split_keys)) {
    part <- metrics[idx, , drop = FALSE]
    target_rows <- part[part$method == target, , drop = FALSE]
    if (nrow(target_rows) == 0L) {
      next
    }

    target_value <- target_rows[[metric]][1]
    for (ref in reference) {
      ref_rows <- part[part$method == ref, , drop = FALSE]
      if (nrow(ref_rows) == 0L) {
        next
      }

      out <- target_rows[1, split_cols, drop = FALSE]
      out$target <- target
      out$reference <- ref
      out$metric <- metric
      out$target_value <- target_value
      out$reference_value <- ref_rows[[metric]][1]
      out$delta <- out$target_value - out$reference_value
      out$target_wins <- out$delta > 0
      rows[[counter]] <- out
      counter <- counter + 1L
    }
  }

  rbind_fill_data_frames(rows)
}

aggregate_advantage_rows <- function(rows) {
  if (nrow(rows) == 0L) {
    return(rows)
  }

  by_cols <- intersect(
    c(
      "scenario", "representation", "family",
      benchmark_setting_columns(names(rows)),
      "level", "target", "reference", "metric", "width"
    ),
    names(rows)
  )
    split_keys <- interaction_key(rows[by_cols])
  do.call(rbind, lapply(split(seq_len(nrow(rows)), split_keys), function(idx) {
    part <- rows[idx, , drop = FALSE]
    out <- part[1, by_cols, drop = FALSE]
    out$n_rep <- length(unique(part$replicate %||% seq_len(nrow(part))))
    out$target_value_mean <- mean(part$target_value, na.rm = TRUE)
    out$reference_value_mean <- mean(part$reference_value, na.rm = TRUE)
    out$delta_mean <- mean(part$delta, na.rm = TRUE)
    out$delta_sd <- if (nrow(part) > 1L) stats::sd(part$delta, na.rm = TRUE) else 0
    out$win_rate <- mean(part$target_wins, na.rm = TRUE)
    out
  }))
}

smooth_curve_matrix <- function(values, local_correlation = 0) {
  if (!is.numeric(local_correlation) || length(local_correlation) != 1L || is.na(local_correlation) || local_correlation < 0) {
    stop("`local_correlation` must be a single non-negative number.", call. = FALSE)
  }

  if (local_correlation <= 0) {
    return(values)
  }

  positions <- seq_len(ncol(values))
  weights <- outer(positions, positions, function(i, j) {
    exp(-0.5 * ((i - j) / local_correlation) ^ 2)
  })
  weights <- sweep(weights, 2L, colSums(weights), "/")
  values %*% weights
}

rescale_region_bounds <- function(region_bounds, active_region_scale, grid_length) {
  if (!is.numeric(active_region_scale) || length(active_region_scale) != 1L || is.na(active_region_scale) || active_region_scale <= 0) {
    stop("`active_region_scale` must be a single positive number.", call. = FALSE)
  }

  widths <- pmax(2L, round((region_bounds[, 2] - region_bounds[, 1] + 1L) * active_region_scale))
  centers <- round(rowMeans(region_bounds))
  starts <- pmax(1L, centers - floor((widths - 1L) / 2L))
  ends <- pmin(grid_length, starts + widths - 1L)
  starts <- pmax(1L, ends - widths + 1L)
  cbind(starts, ends)
}

grid_row_as_list <- function(grid, i, na_to_null = FALSE) {
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

append_parameter_columns <- function(data, params) {
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

timing_value <- function(timing, name) {
  value <- unname(timing[[name]])
  if (length(value) == 0L || is.null(value) || is.na(value)) {
    return(NA_real_)
  }
  as.numeric(value)
}

object_size_mb <- function(x) {
  if (is.null(x)) {
    return(NA_real_)
  }
  as.numeric(utils::object.size(x)) / (1024^2)
}

capture_runtime_result <- function(expr) {
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

failed_benchmark_metrics <- function(methods,
                                     levels,
                                     data = NULL,
                                     simulate_labels = list(),
                                     stage = "benchmark",
                                     error_message = NA_character_) {
  methods <- as.character(methods)
  levels <- as.character(levels)
  if (length(methods) == 0L) {
    methods <- NA_character_
  }
  if (length(levels) == 0L) {
    levels <- NA_character_
  }

  out <- expand.grid(
    method = methods,
    level = levels,
    stringsAsFactors = FALSE
  )
  out$n_universe <- NA_integer_
  out$n_truth <- NA_integer_
  out$n_selected <- NA_integer_
  out$tp <- NA_integer_
  out$fp <- NA_integer_
  out$fn <- NA_integer_
  out$tn <- NA_integer_
  out$precision <- NA_real_
  out$recall <- NA_real_
  out$specificity <- NA_real_
  out$f1 <- NA_real_
  out$jaccard <- NA_real_
  out$selection_rate <- NA_real_

  out$scenario <- if (!is.null(data)) data$scenario else simulate_labels$scenario %||% NA_character_
  out$representation <- if (!is.null(data)) data$representation else simulate_labels$representation %||% NA_character_
  out$family <- if (!is.null(data)) data$family else simulate_labels$family %||% NA_character_
  out$noise_axis <- if (!is.null(data)) data$noise_axis %||% NA_character_ else simulate_labels$noise_axis %||% NA_character_
  out$snr <- if (!is.null(data)) data$snr %||% NA_real_ else simulate_labels$snr %||% NA_real_
  out$noise_sd <- if (!is.null(data)) data$requested_noise_sd %||% data$noise_sd %||% NA_real_ else simulate_labels$noise_sd %||% NA_real_
  out$effective_noise_sd <- if (!is.null(data)) data$noise_sd %||% NA_real_ else NA_real_
  out$effective_snr <- if (!is.null(data)) data$effective_snr %||% NA_real_ else NA_real_
  out$effective_variance_snr <- if (!is.null(data)) {
    data$effective_variance_snr %||% {
      value <- data$effective_snr %||% NA_real_
      ifelse(is.na(value), NA_real_, value^2)
    }
  } else {
    NA_real_
  }
  out$runtime_status <- "failed"
  out$failure_stage <- stage
  out$n_failures <- 1L
  out$error_message <- as.character(error_message %||% NA_character_)
  out
}

build_truth_from_design <- function(design,
                                    active_functional = NULL,
                                    active_scalar = NULL,
                                    active_features = NULL) {
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
  if (!is.null(active_features) && length(active_features) > 0L) {
    active_mask <- active_mask | feature_map$feature %in% active_features
  }

  active_features <- feature_map$feature[active_mask]
  active_predictors <- unique(feature_map$predictor[active_mask])
  feature_truth <- feature_map
  feature_truth$active <- active_mask

  basis_mask <- feature_map$representation == "basis"
  basis_component <- ifelse(
    is.na(feature_map$component) | !nzchar(feature_map$component),
    feature_map$argval,
    feature_map$component
  )
  basis_component_universe <- basis_component_key(
    feature_map$predictor[basis_mask],
    feature_map$basis_type[basis_mask],
    basis_component[basis_mask]
  )
  active_basis_components <- basis_component_key(
    feature_map$predictor[basis_mask & active_mask],
    feature_map$basis_type[basis_mask & active_mask],
    basis_component[basis_mask & active_mask]
  )

  list(
    active_functional = active_functional,
    active_scalar = active_scalar,
    feature_truth = feature_truth,
    active_features = active_features,
    feature_universe = feature_map$feature,
    active_basis_components = unique(active_basis_components),
    basis_component_universe = unique(basis_component_universe),
    active_basis = unique(feature_map$predictor[basis_mask & active_mask]),
    basis_universe = unique(feature_map$predictor[basis_mask]),
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
#'   [fda_design()]: `"grid"` keeps the raw curves, `"bspline"` applies a
#'   spline-basis transform, and `"fpca"` applies FPCA scores. The older
#'   `"basis"` label is accepted as an alias for `"bspline"`.
#' @param transforms Optional transform list passed to [fda_design()]. When
#'   omitted, a sensible default is chosen from `representation`.
#' @param basis_df Degrees of freedom used when `representation = "bspline"`.
#' @param n_components Number of FPCA components used when
#'   `representation = "fpca"`.
#' @param scenario Benchmark scenario. Supported values are:
#'   `"localized_dense"` for dense local signal, `"confounded_blocks"` for
#'   correlated nuisance blocks, `"smooth_sparse"` for smooth coefficients on a
#'   sparse active domain, `"basis_block_signal"` for signal aligned with
#'   basis-like blocks, `"fpca_low_rank_signal"` for signal carried by the first
#'   FPCA components, `"null_signal"` for no true active effect, and
#'   `"mislocalized_signal"` for fragmented signal that is intentionally poorly
#'   aligned with interval/locality rules. `"distributed_smooth"` is retained as
#'   a backwards-compatible alias for the earlier broad smooth scenario.
#' @param confounding_strength Strength of cross-block confounding injected into
#'   the nuisance curve. Higher values make plain `SelectBoost` less able to
#'   separate true local signals from correlated nuisance structure.
#' @param active_region_scale Positive multiplier applied to the width of the
#'   active regions. Values below `1` create narrower active regions.
#' @param local_correlation Non-negative smoothing parameter applied to the
#'   simulated curves. Larger values increase local correlation along the grid.
#' @param include_scalar Should scalar covariates be included in the design and
#'   truth object?
#' @param noise_axis Optional label describing whether the benchmark setting is
#'   part of the default, fixed-SNR, or fixed-noise axis.
#' @param noise_sd Observation noise level. Ignored for Gaussian responses when
#'   `snr` is supplied.
#' @param snr Optional target signal-to-noise standard-deviation ratio for
#'   Gaussian responses. When supplied, the observation noise standard deviation
#'   is set to `sd(linear_predictor) / snr`.
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
                                  representation = c("grid", "bspline", "fpca", "basis"),
                                  transforms = NULL,
                                  basis_df = 7L,
                                  n_components = 5L,
                                  scenario = c(
                                    "localized_dense",
                                    "confounded_blocks",
                                    "smooth_sparse",
                                    "basis_block_signal",
                                    "fpca_low_rank_signal",
                                    "null_signal",
                                    "mislocalized_signal",
                                    "distributed_smooth"
                                  ),
                                  confounding_strength = NULL,
                                  active_region_scale = 1,
                                  local_correlation = 0,
                                  include_scalar = TRUE,
                                  noise_axis = NULL,
                                  noise_sd = 0.4,
                                  snr = NULL,
                                  seed = NULL) {
  family <- match.arg(family)
  representation <- match.arg(representation)
  representation <- if (identical(representation, "basis")) "bspline" else representation
  scenario <- match.arg(scenario)
  n <- as.integer(n)
  grid_length <- as.integer(grid_length)
  basis_df <- as.integer(basis_df)
  n_components <- as.integer(n_components)
  if (is.null(confounding_strength)) {
    confounding_strength <- if (identical(scenario, "confounded_blocks")) 0.7 else 0
  }
  if (is.null(noise_axis) || length(noise_axis) == 0L ||
      (length(noise_axis) == 1L && is.na(noise_axis))) {
    noise_axis <- if (is.null(snr)) "noise_sd" else "snr"
  }
  noise_axis <- match.arg(as.character(noise_axis[1L]), c("default", "noise_sd", "snr"))
  if (!is.numeric(noise_sd) || length(noise_sd) != 1L || is.na(noise_sd) || noise_sd < 0) {
    stop("`noise_sd` must be a single non-negative number.", call. = FALSE)
  }
  if (!is.null(snr) &&
      (!is.numeric(snr) || length(snr) != 1L || is.na(snr) || !is.finite(snr) || snr <= 0)) {
    stop("`snr` must be NULL or a single positive finite number.", call. = FALSE)
  }

  with_optional_seed(seed, {
    grid <- seq(0, 1, length.out = grid_length)
    latent_signal_1 <- stats::rnorm(n)
    latent_signal_2 <- stats::rnorm(n)
    latent_nuisance <- stats::rnorm(n)
    latent_effect <- NULL
    if (identical(scenario, "localized_dense")) {
      signal_shape_1 <- exp(-((grid - 0.25) / 0.08) ^ 2)
      signal_shape_2 <- sin(2 * pi * grid) * exp(-((grid - 0.65) / 0.18) ^ 2)
      nuisance_shape_1 <- cos(pi * grid)
      nuisance_shape_2 <- exp(-((grid - 0.78) / 0.09) ^ 2)
      signal_noise_sd <- 0.10
      nuisance_noise_sd <- 0.12
      region_bounds <- rbind(
        c(max(1L, floor(0.15 * grid_length)), max(2L, floor(0.28 * grid_length))),
        c(max(1L, floor(0.52 * grid_length)), max(2L, floor(0.68 * grid_length)))
      )
      region_bounds <- rescale_region_bounds(region_bounds, active_region_scale = active_region_scale, grid_length = grid_length)
      region_weights <- c(1.6, -1.25)
      nuisance <- confounding_strength * outer(latent_signal_1, nuisance_shape_2) +
        outer(latent_nuisance, nuisance_shape_1) +
        outer(stats::rnorm(n), nuisance_shape_2)
    } else if (identical(scenario, "smooth_sparse")) {
      signal_shape_1 <- sin(pi * grid) * exp(-((grid - 0.34) / 0.18) ^ 2)
      signal_shape_2 <- cos(2 * pi * grid) * exp(-((grid - 0.72) / 0.12) ^ 2)
      nuisance_shape_1 <- cos(pi * grid)
      nuisance_shape_2 <- sin(4 * pi * grid)
      signal_noise_sd <- 0.10
      nuisance_noise_sd <- 0.13
      region_bounds <- rbind(
        c(max(1L, floor(0.28 * grid_length)), max(2L, floor(0.42 * grid_length))),
        c(max(1L, floor(0.68 * grid_length)), max(2L, floor(0.80 * grid_length)))
      )
      region_bounds <- rescale_region_bounds(region_bounds, active_region_scale = active_region_scale, grid_length = grid_length)
      region_weights <- c(1.25, -1.0)
      nuisance <- confounding_strength * outer(latent_signal_2, nuisance_shape_2) +
        outer(latent_nuisance, nuisance_shape_1) +
        outer(stats::rnorm(n), nuisance_shape_2)
    } else if (identical(scenario, "basis_block_signal")) {
      signal_shape_1 <- pmax(0, 1 - abs(grid - 0.32) / 0.14) ^ 3
      signal_shape_2 <- pmax(0, 1 - abs(grid - 0.67) / 0.13) ^ 3
      nuisance_shape_1 <- pmax(0, 1 - abs(grid - 0.48) / 0.18) ^ 2
      nuisance_shape_2 <- cos(2 * pi * grid)
      signal_noise_sd <- 0.08
      nuisance_noise_sd <- 0.12
      region_bounds <- rbind(
        c(max(1L, floor(0.22 * grid_length)), max(2L, floor(0.42 * grid_length))),
        c(max(1L, floor(0.57 * grid_length)), max(2L, floor(0.78 * grid_length)))
      )
      region_bounds <- rescale_region_bounds(region_bounds, active_region_scale = active_region_scale, grid_length = grid_length)
      region_weights <- c(1.35, -1.05)
      nuisance <- confounding_strength * outer(latent_signal_1, nuisance_shape_1) +
        outer(latent_nuisance, nuisance_shape_2)
    } else if (identical(scenario, "fpca_low_rank_signal")) {
      signal_shape_1 <- sqrt(2) * sin(pi * grid)
      signal_shape_2 <- sqrt(2) * cos(2 * pi * grid)
      nuisance_shape_1 <- sqrt(2) * sin(3 * pi * grid)
      nuisance_shape_2 <- sqrt(2) * cos(4 * pi * grid)
      signal_noise_sd <- 0.08
      nuisance_noise_sd <- 0.12
      region_bounds <- matrix(c(1L, grid_length), ncol = 2L)
      region_weights <- 1
      latent_effect <- 1.4 * latent_signal_1 - 1.0 * latent_signal_2
      nuisance <- confounding_strength * outer(latent_signal_2, nuisance_shape_1) +
        outer(latent_nuisance, nuisance_shape_2)
    } else if (identical(scenario, "null_signal")) {
      signal_shape_1 <- sin(pi * grid)
      signal_shape_2 <- cos(2 * pi * grid)
      nuisance_shape_1 <- cos(pi * grid)
      nuisance_shape_2 <- sin(3 * pi * grid)
      signal_noise_sd <- 0.16
      nuisance_noise_sd <- 0.16
      region_bounds <- matrix(integer(0), ncol = 2L)
      region_weights <- numeric()
      latent_effect <- rep(0, n)
      nuisance <- outer(latent_nuisance, nuisance_shape_1) +
        outer(stats::rnorm(n), nuisance_shape_2)
    } else if (identical(scenario, "mislocalized_signal")) {
      signal_shape_1 <- sin(5 * pi * grid) * exp(-((grid - 0.50) / 0.34) ^ 2)
      signal_shape_2 <- cos(7 * pi * grid) * exp(-((grid - 0.55) / 0.32) ^ 2)
      nuisance_shape_1 <- exp(-((grid - 0.35) / 0.20) ^ 2)
      nuisance_shape_2 <- exp(-((grid - 0.70) / 0.20) ^ 2)
      signal_noise_sd <- 0.10
      nuisance_noise_sd <- 0.13
      centers <- pmax(1L, pmin(grid_length, round(c(0.18, 0.31, 0.49, 0.73) * grid_length)))
      half_width <- max(0L, floor(0.025 * grid_length * active_region_scale))
      region_bounds <- cbind(
        pmax(1L, centers - half_width),
        pmin(grid_length, centers + half_width)
      )
      region_weights <- c(1.15, -1.1, 0.95, -0.9)
      nuisance <- confounding_strength * outer(latent_signal_1, nuisance_shape_1) +
        outer(latent_nuisance, nuisance_shape_2)
    } else if (identical(scenario, "distributed_smooth")) {
      signal_shape_1 <- sin(pi * grid)
      signal_shape_2 <- cos(2 * pi * grid)
      nuisance_shape_1 <- sin(3 * pi * grid)
      nuisance_shape_2 <- cos(pi * grid)
      signal_noise_sd <- 0.12
      nuisance_noise_sd <- 0.14
      region_bounds <- rbind(
        c(max(1L, floor(0.10 * grid_length)), max(2L, floor(0.42 * grid_length))),
        c(max(1L, floor(0.58 * grid_length)), max(2L, floor(0.92 * grid_length)))
      )
      region_bounds <- rescale_region_bounds(region_bounds, active_region_scale = active_region_scale, grid_length = grid_length)
      region_weights <- c(1.0, -0.9)
      nuisance <- confounding_strength * outer(latent_signal_1, nuisance_shape_2) +
        outer(latent_nuisance, nuisance_shape_1) +
        outer(stats::rnorm(n), nuisance_shape_2)
    } else {
      signal_shape_1 <- exp(-((grid - 0.22) / 0.07) ^ 2)
      signal_shape_2 <- exp(-((grid - 0.62) / 0.10) ^ 2)
      nuisance_shape_1 <- exp(-((grid - 0.28) / 0.08) ^ 2)
      nuisance_shape_2 <- cos(2 * pi * grid)
      signal_noise_sd <- 0.10
      nuisance_noise_sd <- 0.12
      region_bounds <- rbind(
        c(max(1L, floor(0.16 * grid_length)), max(2L, floor(0.26 * grid_length))),
        c(max(1L, floor(0.56 * grid_length)), max(2L, floor(0.70 * grid_length)))
      )
      region_bounds <- rescale_region_bounds(region_bounds, active_region_scale = active_region_scale, grid_length = grid_length)
      region_weights <- c(1.5, -1.1)
      nuisance <- confounding_strength * outer(latent_signal_1, nuisance_shape_1) +
        outer(latent_nuisance, nuisance_shape_2)
    }

    signal <- outer(latent_signal_1, signal_shape_1) +
      outer(latent_signal_2, signal_shape_2) +
      matrix(stats::rnorm(n * grid_length, sd = signal_noise_sd), nrow = n)
    nuisance <- nuisance + matrix(stats::rnorm(n * grid_length, sd = nuisance_noise_sd), nrow = n)
    signal <- smooth_curve_matrix(signal, local_correlation = local_correlation)
    nuisance <- smooth_curve_matrix(nuisance, local_correlation = local_correlation)

    region_effects <- if (nrow(region_bounds) > 0L) {
      vapply(seq_len(nrow(region_bounds)), function(i) {
        idx <- seq.int(region_bounds[i, 1], region_bounds[i, 2])
        rowMeans(signal[, idx, drop = FALSE]) * region_weights[i]
      }, numeric(n))
    } else {
      matrix(0, nrow = n, ncol = 0L)
    }

    scalar_covariates <- NULL
    scalar_truth <- NULL
    linear_predictor <- if (is.null(latent_effect)) rowSums(region_effects) else latent_effect
    if (isTRUE(include_scalar)) {
      age <- stats::rnorm(n, mean = 50, sd = 7)
      treatment <- stats::rbinom(n, size = 1, prob = 0.45)
      scalar_covariates <- data.frame(age = age, treatment = treatment)
      if (!identical(scenario, "null_signal")) {
        linear_predictor <- linear_predictor + 0.05 * age - 0.6 * treatment
        scalar_truth <- data.frame(
          predictor = c("age", "treatment"),
          feature = c("age", "treatment"),
          weight = c(0.05, -0.6),
          stringsAsFactors = FALSE
        )
      }
    }

    signal_sd <- stats::sd(linear_predictor)
    effective_noise_sd <- noise_sd
    effective_snr <- if (is.finite(signal_sd) && signal_sd > 0 && noise_sd > 0) {
      signal_sd / noise_sd
    } else {
      NA_real_
    }
    if (!is.null(snr) && identical(family, "gaussian")) {
      effective_noise_sd <- if (is.finite(signal_sd) && signal_sd > 0) {
        signal_sd / snr
      } else {
        noise_sd
      }
      effective_snr <- if (is.finite(signal_sd) && signal_sd > 0 && effective_noise_sd > 0) {
        signal_sd / effective_noise_sd
      } else {
        NA_real_
      }
    }

    response <- if (identical(family, "gaussian")) {
      linear_predictor + stats::rnorm(n, sd = effective_noise_sd)
    } else {
      lp_sd <- stats::sd(linear_predictor)
      scaled_predictor <- if (!is.finite(lp_sd) || lp_sd == 0) {
        rep(0, length(linear_predictor))
      } else {
        as.numeric(scale(linear_predictor)[, 1])
      }
      prob <- stats::plogis(scaled_predictor)
      stats::rbinom(n, size = 1, prob = prob)
    }

    predictors <- list(
      signal = fda_grid(signal, argvals = grid, name = "signal"),
      nuisance = fda_grid(nuisance, argvals = grid, name = "nuisance")
    )

    current_transforms <- transforms
    if (is.null(current_transforms)) {
      current_transforms <- switch(
        representation,
        grid = NULL,
        bspline = list(
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
      transforms = current_transforms,
      scalar_transform = if (isTRUE(include_scalar)) fda_standardize() else NULL
    )

    active_functional <- if (nrow(region_bounds) > 0L) {
      data.frame(
        predictor = rep("signal", nrow(region_bounds)),
        start_position = region_bounds[, 1],
        end_position = region_bounds[, 2],
        start_argval = grid[region_bounds[, 1]],
        end_argval = grid[region_bounds[, 2]],
        weight = region_weights,
        stringsAsFactors = FALSE
      )
    } else {
      data.frame(
        predictor = character(),
        start_position = integer(),
        end_position = integer(),
        start_argval = numeric(),
        end_argval = numeric(),
        weight = numeric(),
        stringsAsFactors = FALSE
      )
    }

    active_feature_override <- NULL
    truth_active_functional <- active_functional
    if (identical(scenario, "fpca_low_rank_signal") && identical(representation, "fpca")) {
      feature_map <- design$feature_map
      active_feature_override <- feature_map$feature[
        feature_map$predictor == "signal" &
          feature_map$basis_type == "fpca" &
          feature_map$component %in% c("PC1", "PC2")
      ]
      truth_active_functional <- NULL
    }

    truth <- build_truth_from_design(
      design = design,
      active_functional = truth_active_functional,
      active_scalar = scalar_truth,
      active_features = active_feature_override
    )
    if (identical(scenario, "fpca_low_rank_signal") && identical(representation, "fpca")) {
      truth$active_functional <- active_functional
    }

    output <- list(
      grid = grid,
      response = response,
      predictors = lapply(predictors, `[[`, "values"),
      scalar_covariates = scalar_covariates,
      design = design,
      truth = truth,
      linear_predictor = linear_predictor,
      scenario = scenario,
      confounding_strength = confounding_strength,
      active_region_scale = active_region_scale,
      local_correlation = local_correlation,
      representation = representation,
      family = family,
      noise_axis = noise_axis,
      snr = snr %||% NA_real_,
      noise_sd = effective_noise_sd,
      requested_noise_sd = noise_sd,
      effective_snr = effective_snr,
      effective_variance_snr = if (is.na(effective_snr)) NA_real_ else effective_snr^2
    )
    class(output) <- "fda_simulation_data"
    output
  })
}

#' @export
print.fda_simulation_data <- function(x, ...) {
  cat("FDA simulation data\n")
  cat("  observations:", nrow(x$design$matrix$x), "\n")
  cat("  features:", ncol(x$design$matrix$x), "\n")
  cat("  active features:", length(x$truth$active_features), "\n")
  cat("  scenario:", x$scenario, "\n")
  cat("  confounding strength:", x$confounding_strength, "\n")
  cat("  active region scale:", x$active_region_scale, "\n")
  cat("  local correlation:", x$local_correlation, "\n")
  cat("  noise axis:", x$noise_axis %||% NA_character_, "\n")
  cat("  noise sd:", x$noise_sd %||% NA_real_, "\n")
  cat("  effective signal-to-noise SD ratio:", x$effective_snr %||% NA_real_, "\n")
  target_snr <- x$snr %||% NA_real_
  if (length(target_snr) == 1L && !is.na(target_snr)) {
    cat("  target snr:", target_snr, "\n")
  }
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
    selection_targets_for_map(
      map = selection_map(x, level = "basis", cutoff = cutoff, ...),
      level = "basis"
    )
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
    out$scenario <- data$scenario
    out$representation <- data$representation
    out$family <- data$family
    out$noise_axis <- data$noise_axis %||% NA_character_
    out$snr <- data$snr %||% NA_real_
    out$noise_sd <- data$requested_noise_sd %||% data$noise_sd %||% NA_real_
    out$effective_noise_sd <- data$noise_sd %||% NA_real_
    out$effective_snr <- data$effective_snr %||% NA_real_
    out$effective_variance_snr <- data$effective_variance_snr %||% {
      value <- data$effective_snr %||% NA_real_
      ifelse(is.na(value), NA_real_, value^2)
    }
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

#' Summarize Benchmark Performance by Method
#'
#' Collapses raw benchmark rows into method-level performance summaries, with an
#' option to retain only the best `c0` per method and replication.
#'
#' @param x An `fda_benchmark` or `fda_simulation_study` object.
#' @param level Evaluation level.
#' @param metric Metric used to pick the best `c0` when `select_c0 = "best"`.
#' @param optimize Should larger or smaller values of `metric` be preferred?
#' @param select_c0 Keep all `c0` rows or only the best one per method and
#'   replicate.
#'
#' @returns A data frame.
#' @export
summarise_benchmark_performance <- function(x,
                                            level = c("feature", "group", "basis"),
                                            metric = "f1",
                                            optimize = c("max", "min"),
                                            select_c0 = c("best", "all")) {
  metrics <- benchmark_metrics_from_object(x)
  rows <- best_metric_rows(
    metrics = metrics,
    level = match.arg(level),
    metric = metric,
    optimize = match.arg(optimize),
    select_c0 = match.arg(select_c0)
  )
  aggregate_benchmark_rows(rows)
}

#' Summarize the Advantage of FDA-SelectBoost Over Baselines
#'
#' Computes the per-scenario and per-level gain of a target method over one or
#' more reference methods. This is intended to make the benchmark story explicit
#' when comparing FDA-aware `SelectBoost` to existing baselines.
#'
#' @param x An `fda_benchmark` or `fda_simulation_study` object.
#' @param target Method whose gain should be assessed.
#' @param reference One or more baseline methods.
#' @param level Evaluation level.
#' @param metric Metric used both for best-`c0` selection and for the reported
#'   gains.
#' @param optimize Should larger or smaller values of `metric` be preferred?
#' @param select_c0 Keep all `c0` rows or only the best one per method and
#'   replicate.
#'
#' @returns A data frame.
#' @export
summarise_benchmark_advantage <- function(x,
                                          target = "selectboost",
                                          reference = c("plain_selectboost", "stability"),
                                          level = c("feature", "group", "basis"),
                                          metric = "f1",
                                          optimize = c("max", "min"),
                                          select_c0 = c("best", "all")) {
  metrics <- benchmark_metrics_from_object(x)
  rows <- best_metric_rows(
    metrics = metrics,
    level = match.arg(level),
    metric = metric,
    optimize = match.arg(optimize),
    select_c0 = match.arg(select_c0)
  )
  advantage <- advantage_rows(
    metrics = rows,
    target = target,
    reference = reference,
    metric = metric
  )
  aggregate_advantage_rows(advantage)
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

#' Run a Targeted Sensitivity Study for FDA-SelectBoost
#'
#' Repeats the FDA benchmark over a grid of simulation settings and a grid of
#' FDA-aware `SelectBoost` settings. This is intended to answer the specific
#' benchmark question of when `selectboost_fda()` improves on plain
#' `SelectBoost`.
#'
#' @param n_rep Number of replications per setting combination.
#' @param simulate_grid Data frame of simulation-setting combinations. Columns
#'   are merged into `simulate_args` and can include `scenario`,
#'   `confounding_strength`, `active_region_scale`, and `local_correlation`.
#' @param selectboost_grid Data frame of `selectboost_fda()` setting
#'   combinations. Columns are merged into `benchmark_args$selectboost_args`
#'   and can include `association_method`, `bandwidth`, `width`, or `step`.
#' @param simulate_args Named list forwarded to `simulate_fda_scenario()`.
#' @param benchmark_args Named list forwarded to `benchmark_selection_methods()`.
#'   When omitted, the study compares FDA-aware `SelectBoost`, plain
#'   `SelectBoost`, and grouped stability selection.
#' @param seed Optional seed used to derive deterministic per-replication and
#'   per-setting seeds.
#' @param keep_results Should the individual benchmark objects be returned?
#' @param progress Optional callback function used for long-running studies.
#'   When supplied, it is called with named arguments including `event`,
#'   `replicate`, `completed_runs`, `total_runs`, and `metrics` at
#'   `setting_complete` and `replicate_complete`. No files are written by
#'   default.
#'
#' The returned raw metrics include runtime diagnostics for each setting:
#' elapsed, user, and system time; warning and failure counts; runtime status;
#' error messages for failed settings; and fitted benchmark object size in MB
#' when available. Failed benchmark settings are retained as rows with missing
#' recovery metrics and `runtime_status = "failed"`.
#'
#' @returns An object inheriting from `fda_selectboost_sensitivity_study` and
#'   `fda_simulation_study`.
#' @examples
#' grid <- data.frame(
#'   scenario = "confounded_blocks",
#'   confounding_strength = 0.9,
#'   active_region_scale = 0.7,
#'   local_correlation = 2,
#'   stringsAsFactors = FALSE
#' )
#' methods <- data.frame(
#'   association_method = c("correlation", "hybrid"),
#'   bandwidth = c(NA, 4),
#'   stringsAsFactors = FALSE
#' )
#' study <- run_selectboost_sensitivity_study(
#'   n_rep = 1,
#'   simulate_grid = grid,
#'   selectboost_grid = methods,
#'   simulate_args = list(n = 24, grid_length = 16),
#'   benchmark_args = list(
#'     methods = c("selectboost", "plain_selectboost"),
#'     levels = "feature",
#'     selectboost_args = list(B = 3, steps.seq = 0.5, c0lim = FALSE),
#'     plain_selectboost_args = list(B = 3, steps.seq = 0.5, c0lim = FALSE)
#'   ),
#'   seed = 1
#' )
#' summarise_benchmark_advantage(
#'   study,
#'   target = "selectboost",
#'   reference = "plain_selectboost",
#'   level = "feature"
#' )
#' @export
run_selectboost_sensitivity_study <- function(n_rep = 10L,
                                              simulate_grid = expand.grid(
                                                scenario = c("localized_dense", "confounded_blocks", "smooth_sparse", "null_signal"),
                                                confounding_strength = c(0.4, 0.9),
                                                active_region_scale = c(1, 0.7),
                                                local_correlation = c(0, 2),
                                                stringsAsFactors = FALSE
                                              ),
                                              selectboost_grid = expand.grid(
                                                association_method = c("correlation", "neighborhood", "hybrid", "interval"),
                                                bandwidth = c(NA, 4, 8),
                                                stringsAsFactors = FALSE
                                              ),
                                              simulate_args = list(),
                                              benchmark_args = list(),
                                              seed = NULL,
                                              keep_results = FALSE,
                                              progress = NULL) {
  n_rep <- as.integer(n_rep)
  if (n_rep < 1L) {
    stop("`n_rep` must be a positive integer.", call. = FALSE)
  }
  if (!is.null(progress) && !is.function(progress)) {
    stop("`progress` must be NULL or a callback function.", call. = FALSE)
  }
  if (!is.data.frame(simulate_grid) || nrow(simulate_grid) == 0L) {
    stop("`simulate_grid` must be a non-empty data frame.", call. = FALSE)
  }
  if (!is.data.frame(selectboost_grid) || nrow(selectboost_grid) == 0L) {
    stop("`selectboost_grid` must be a non-empty data frame.", call. = FALSE)
  }

  benchmark_args <- benchmark_args %||% list()
  if (is.null(benchmark_args$methods)) {
    benchmark_args$methods <- c("stability", "selectboost", "plain_selectboost")
  }

  total_runs <- n_rep * nrow(simulate_grid) * nrow(selectboost_grid)
  benchmark_results <- if (isTRUE(keep_results)) vector("list", total_runs) else NULL
  metric_rows <- vector("list", total_runs)
  counter <- 1L
  emit_progress <- function(event, ...) {
    if (is.function(progress)) {
      progress(event = event, ...)
    }
    invisible(NULL)
  }

  emit_progress(
    "study_start",
    n_rep = n_rep,
    n_simulate_settings = nrow(simulate_grid),
    n_selectboost_settings = nrow(selectboost_grid),
    completed_runs = 0L,
    total_runs = total_runs
  )

  for (replicate in seq_len(n_rep)) {
    replicate_seed <- next_seed(seed, replicate)
    replicate_rows <- vector("list", nrow(simulate_grid) * nrow(selectboost_grid))
    replicate_counter <- 1L
    emit_progress(
      "replicate_start",
      replicate = replicate,
      replicate_seed = replicate_seed,
      completed_runs = counter - 1L,
      total_runs = total_runs
    )

    for (i in seq_len(nrow(simulate_grid))) {
      simulate_args_current <- utils::modifyList(
        simulate_args,
        grid_row_as_list(simulate_grid, i, na_to_null = TRUE)
      )
      simulate_args_current$seed <- next_seed(replicate_seed, i)
      simulation_capture <- capture_runtime_result(
        do.call(simulate_fda_scenario, simulate_args_current)
      )
      simulation_timing <- simulation_capture$timing
      sim <- simulation_capture$value
      simulate_labels <- grid_row_as_list(simulate_grid, i, na_to_null = FALSE)
      emit_progress(
        "simulation_complete",
        replicate = replicate,
        simulate_index = i,
        simulation_seed = simulate_args_current$seed,
        simulation_elapsed = unname(simulation_timing[["elapsed"]]),
        simulation_user = timing_value(simulation_timing, "user.self"),
        simulation_system = timing_value(simulation_timing, "sys.self"),
        n_warnings = length(simulation_capture$warnings),
        n_failures = if (is.null(simulation_capture$error)) 0L else 1L,
        runtime_status = if (is.null(simulation_capture$error)) "completed" else "failed",
        error_message = if (is.null(simulation_capture$error)) NA_character_ else conditionMessage(simulation_capture$error),
        simulate_labels = simulate_labels,
        completed_runs = counter - 1L,
        total_runs = total_runs
      )

      for (j in seq_len(nrow(selectboost_grid))) {
        selectboost_labels <- grid_row_as_list(selectboost_grid, j, na_to_null = FALSE)
        benchmark_seed <- next_seed(next_seed(simulate_args_current$seed, j), nrow(simulate_grid))

        if (!is.null(simulation_capture$error)) {
          metrics <- failed_benchmark_metrics(
            methods = benchmark_args$methods,
            levels = benchmark_args$levels %||% c("feature", "group"),
            data = NULL,
            simulate_labels = simulate_labels,
            stage = "simulation",
            error_message = conditionMessage(simulation_capture$error)
          )
          metrics$replicate <- replicate
          metrics$setting_index <- counter
          metrics$simulation_seed <- simulate_args_current$seed
          metrics$benchmark_seed <- benchmark_seed
          metrics$simulation_user <- timing_value(simulation_timing, "user.self")
          metrics$simulation_system <- timing_value(simulation_timing, "sys.self")
          metrics$simulation_elapsed <- timing_value(simulation_timing, "elapsed")
          metrics$benchmark_user <- NA_real_
          metrics$benchmark_system <- NA_real_
          metrics$benchmark_elapsed <- NA_real_
          metrics$setting_user <- metrics$simulation_user
          metrics$setting_system <- metrics$simulation_system
          metrics$setting_elapsed <- metrics$simulation_elapsed
          metrics$n_warnings <- length(simulation_capture$warnings)
          metrics$warning_messages <- paste(simulation_capture$warnings, collapse = " | ")
          metrics$result_size_mb <- NA_real_
          metrics <- append_parameter_columns(metrics, simulate_labels)
          metrics <- append_parameter_columns(metrics, selectboost_labels)
          metric_rows[[counter]] <- metrics
          replicate_rows[[replicate_counter]] <- metrics

          emit_progress(
            "setting_complete",
            replicate = replicate,
            simulate_index = i,
            selectboost_index = j,
            simulation_seed = simulate_args_current$seed,
            benchmark_seed = benchmark_seed,
            simulate_labels = simulate_labels,
            selectboost_labels = selectboost_labels,
            rows = nrow(metrics),
            simulation_elapsed = timing_value(simulation_timing, "elapsed"),
            simulation_user = timing_value(simulation_timing, "user.self"),
            simulation_system = timing_value(simulation_timing, "sys.self"),
            benchmark_elapsed = NA_real_,
            benchmark_user = NA_real_,
            benchmark_system = NA_real_,
            setting_elapsed = timing_value(simulation_timing, "elapsed"),
            setting_user = timing_value(simulation_timing, "user.self"),
            setting_system = timing_value(simulation_timing, "sys.self"),
            n_warnings = length(simulation_capture$warnings),
            n_failures = 1L,
            runtime_status = "failed",
            error_message = conditionMessage(simulation_capture$error),
            metrics = metrics,
            completed_runs = counter,
            total_runs = total_runs
          )

          counter <- counter + 1L
          replicate_counter <- replicate_counter + 1L
          next
        }

        selectboost_args_current <- utils::modifyList(
          benchmark_args$selectboost_args %||% list(),
          grid_row_as_list(selectboost_grid, j, na_to_null = TRUE)
        )

        if (identical(selectboost_args_current$association_method, "interval") &&
            is.null(selectboost_args_current$width)) {
          selectboost_args_current$width <- default_interval_width(sim$design)
          if (is.null(selectboost_args_current$step)) {
            selectboost_args_current$step <- selectboost_args_current$width
          }
        }

        benchmark_args_current <- benchmark_args
        benchmark_args_current$selectboost_args <- selectboost_args_current
        emit_progress(
          "setting_start",
          replicate = replicate,
          simulate_index = i,
          selectboost_index = j,
          simulation_seed = simulate_args_current$seed,
          benchmark_seed = benchmark_seed,
          simulate_labels = simulate_labels,
          selectboost_labels = selectboost_labels,
          completed_runs = counter - 1L,
          total_runs = total_runs
        )
        benchmark_capture <- capture_runtime_result(
          with_optional_seed(
            benchmark_seed,
            do.call(
              benchmark_selection_methods,
              c(list(data = sim), benchmark_args_current)
            )
          )
        )
        benchmark_timing <- benchmark_capture$timing
        bench <- benchmark_capture$value

        metrics <- if (is.null(benchmark_capture$error)) {
          bench$metrics
        } else {
          failed_benchmark_metrics(
            methods = benchmark_args$methods,
            levels = benchmark_args$levels %||% c("feature", "group"),
            data = sim,
            stage = "benchmark",
            error_message = conditionMessage(benchmark_capture$error)
          )
        }
        metrics$replicate <- replicate
        metrics$setting_index <- counter
        metrics$simulation_seed <- simulate_args_current$seed
        metrics$benchmark_seed <- benchmark_seed
        metrics$simulation_user <- timing_value(simulation_timing, "user.self")
        metrics$simulation_system <- timing_value(simulation_timing, "sys.self")
        metrics$simulation_elapsed <- timing_value(simulation_timing, "elapsed")
        metrics$benchmark_user <- timing_value(benchmark_timing, "user.self")
        metrics$benchmark_system <- timing_value(benchmark_timing, "sys.self")
        metrics$benchmark_elapsed <- timing_value(benchmark_timing, "elapsed")
        metrics$setting_user <- metrics$simulation_user + metrics$benchmark_user
        metrics$setting_system <- metrics$simulation_system + metrics$benchmark_system
        metrics$setting_elapsed <- metrics$simulation_elapsed + metrics$benchmark_elapsed
        runtime_warnings <- unique(c(simulation_capture$warnings, benchmark_capture$warnings))
        metrics$n_warnings <- length(runtime_warnings)
        metrics$warning_messages <- paste(runtime_warnings, collapse = " | ")
        metrics$n_failures <- if (is.null(benchmark_capture$error)) 0L else 1L
        metrics$runtime_status <- if (is.null(benchmark_capture$error)) "completed" else "failed"
        metrics$failure_stage <- if (is.null(benchmark_capture$error)) NA_character_ else "benchmark"
        metrics$error_message <- if (is.null(benchmark_capture$error)) NA_character_ else conditionMessage(benchmark_capture$error)
        metrics$result_size_mb <- if (is.null(benchmark_capture$error)) object_size_mb(bench) else NA_real_
        metrics <- append_parameter_columns(metrics, simulate_labels)
        metrics <- append_parameter_columns(metrics, selectboost_labels)
        metric_rows[[counter]] <- metrics
        replicate_rows[[replicate_counter]] <- metrics

        if (isTRUE(keep_results)) {
          benchmark_results[[counter]] <- list(
            replicate = replicate,
            simulation = simulate_labels,
            selectboost = selectboost_labels,
            benchmark = bench
          )
        }

        emit_progress(
          "setting_complete",
          replicate = replicate,
          simulate_index = i,
          selectboost_index = j,
          simulation_seed = simulate_args_current$seed,
          benchmark_seed = benchmark_seed,
          simulate_labels = simulate_labels,
          selectboost_labels = selectboost_labels,
          rows = nrow(metrics),
          simulation_elapsed = timing_value(simulation_timing, "elapsed"),
          simulation_user = timing_value(simulation_timing, "user.self"),
          simulation_system = timing_value(simulation_timing, "sys.self"),
          benchmark_elapsed = timing_value(benchmark_timing, "elapsed"),
          benchmark_user = timing_value(benchmark_timing, "user.self"),
          benchmark_system = timing_value(benchmark_timing, "sys.self"),
          setting_elapsed = timing_value(simulation_timing, "elapsed") + timing_value(benchmark_timing, "elapsed"),
          setting_user = timing_value(simulation_timing, "user.self") + timing_value(benchmark_timing, "user.self"),
          setting_system = timing_value(simulation_timing, "sys.self") + timing_value(benchmark_timing, "sys.self"),
          n_warnings = length(runtime_warnings),
          n_failures = if (is.null(benchmark_capture$error)) 0L else 1L,
          runtime_status = if (is.null(benchmark_capture$error)) "completed" else "failed",
          error_message = if (is.null(benchmark_capture$error)) NA_character_ else conditionMessage(benchmark_capture$error),
          result_size_mb = if (is.null(benchmark_capture$error)) object_size_mb(bench) else NA_real_,
          metrics = metrics,
          completed_runs = counter,
          total_runs = total_runs
        )

        counter <- counter + 1L
        replicate_counter <- replicate_counter + 1L
      }
    }
    emit_progress(
      "replicate_complete",
      replicate = replicate,
      replicate_seed = replicate_seed,
      metrics = rbind_fill_data_frames(replicate_rows),
      completed_runs = counter - 1L,
      total_runs = total_runs
    )
  }

  metrics <- rbind_fill_data_frames(metric_rows)
  emit_progress(
    "study_complete",
    metrics = metrics,
    completed_runs = total_runs,
    total_runs = total_runs
  )
  structure(
    list(
      metrics = metrics,
      summary_table = summarise_simulation_metrics(metrics),
      results = benchmark_results,
      simulate_grid = simulate_grid,
      selectboost_grid = selectboost_grid
    ),
    class = c("fda_selectboost_sensitivity_study", "fda_simulation_study")
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
