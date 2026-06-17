monotonicity_path_key <- function(data) {
  split_cols <- intersect(
    c("id", "level", "method", "scenario", "replicate", "q", "c0"),
    names(data)
  )
  split_cols <- setdiff(split_cols, data$axis[1L])
  interaction_no_na(data[split_cols])
}

monotonicity_delta <- function(values, direction) {
  delta <- c(NA_real_, diff(values))
  if (identical(direction, "nonincreasing")) {
    violation <- !is.na(delta) & delta > 0
    size <- ifelse(violation, delta, 0)
  } else {
    violation <- !is.na(delta) & delta < 0
    size <- ifelse(violation, abs(delta), 0)
  }
  list(delta = delta, violation = violation, violation_size = size)
}

#' Check Selection-Path Monotonicity
#'
#' Diagnoses whether selection scores are monotone along the `c0` or `q` axis.
#'
#' @param x A fitted selection object or data frame accepted by
#'   [as_monotonicity_path_data()].
#' @param axis Axis over which paths are checked.
#' @param direction Expected monotonicity direction.
#' @param level Selection level.
#' @param value Selection column to check.
#' @param tolerance Numerical tolerance for violations.
#' @param ... Additional arguments passed to [as_monotonicity_path_data()].
#'
#' @returns A data frame of class `fda_monotonicity_diagnostic`.
#' @export
check_selection_monotonicity <- function(x,
                                         axis = c("c0", "q"),
                                         direction = c("nonincreasing", "nondecreasing"),
                                         level = c("feature", "group", "basis"),
                                         value = c("selection", "mean_selection", "max_selection"),
                                         tolerance = 1e-8,
                                         ...) {
  axis <- match.arg(axis)
  direction <- match.arg(direction)
  level <- match.arg(level)
  value <- match.arg(value)
  paths <- as_monotonicity_path_data(
    x,
    axis = axis,
    level = level,
    value = value,
    tolerance = tolerance,
    ...
  )
  if (nrow(paths) == 0L) {
    out <- data.frame(
      id = character(), level = character(), axis = character(),
      n_steps = integer(), n_violations = integer(),
      max_violation = numeric(), total_violation = numeric(),
      is_monotone = logical(), stringsAsFactors = FALSE
    )
    class(out) <- c("fda_monotonicity_diagnostic", "data.frame")
    return(out)
  }

  keys <- monotonicity_path_key(paths)
  rows <- lapply(split(seq_len(nrow(paths)), keys), function(idx) {
    part <- paths[idx, , drop = FALSE]
    part <- part[order(part$axis_value), , drop = FALSE]
    deltas <- monotonicity_delta(part$value, direction = direction)
    violation <- deltas$violation & deltas$violation_size > tolerance
    data.frame(
      id = part$id[1L],
      level = part$level[1L],
      axis = axis,
      n_steps = nrow(part),
      n_violations = sum(violation, na.rm = TRUE),
      max_violation = if (all(is.na(deltas$violation_size))) NA_real_ else max(deltas$violation_size, na.rm = TRUE),
      total_violation = sum(deltas$violation_size[violation], na.rm = TRUE),
      is_monotone = !any(violation, na.rm = TRUE),
      stringsAsFactors = FALSE
    )
  })

  out <- rbind_fill_data_frames(rows)
  class(out) <- c("fda_monotonicity_diagnostic", "data.frame")
  out
}

enforce_one_path <- function(values, direction, method) {
  if (identical(method, "cummin")) {
    if (!identical(direction, "nonincreasing")) {
      stop("`method = \"cummin\"` enforces `direction = \"nonincreasing\"`.", call. = FALSE)
    }
    return(cummin(values))
  }
  if (identical(method, "cummax")) {
    if (!identical(direction, "nondecreasing")) {
      stop("`method = \"cummax\"` enforces `direction = \"nondecreasing\"`.", call. = FALSE)
    }
    return(cummax(values))
  }

  finite <- is.finite(values)
  adjusted <- values
  if (sum(finite) < 2L) {
    return(adjusted)
  }
  y <- if (identical(direction, "nonincreasing")) -values[finite] else values[finite]
  fitted <- stats::isoreg(seq_along(y), y)$yf
  adjusted[finite] <- if (identical(direction, "nonincreasing")) -fitted else fitted
  adjusted
}

