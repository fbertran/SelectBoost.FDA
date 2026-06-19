selection_levels <- function(level, default_all = TRUE) {
  choices <- c("feature", "group", "basis")
  if (missing(level) || is.null(level)) {
    if (isTRUE(default_all)) choices else choices[1L]
  } else {
    match.arg(level, choices, several.ok = TRUE)
  }
}

coerce_c0_value <- function(x) {
  if (is.null(x)) {
    return(NA_real_)
  }
  if (is.numeric(x)) {
    return(as.numeric(x))
  }
  x_chr <- as.character(x)
  parsed <- suppressWarnings(as.numeric(x_chr))
  needs_cleanup <- is.na(parsed) & !is.na(x_chr)
  if (any(needs_cleanup)) {
    cleaned <- gsub("[^0-9eE+.-]", "", x_chr[needs_cleanup])
    parsed[needs_cleanup] <- suppressWarnings(as.numeric(cleaned))
  }
  parsed
}

first_non_missing <- function(...) {
  values <- list(...)
  for (value in values) {
    if (!is.null(value)) {
      return(value)
    }
  }
  NULL
}

add_missing_columns <- function(data, columns, value = NA) {
  for (name in setdiff(columns, names(data))) {
    data[[name]] <- value
  }
  data
}

interaction_no_na <- function(data) {
  data <- as.data.frame(data, stringsAsFactors = FALSE)
  for (name in names(data)) {
    value <- as.character(data[[name]])
    value[is.na(value)] <- "..NA.."
    data[[name]] <- value
  }
  interaction(data, drop = TRUE, lex.order = TRUE)
}

selection_identifier <- function(data, level) {
  if (identical(level, "feature") && "feature" %in% names(data)) {
    return(as.character(data$feature))
  }
  if (identical(level, "group") && "group" %in% names(data)) {
    return(as.character(data$group))
  }
  if (identical(level, "basis")) {
    if ("predictor" %in% names(data)) {
      return(as.character(data$predictor))
    }
    if ("group" %in% names(data)) {
      return(as.character(data$group))
    }
  }
  if ("feature" %in% names(data)) {
    return(as.character(data$feature))
  }
  seq_len(nrow(data))
}

standardize_selection_surface <- function(data,
                                          level,
                                          q = NA_real_,
                                          c0 = NULL,
                                          threshold = 0,
                                          method = NA_character_) {
  if (is.null(data) || nrow(data) == 0L) {
    empty <- data.frame(level = character(), stringsAsFactors = FALSE)
    return(add_missing_columns(empty, selection_surface_columns()))
  }

  data <- as.data.frame(data, stringsAsFactors = FALSE)
  n <- nrow(data)
  if (!"level" %in% names(data)) {
    data$level <- rep(level, n)
  }

  if (!"q" %in% names(data)) {
    data$q <- rep(q, n)
  }
  if (!"c0" %in% names(data)) {
    data$c0 <- if (is.null(c0)) rep(NA_real_, n) else rep(c0, length.out = n)
  }
  data$c0 <- coerce_c0_value(data$c0)

  if (!"feature" %in% names(data)) {
    data$feature <- selection_identifier(data, level)
  }
  if (!"group" %in% names(data)) {
    data$group <- if ("block" %in% names(data)) data$block else data$predictor %||% data$feature
  }

  if (!"selection" %in% names(data)) {
    data$selection <- first_non_missing(
      data$feature_frequency,
      data$group_frequency,
      data$mean_selection,
      data$mean_feature_frequency,
      data$max_selection,
      data$max_feature_frequency,
      rep(NA_real_, n)
    )
  }
  if (!"mean_selection" %in% names(data)) {
    data$mean_selection <- first_non_missing(
      data$selection,
      data$mean_feature_frequency,
      data$group_frequency,
      rep(NA_real_, n)
    )
  }
  if (!"max_selection" %in% names(data)) {
    data$max_selection <- first_non_missing(
      data$selection,
      data$max_feature_frequency,
      data$group_frequency,
      rep(NA_real_, n)
    )
  }
  if (!"selected" %in% names(data)) {
    selected_value <- if (identical(level, "feature")) {
      data$selection
    } else {
      data$max_selection
    }
    data$selected <- selected_value > threshold
  }

  if (!"start_position" %in% names(data)) {
    data$start_position <- data$position %||% NA_integer_
  }
  if (!"end_position" %in% names(data)) {
    data$end_position <- data$position %||% data$start_position
  }
  if (!"start_argval" %in% names(data)) {
    data$start_argval <- data$argval %||% NA_character_
  }
  if (!"end_argval" %in% names(data)) {
    data$end_argval <- data$argval %||% data$start_argval
  }
  if (!"domain_start" %in% names(data)) {
    data$domain_start <- data$start_argval
  }
  if (!"domain_end" %in% names(data)) {
    data$domain_end <- data$end_argval
  }
  if (!"method" %in% names(data)) {
    data$method <- rep(method, n)
  }

  data <- add_missing_columns(data, selection_surface_columns())
  data[, unique(c(selection_surface_columns(), setdiff(names(data), selection_surface_columns()))), drop = FALSE]
}

