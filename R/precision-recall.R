#' Compute FDA Precision-Recall Curves
#'
#' Wrapper around [as_precision_recall_path_data()] for threshold-path
#' evaluation of FDA selection results.
#'
#' @param x A fitted selection object, perturbation-grid object, benchmark
#'   object, simulation-study object, or selection-surface data frame.
#' @param truth Ground-truth object, typically from [simulate_fda_scenario()].
#' @param level Selection level.
#' @param value Selection column used for grouped and basis summaries.
#' @param threshold_grid Numeric thresholds.
#' @param ... Additional arguments passed to [as_precision_recall_path_data()].
#'
#' @returns A threshold-indexed metric data frame.
#' @export
precision_recall_curve_fda <- function(x,
                                       truth = NULL,
                                       level = c("feature", "group", "basis"),
                                       value = c("selection", "mean_selection", "max_selection"),
                                       threshold_grid = seq(0, 1, by = 0.01),
                                       ...) {
  as_precision_recall_path_data(
    x,
    truth = truth,
    level = match.arg(level),
    value = match.arg(value),
    threshold_grid = threshold_grid,
    ...
  )
}

coerce_precision_recall_data <- function(x, truth = NULL, ...) {
  required <- c("precision", "recall", "f1", "jaccard", "threshold")
  if (is.data.frame(x) && all(required %in% names(x))) {
    return(x)
  }
  as_precision_recall_path_data(x, truth = truth, ...)
}

#' Choose the Best FDA Selection Threshold
#'
#' Selects the best threshold from precision-recall path data.
#'
#' @param x Precision-recall data or an object accepted by
#'   [precision_recall_curve_fda()].
#' @param metric Optimization target.
#' @param min_precision,min_recall Optional constraints for constrained
#'   threshold selection.
#' @param truth Optional truth object when `x` is a fitted object.
#' @param ... Additional arguments passed to [as_precision_recall_path_data()].
#'
#' @returns The best row for each method/level/path group.
#' @export
best_threshold_fda <- function(x,
                               metric = c("f1", "jaccard", "precision_at_recall", "recall_at_precision"),
                               min_precision = NULL,
                               min_recall = NULL,
                               truth = NULL,
                               ...) {
  metric <- match.arg(metric)
  data <- coerce_precision_recall_data(x, truth = truth, ...)
  if (nrow(data) == 0L) {
    return(data)
  }

  split_cols <- intersect(c("method", "scenario", "replicate", "level", "q", "c0"), names(data))
  if (length(split_cols) == 0L) {
    split_cols <- "level"
  }
  keys <- interaction(data[split_cols], drop = TRUE, lex.order = TRUE)

  rows <- lapply(split(seq_len(nrow(data)), keys), function(idx) {
    part <- data[idx, , drop = FALSE]
    keep <- rep(TRUE, nrow(part))
    if (!is.null(min_precision)) {
      keep <- keep & !is.na(part$precision) & part$precision >= min_precision
    }
    if (!is.null(min_recall)) {
      keep <- keep & !is.na(part$recall) & part$recall >= min_recall
    }
    part <- part[keep, , drop = FALSE]
    if (nrow(part) == 0L) {
      return(NULL)
    }

    score <- switch(
      metric,
      f1 = part$f1,
      jaccard = part$jaccard,
      precision_at_recall = {
        if (is.null(min_recall)) {
          stop("`min_recall` is required for `metric = \"precision_at_recall\"`.", call. = FALSE)
        }
        part$precision
      },
      recall_at_precision = {
        if (is.null(min_precision)) {
          stop("`min_precision` is required for `metric = \"recall_at_precision\"`.", call. = FALSE)
        }
        part$recall
      }
    )
    score[is.na(score)] <- -Inf
    part[which.max(score), , drop = FALSE]
  })

  rbind_fill_data_frames(rows)
}

#' Summarize FDA Precision-Recall Paths
#'
#' Returns one best-threshold row per method and level.
#'
#' @param x Precision-recall data or an object accepted by
#'   [precision_recall_curve_fda()].
#' @param metric Metric optimized by [best_threshold_fda()].
#' @param truth Optional truth object when `x` is a fitted object.
#' @param ... Additional arguments passed to [best_threshold_fda()].
#'
#' @returns A compact data frame with best threshold and recovery metrics.
#' @export
summarise_precision_recall_fda <- function(x,
                                           metric = c("f1", "jaccard", "precision_at_recall", "recall_at_precision"),
                                           truth = NULL,
                                           ...) {
  best <- best_threshold_fda(
    x,
    metric = match.arg(metric),
    truth = truth,
    ...
  )
  if (nrow(best) == 0L) {
    return(data.frame(
      method = character(), level = character(), best_threshold = numeric(),
      precision = numeric(), recall = numeric(), f1 = numeric(),
      jaccard = numeric(), selection_rate = numeric(),
      stringsAsFactors = FALSE
    ))
  }

  out <- data.frame(
    method = best$method %||% NA_character_,
    level = best$level,
    best_threshold = best$threshold,
    precision = best$precision,
    recall = best$recall,
    f1 = best$f1,
    jaccard = best$jaccard,
    selection_rate = best$selection_rate,
    stringsAsFactors = FALSE
  )
  extra <- intersect(c("scenario", "replicate", "q", "c0"), names(best))
  cbind(out, best[extra])
}