#' Enforce Monotone Selection Paths
#'
#' Returns path data with an additional `adjusted_value` column after applying
#' cumulative or isotonic monotone post-processing.
#'
#' @param x A fitted selection object or data frame.
#' @param axis,direction,level,value Path specification.
#' @param method Monotone enforcement method.
#' @param ... Additional arguments passed to [as_monotonicity_path_data()].
#'
#' @returns A data frame preserving the path metadata and adding
#'   `adjusted_value`.
#' @export
enforce_monotone_selection <- function(x,
                                       axis = c("c0", "q"),
                                       direction = c("nonincreasing", "nondecreasing"),
                                       method = c("cummin", "cummax", "isotonic"),
                                       level = c("feature", "group", "basis"),
                                       value = c("selection", "mean_selection", "max_selection"),
                                       ...) {
  axis <- match.arg(axis)
  direction <- match.arg(direction)
  method <- match.arg(method)
  level <- match.arg(level)
  value <- match.arg(value)
  paths <- as_monotonicity_path_data(
    x,
    axis = axis,
    level = level,
    value = value,
    ...
  )
  if (nrow(paths) == 0L) {
    paths$adjusted_value <- numeric()
    return(paths)
  }

  keys <- monotonicity_path_key(paths)
  rows <- lapply(split(seq_len(nrow(paths)), keys), function(idx) {
    part <- paths[idx, , drop = FALSE]
    part <- part[order(part$axis_value), , drop = FALSE]
    part$adjusted_value <- enforce_one_path(part$value, direction = direction, method = method)
    deltas <- monotonicity_delta(part$adjusted_value, direction = direction)
    part$delta <- deltas$delta
    part$violation <- deltas$violation
    part$violation_size <- deltas$violation_size
    part
  })
  rbind_fill_data_frames(rows)
}

#' Summarize Monotonicity Diagnostics
#'
#' Collapses path-level monotonicity diagnostics into report-ready summaries.
#'
#' @param x A fitted object or an object returned by
#'   [check_selection_monotonicity()].
#' @param axis,direction,level,value,tolerance Passed to
#'   [check_selection_monotonicity()] when `x` is not already diagnostic data.
#' @param ... Additional arguments passed to [check_selection_monotonicity()].
#'
#' @returns A compact data frame with path counts and violation summaries.
#' @export
summarise_monotonicity <- function(x,
                                   axis = c("c0", "q"),
                                   direction = c("nonincreasing", "nondecreasing"),
                                   level = c("feature", "group", "basis"),
                                   value = c("selection", "mean_selection", "max_selection"),
                                   tolerance = 1e-8,
                                   ...) {
  diagnostic <- if (inherits(x, "fda_monotonicity_diagnostic")) {
    x
  } else {
    check_selection_monotonicity(
      x,
      axis = axis,
      direction = direction,
      level = level,
      value = value,
      tolerance = tolerance,
      ...
    )
  }
  if (nrow(diagnostic) == 0L) {
    return(data.frame(
      level = character(), axis = character(), n_paths = integer(),
      n_monotone = integer(), fraction_monotone = numeric(),
      mean_total_violation = numeric(), max_violation = numeric(),
      stringsAsFactors = FALSE
    ))
  }

  split_cols <- intersect(c("level", "axis"), names(diagnostic))
  keys <- interaction(diagnostic[split_cols], drop = TRUE, lex.order = TRUE)
  do.call(rbind, lapply(split(seq_len(nrow(diagnostic)), keys), function(idx) {
    part <- diagnostic[idx, , drop = FALSE]
    data.frame(
      level = part$level[1L],
      axis = part$axis[1L],
      n_paths = nrow(part),
      n_monotone = sum(part$is_monotone, na.rm = TRUE),
      fraction_monotone = mean(part$is_monotone, na.rm = TRUE),
      mean_total_violation = mean(part$total_violation, na.rm = TRUE),
      max_violation = max(part$max_violation, na.rm = TRUE),
      stringsAsFactors = FALSE
    )
  }))
}