selection_surface_columns <- function() {
  c(
    "feature", "predictor", "group", "level", "q", "c0", "selection",
    "mean_selection", "max_selection", "selected", "representation",
    "basis_type", "source_representation", "start_position", "end_position",
    "start_argval", "end_argval", "domain_start", "domain_end", "method"
  )
}

#' Extract Selection Surface Data
#'
#' Converts fitted FDA selection objects into renderer-neutral data frames.
#' The output can be consumed by base plotting, `ggplot2`, WebGL renderers, or
#' report-generation code without adding plotting dependencies to the package.
#'
#' @param x A `fda_perturbation_grid`, `selectboost_fda_result`,
#'   `fda_stability_selection`, `fda_method_comparison`, or data frame.
#' @param level Selection level. When omitted, all available levels are
#'   returned for fitted objects.
#' @param threshold Selection cutoff used to populate the `selected` column.
#' @param ... Additional arguments passed to [selection_map()] methods.
#'
#' @returns A data frame with feature, group, domain, `q`, `c0`, and selection
#'   columns.
#' @export
as_selection_surface_data <- function(x, level = NULL, threshold = 0, ...) {
  UseMethod("as_selection_surface_data")
}

#' @export
as_selection_surface_data.data.frame <- function(x, level = NULL, threshold = 0, ...) {
  level_value <- if ("level" %in% names(x) && length(unique(x$level)) == 1L) {
    unique(x$level)
  } else {
    selection_levels(level, default_all = FALSE)
  }
  standardize_selection_surface(x, level = level_value[1L], threshold = threshold)
}

#' @export
as_selection_surface_data.fda_perturbation_grid <- function(x,
                                                            level = NULL,
                                                            threshold = x$cutoff %||% 0,
                                                            ...) {
  out <- x$surface
  if (!is.null(level)) {
    levels <- selection_levels(level)
    out <- out[out$level %in% levels, , drop = FALSE]
  }
  standardize_selection_surface(out, level = "feature", threshold = threshold)
}

#' @export
as_selection_surface_data.selectboost_fda_result <- function(x,
                                                             level = NULL,
                                                             threshold = 0,
                                                             ...) {
  levels <- selection_levels(level)
  rows <- lapply(levels, function(current_level) {
    map <- selection_map(x, level = current_level, ...)
    standardize_selection_surface(
      map,
      level = current_level,
      threshold = threshold,
      method = if (inherits(x, "plain_selectboost_result")) "plain_selectboost" else "selectboost"
    )
  })
  rbind_fill_data_frames(rows)
}

#' @export
as_selection_surface_data.fda_stability_selection <- function(x,
                                                              level = NULL,
                                                              threshold = x$cutoff,
                                                              ...) {
  levels <- selection_levels(level)
  rows <- lapply(levels, function(current_level) {
    map <- selection_map(x, level = current_level, cutoff = threshold, ...)
    out <- standardize_selection_surface(
      map,
      level = current_level,
      q = x$sample_fraction %||% NA_real_,
      threshold = threshold,
      method = "stability_selection"
    )
    out$c0 <- NA_real_
    out
  })
  rbind_fill_data_frames(rows)
}

#' @export
as_selection_surface_data.fda_method_comparison <- function(x,
                                                            level = NULL,
                                                            threshold = 0,
                                                            ...) {
  levels <- selection_levels(level)
  rows <- vector("list", 0L)
  counter <- 1L
  for (method in names(x$fits)) {
    fit <- x$fits[[method]]
    if (!inherits(fit, c("fda_stability_selection", "selectboost_fda_result"))) {
      next
    }
    current <- as_selection_surface_data(fit, level = levels, threshold = threshold, ...)
    current$method <- method
    rows[[counter]] <- current
    counter <- counter + 1L
  }
  rbind_fill_data_frames(rows)
}

path_value_column <- function(data, value) {
  value <- match.arg(value, c("selection", "mean_selection", "max_selection"))
  if (!value %in% names(data)) {
    stop(sprintf("Column `%s` was not found in the selection data.", value), call. = FALSE)
  }
  value
}

split_path_indices <- function(data, axis) {
  id <- data$id
  split_cols <- intersect(
    c("method", "scenario", "replicate", "level", "q", "c0"),
    names(data)
  )
  split_cols <- setdiff(split_cols, axis)
  key_data <- data.frame(id = id, data[split_cols], stringsAsFactors = FALSE)
  interaction_no_na(key_data)
}

#' Extract Monotonicity Path Data
#'
#' Builds one row per selection path step across a chosen `c0` or `q` axis.
#'
#' @param x A selection fit or data frame accepted by
#'   [as_selection_surface_data()].
#' @param axis Axis over which paths are evaluated.
#' @param level Selection level.
#' @param value Selection column to track.
#' @param tolerance Numerical tolerance used for the default violation flag.
#' @param ... Additional arguments passed to [as_selection_surface_data()].
#'
#' @returns A data frame with path identifiers, axis values, deltas, and
#'   violation flags.
#' @export
as_monotonicity_path_data <- function(x,
                                      axis = c("c0", "q"),
                                      level = c("feature", "group", "basis"),
                                      value = c("selection", "mean_selection", "max_selection"),
                                      tolerance = sqrt(.Machine$double.eps),
                                      ...) {
  axis <- match.arg(axis)
  level <- match.arg(level)
  value <- path_value_column(as_selection_surface_data(x, level = level, ...), value)
  data <- as_selection_surface_data(x, level = level, ...)
  if (!axis %in% names(data)) {
    stop(sprintf("Axis `%s` was not found in the selection data.", axis), call. = FALSE)
  }

  data <- data[is.finite(data[[axis]]) | !is.na(data[[axis]]), , drop = FALSE]
  if (nrow(data) == 0L) {
    return(data.frame(
      id = character(), level = character(), axis = character(),
      axis_value = numeric(), value = numeric(), delta = numeric(),
      violation = logical(), violation_size = numeric(),
      stringsAsFactors = FALSE
    ))
  }

  data$id <- selection_identifier(data, level)
  keys <- split_path_indices(data, axis = axis)
  rows <- lapply(split(seq_len(nrow(data)), keys), function(idx) {
    part <- data[idx, , drop = FALSE]
    part <- part[order(part[[axis]], na.last = TRUE), , drop = FALSE]
    values <- part[[value]]
    delta <- c(NA_real_, diff(values))
    out <- data.frame(
      id = part$id,
      level = part$level,
      axis = axis,
      axis_value = part[[axis]],
      value = values,
      delta = delta,
      violation = !is.na(delta) & delta > tolerance,
      violation_size = ifelse(!is.na(delta) & delta > tolerance, delta, 0),
      stringsAsFactors = FALSE
    )
    keep <- intersect(c("method", "scenario", "replicate", "q", "c0"), names(part))
    cbind(out, part[keep])
  })

  rbind_fill_data_frames(rows)
}

truth_targets_for_surface <- function(data, truth, level) {
  truth <- resolve_truth_object(truth)
  if (identical(level, "feature")) {
    universe <- unique(as.character(data$feature))
    return(list(
      active = intersect(truth$active_features, universe),
      universe = universe
    ))
  }

  if (identical(level, "basis")) {
    universe <- unique(as.character(data$predictor))
    active <- intersect(truth$active_predictors %||% character(), universe)
    return(list(active = active, universe = universe))
  }

  feature_rows <- data[data$level == "feature", , drop = FALSE]
  if (nrow(feature_rows) > 0L && all(c("feature", "group") %in% names(feature_rows))) {
    universe <- unique(as.character(feature_rows$group))
    active <- unique(as.character(feature_rows$group[feature_rows$feature %in% truth$active_features]))
    return(list(active = intersect(active, universe), universe = universe))
  }

  universe <- unique(as.character(data$group))
  list(active = character(), universe = universe)
}

selection_targets_from_surface <- function(data, level, threshold, value) {
  metric <- if (identical(level, "feature")) {
    data$selection
  } else {
    data[[value]]
  }
  ids <- selection_identifier(data, level)
  unique(as.character(ids[metric >= threshold]))
}

#' Extract Precision-Recall Path Data
#'
#' Computes threshold-indexed precision, recall, F1, Jaccard, and selection
#' rates from a fitted FDA selection object or benchmark table.
#'
#' @param x A fitted selection object, perturbation-grid object, benchmark
#'   object, simulation-study object, or selection-surface data frame.
#' @param truth Optional simulation truth object. Required for fitted objects
#'   unless they already store truth.
#' @param level Selection level.
#' @param threshold_grid Numeric thresholds applied to selection scores.
#' @param value Selection column used for grouped and basis summaries.
#' @param ... Additional arguments passed to [as_selection_surface_data()].
#'
#' @returns A data frame with precision-recall metrics.
#' @export
as_precision_recall_path_data <- function(x,
                                          truth = NULL,
                                          level = c("feature", "group", "basis"),
                                          threshold_grid = seq(0, 1, by = 0.01),
                                          value = c("selection", "mean_selection", "max_selection"),
                                          ...) {
  UseMethod("as_precision_recall_path_data")
}

#' @export
as_precision_recall_path_data.fda_benchmark <- function(x,
                                                        truth = NULL,
                                                        level = c("feature", "group", "basis"),
                                                        threshold_grid = seq(0, 1, by = 0.01),
                                                        value = c("selection", "mean_selection", "max_selection"),
                                                        ...) {
  metrics <- x$metrics
  metrics$threshold <- if ("c0" %in% names(metrics)) coerce_c0_value(metrics$c0) else NA_real_
  metrics
}

#' @export
as_precision_recall_path_data.fda_simulation_study <- function(x,
                                                               truth = NULL,
                                                               level = c("feature", "group", "basis"),
                                                               threshold_grid = seq(0, 1, by = 0.01),
                                                               value = c("selection", "mean_selection", "max_selection"),
                                                               ...) {
  metrics <- x$metrics
  metrics$threshold <- if ("c0" %in% names(metrics)) coerce_c0_value(metrics$c0) else NA_real_
  metrics
}

#' @export
as_precision_recall_path_data.default <- function(x,
                                                  truth = NULL,
                                                  level = c("feature", "group", "basis"),
                                                  threshold_grid = seq(0, 1, by = 0.01),
                                                  value = c("selection", "mean_selection", "max_selection"),
                                                  ...) {
  level <- match.arg(level)
  value <- match.arg(value)
  if (is.null(truth) && inherits(x, "fda_perturbation_grid")) {
    truth <- x$truth
  }
  if (is.null(truth)) {
    stop("`truth` must be supplied to compute precision-recall paths.", call. = FALSE)
  }

  data <- as_selection_surface_data(x, level = c("feature", level), ...)
  targets <- if (inherits(x, c("selectboost_fda_result", "fda_stability_selection"))) {
    truth_targets_for_fit(x, truth = truth, level = level)
  } else if (inherits(x, "fda_perturbation_grid")) {
    truth_targets_for_fit(x, truth = truth, level = level)
  } else {
    truth_targets_for_surface(data, truth = truth, level = level)
  }

  level_data <- data[data$level == level, , drop = FALSE]
  split_cols <- intersect(c("method", "scenario", "replicate", "q", "c0", "level"), names(level_data))
  if (length(split_cols) == 0L) {
    split_cols <- "level"
  }
  split_keys <- interaction_no_na(level_data[split_cols])
  rows <- vector("list", 0L)
  counter <- 1L

  for (idx in split(seq_len(nrow(level_data)), split_keys)) {
    part <- level_data[idx, , drop = FALSE]
    for (threshold in threshold_grid) {
      predicted <- selection_targets_from_surface(
        data = part,
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
      out$threshold <- threshold
      keep <- intersect(c("method", "scenario", "replicate", "q", "c0"), names(part))
      out <- cbind(out, part[1L, keep, drop = FALSE])
      rows[[counter]] <- out
      counter <- counter + 1L
    }
  }

  rbind_fill_data_frames(rows)
}

#' Extract Association Heatmap Data
#'
#' Converts a functional association matrix into long-form data with feature
#' metadata for heatmaps or network displays.
#'
#' @param x Any input accepted by [as_functional_matrix()].
#' @param association Optional precomputed association matrix.
#' @param method,within_blocks,bandwidth,interval_groups,width,step,decay
#'   Passed to [functional_association()].
#'
#' @returns A long-form data frame with one row per matrix cell.
#' @export
as_association_heatmap_data <- function(x,
                                        association = NULL,
                                        method = c("correlation", "neighborhood", "hybrid", "interval"),
                                        within_blocks = TRUE,
                                        bandwidth = NULL,
                                        interval_groups = NULL,
                                        width = NULL,
                                        step = width,
                                        decay = 1) {
  fda_x <- as_functional_matrix(x)
  method <- match.arg(method)
  assoc <- functional_association(
    x = fda_x,
    association = association,
    method = method,
    within_blocks = within_blocks,
    bandwidth = bandwidth,
    interval_groups = interval_groups,
    width = width,
    step = step,
    decay = decay
  )
  fmap <- fda_x$feature_map
  p <- nrow(fmap)
  grid <- expand.grid(i = seq_len(p), j = seq_len(p))
  out <- data.frame(
    feature_i = fmap$feature[grid$i],
    feature_j = fmap$feature[grid$j],
    predictor_i = fmap$predictor[grid$i],
    predictor_j = fmap$predictor[grid$j],
    position_i = fmap$position[grid$i],
    position_j = fmap$position[grid$j],
    argval_i = fmap$argval[grid$i],
    argval_j = fmap$argval[grid$j],
    association = as.vector(assoc),
    same_block = fmap$block[grid$i] == fmap$block[grid$j],
    within_bandwidth = if (is.null(bandwidth)) {
      TRUE
    } else {
      abs(fmap$position[grid$i] - fmap$position[grid$j]) <= bandwidth
    },
    method = method,
    stringsAsFactors = FALSE
  )
  out
}

#' Extract Functional Interval Map Data
#'
#' Returns interval or group-level selection summaries with functional-domain
#' boundaries.
#'
#' @param x A fitted selection object or selection-surface data frame.
#' @param threshold Selection cutoff.
#' @param ... Additional arguments passed to [as_selection_surface_data()].
#'
#' @returns A data frame with interval labels, domain boundaries, and selection
#'   values.
#' @export
as_functional_interval_map_data <- function(x, threshold = 0, ...) {
  data <- as_selection_surface_data(x, level = "group", threshold = threshold, ...)
  if (nrow(data) == 0L) {
    return(data.frame(
      predictor = character(), interval_label = character(),
      interval_start = integer(), interval_end = integer(),
      domain_start = character(), domain_end = character(),
      selection = numeric(), selected = logical(), q = numeric(),
      c0 = numeric(), level = character(), stringsAsFactors = FALSE
    ))
  }
  interval_label <- data$interval_label %||% data$group
  interval_start <- data$interval_start %||% data$start_position
  interval_end <- data$interval_end %||% data$end_position
  data.frame(
    predictor = data$predictor,
    interval_label = interval_label,
    interval_start = interval_start,
    interval_end = interval_end,
    domain_start = data$domain_start,
    domain_end = data$domain_end,
    selection = data$selection,
    selected = data$selected,
    q = data$q,
    c0 = data$c0,
    level = data$level,
    stringsAsFactors = FALSE
  )
}

#' Extract Benchmark Summary Data
#'
#' Produces benchmark summary rows suitable for tables and figures.
#'
#' @param x A benchmark object, simulation-study object, or benchmark data
#'   frame.
#' @param level Evaluation level. When omitted, summaries are returned for all
#'   levels present in `x`.
#' @param metric Metric used to choose best `c0` rows when applicable.
#' @param select_c0 Passed to [summarise_benchmark_performance()].
#' @param ... Additional arguments passed to benchmark summary helpers.
#'
#' @returns A data frame with mean and standard-deviation metric columns.
#' @export
as_benchmark_summary_data <- function(x,
                                      level = NULL,
                                      metric = "f1",
                                      select_c0 = c("best", "all"),
                                      ...) {
  UseMethod("as_benchmark_summary_data")
}

#' @export
as_benchmark_summary_data.fda_benchmark <- function(x,
                                                   level = NULL,
                                                   metric = "f1",
                                                   select_c0 = c("best", "all"),
                                                   ...) {
  select_c0 <- match.arg(select_c0, c("best", "all"))
  levels <- if (is.null(level)) unique(x$metrics$level) else selection_levels(level)
  rows <- lapply(levels, function(current_level) {
    summarise_benchmark_performance(
      x,
      level = current_level,
      metric = metric,
      select_c0 = select_c0,
      ...
    )
  })
  normalize_benchmark_summary(rbind_fill_data_frames(rows))
}

#' @export
as_benchmark_summary_data.fda_simulation_study <- function(x,
                                                          level = NULL,
                                                          metric = "f1",
                                                          select_c0 = c("best", "all"),
                                                          ...) {
  select_c0 <- match.arg(select_c0, c("best", "all"))
  levels <- if (is.null(level)) unique(x$metrics$level) else selection_levels(level)
  rows <- lapply(levels, function(current_level) {
    summarise_benchmark_performance(
      x,
      level = current_level,
      metric = metric,
      select_c0 = select_c0,
      ...
    )
  })
  normalize_benchmark_summary(rbind_fill_data_frames(rows))
}

#' @export
as_benchmark_summary_data.data.frame <- function(x,
                                                 level = NULL,
                                                 metric = "f1",
                                                 select_c0 = c("best", "all"),
                                                 ...) {
  if (any(grepl("_mean$", names(x)))) {
    return(normalize_benchmark_summary(x))
  }
  normalize_benchmark_summary(summarise_simulation_metrics(x))
}

normalize_benchmark_summary <- function(data) {
  expected <- c(
    "scenario", "representation", "family", "method", "level",
    "association_method", "bandwidth", "group_method", "within_blocks",
    "n_rep", "precision_mean", "precision_sd", "recall_mean", "recall_sd",
    "f1_mean", "f1_sd", "jaccard_mean", "jaccard_sd",
    "selection_rate_mean", "selection_rate_sd",
    "effective_snr_mean", "effective_snr_sd",
    "effective_variance_snr_mean", "effective_variance_snr_sd"
  )
  data <- add_missing_columns(as.data.frame(data, stringsAsFactors = FALSE), expected)
  data[, unique(c(expected, setdiff(names(data), expected))), drop = FALSE]
}
