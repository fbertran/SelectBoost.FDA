subset_fda_matrix_rows <- function(x, rows) {
  out <- x
  out$x <- x$x[rows, , drop = FALSE]
  class(out) <- "fda_matrix"
  out
}

surface_group_key <- function(data) {
  id <- selection_identifier(data, level = data$level[1L])
  key_data <- data.frame(
    id = id,
    level = data$level,
    q = data$q,
    c0 = data$c0,
    method = data$method %||% NA_character_,
    stringsAsFactors = FALSE
  )
  interaction_no_na(key_data)
}

aggregate_surface_replicates <- function(data, cutoff = 0) {
  if (is.null(data) || nrow(data) == 0L) {
    return(data.frame())
  }
  keys <- surface_group_key(data)
  rows <- lapply(split(seq_len(nrow(data)), keys), function(idx) {
    part <- data[idx, , drop = FALSE]
    out <- part[1L, , drop = FALSE]
    numeric_cols <- intersect(c("selection", "mean_selection", "max_selection"), names(part))
    for (name in numeric_cols) {
      out[[name]] <- mean(part[[name]], na.rm = TRUE)
    }
    if ("replicate" %in% names(out)) {
      out$replicate <- NA_integer_
    }
    metric <- if (identical(out$level[1L], "feature")) out$selection else out$max_selection
    out$selected <- metric > cutoff
    out$n_replicates <- nrow(part)
    out
  })
  rbind_fill_data_frames(rows)
}

warning_row <- function(q, replicate, message) {
  data.frame(
    q = q,
    replicate = replicate,
    message = message,
    stringsAsFactors = FALSE
  )
}

#' Fit a Two-Parameter FDA Perturbation Grid
#'
#' Runs FDA-aware `SelectBoost` over a grid of subject subsampling rates and
#' `c0` perturbation strengths, returning a renderer-neutral selection surface.
#'
#' @param x Any input accepted by [as_functional_matrix()], or an
#'   `fda_design`.
#' @param y Response vector. Leave as `NULL` when `x` is an `fda_design`.
#' @param q_grid Subsampling fractions.
#' @param c0_grid SelectBoost `c0` values.
#' @param B Number of row-subsampling replicates.
#' @param selectboost_B Number of internal SelectBoost perturbation replicates
#'   per subsample.
#' @param selector,selector_fun,selector_args,family,association_method,group_method
#'   Base selector and FDA-aware grouping arguments passed to
#'   [selectboost_fda()].
#' @param within_blocks,bandwidth,width,step Functional association and
#'   interval-structure arguments passed to [selectboost_fda()].
#' @param levels Selection levels to store in the surface.
#' @param cutoff Selection cutoff used for the `selected` column.
#' @param seed Optional seed used in a local RNG scope.
#' @param n_cores Reserved for future parallel backends. The current
#'   implementation runs serially.
#' @param keep_fits Should individual fitted objects be retained?
#' @param ... Additional arguments passed to [selectboost_fda()].
#'
#' @returns An object of class `fda_perturbation_grid`.
#' @export
fit_perturbation_grid <- function(x,
                                  y = NULL,
                                  q_grid = c(0.5, 0.632, 0.8),
                                  c0_grid = seq(0.1, 0.9, by = 0.1),
                                  B = 100L,
                                  selectboost_B = 1L,
                                  selector = "group_lasso",
                                  selector_fun = NULL,
                                  selector_args = list(),
                                  family = c("gaussian", "binomial"),
                                  association_method = c("correlation", "neighborhood", "hybrid", "interval"),
                                  group_method = c("threshold", "community"),
                                  within_blocks = TRUE,
                                  bandwidth = NULL,
                                  width = NULL,
                                  step = width,
                                  levels = c("feature", "group", "basis"),
                                  cutoff = 0,
                                  seed = NULL,
                                  n_cores = 1L,
                                  keep_fits = FALSE,
                                  ...) {
  family_input <- if (missing(family)) NULL else family
  input <- resolve_fit_input(x = x, y = y, family = family_input)
  fda_x <- input$x
  response <- input$y
  family <- input$family
  association_method <- match.arg(association_method)
  group_method <- match.arg(group_method)
  levels <- selection_levels(levels)

  if (!is.numeric(q_grid) || anyNA(q_grid) || any(q_grid <= 0 | q_grid >= 1)) {
    stop("`q_grid` must contain values strictly between 0 and 1.", call. = FALSE)
  }
  if (!is.numeric(c0_grid) || anyNA(c0_grid) || any(c0_grid < 0 | c0_grid > 1)) {
    stop("`c0_grid` must contain values between 0 and 1.", call. = FALSE)
  }
  if (!is.numeric(B) || length(B) != 1L || B < 1) {
    stop("`B` must be a positive integer.", call. = FALSE)
  }
  if (!is.numeric(selectboost_B) || length(selectboost_B) != 1L || selectboost_B < 1) {
    stop("`selectboost_B` must be a positive integer.", call. = FALSE)
  }
  if (!is.numeric(cutoff) || length(cutoff) != 1L || cutoff < 0) {
    stop("`cutoff` must be a non-negative number.", call. = FALSE)
  }

  sample_sizes <- floor(q_grid * nrow(fda_x$x))
  if (any(sample_sizes < 3L)) {
    stop("Every `q_grid` value must produce at least three sampled observations.", call. = FALSE)
  }

  if (identical(association_method, "interval") && is.null(width)) {
    width <- default_interval_width(fda_x)
    step <- step %||% width
  }

  selectboost_args <- list(...)
  selectboost_args$mode <- selectboost_args$mode %||% "fast"
  selectboost_args$steps.seq <- c0_grid
  selectboost_args$c0lim <- FALSE
  selectboost_args$B <- as.integer(selectboost_B)

  fits <- if (isTRUE(keep_fits)) vector("list", length(q_grid) * as.integer(B)) else NULL
  surface_rows <- vector("list", length(q_grid) * as.integer(B))
  warning_rows <- vector("list", 0L)
  fit_counter <- 1L
  warning_counter <- 1L

  with_optional_seed(seed, {
    for (q_index in seq_along(q_grid)) {
      q <- q_grid[q_index]
      sample_size <- sample_sizes[q_index]
      for (replicate in seq_len(as.integer(B))) {
        idx <- sort(sample.int(nrow(fda_x$x), size = sample_size, replace = FALSE))
        x_sub <- subset_fda_matrix_rows(fda_x, idx)
        captured_warnings <- character()
        fit <- tryCatch(
          withCallingHandlers(
            do.call(
              selectboost_fda,
              c(
                list(
                  x = x_sub,
                  y = response[idx],
                  selector = selector,
                  selector_fun = selector_fun,
                  selector_args = selector_args,
                  family = family,
                  association_method = association_method,
                  group_method = group_method,
                  within_blocks = within_blocks,
                  bandwidth = bandwidth,
                  width = width,
                  step = step
                ),
                selectboost_args
              )
            ),
            warning = function(w) {
              captured_warnings <<- c(captured_warnings, conditionMessage(w))
              invokeRestart("muffleWarning")
            }
          ),
          error = function(e) e
        )

        if (inherits(fit, "error")) {
          warning_rows[[warning_counter]] <- warning_row(q, replicate, conditionMessage(fit))
          warning_counter <- warning_counter + 1L
          next
        }

        if (length(captured_warnings) > 0L) {
          warning_rows[[warning_counter]] <- warning_row(q, replicate, paste(unique(captured_warnings), collapse = " | "))
          warning_counter <- warning_counter + 1L
        }

        fit$design <- input$design
        current_surface <- as_selection_surface_data(fit, level = levels, threshold = cutoff)
        current_surface$q <- q
        current_surface$replicate <- replicate
        current_surface$association_method <- association_method
        current_surface$group_method <- group_method
        current_surface$within_blocks <- within_blocks
        current_surface$bandwidth <- bandwidth %||% NA_real_
        current_surface$width <- width %||% NA_real_
        surface_rows[[fit_counter]] <- current_surface

        if (isTRUE(keep_fits)) {
          fits[[fit_counter]] <- fit
        }
        fit_counter <- fit_counter + 1L
      }
    }
  })

  replicate_surface <- rbind_fill_data_frames(surface_rows)
  surface_data <- aggregate_surface_replicates(replicate_surface, cutoff = cutoff)
  warnings <- rbind_fill_data_frames(warning_rows)

  output <- list(
    call = match.call(),
    design = input$design,
    x = fda_x,
    q_grid = q_grid,
    c0_grid = c0_grid,
    B = as.integer(B),
    selectboost_B = as.integer(selectboost_B),
    selector = selector,
    selector_fun = selector_fun,
    selector_args = selector_args,
    association_method = association_method,
    group_method = group_method,
    within_blocks = within_blocks,
    bandwidth = bandwidth,
    width = width,
    step = step,
    seed = seed,
    n_cores = as.integer(n_cores),
    cutoff = cutoff,
    family = family,
    groups = if (nrow(replicate_surface) > 0L && "group" %in% names(replicate_surface)) unique(replicate_surface$group) else NULL,
    fits = fits,
    replicate_surface = replicate_surface,
    surface = surface_data,
    warnings = warnings,
    truth = NULL
  )
  class(output) <- c("fda_perturbation_grid", "fda_selection_fit")
  output
}

#' @export
print.fda_perturbation_grid <- function(x, ...) {
  cat("FDA perturbation grid\n")
  cat("  q values:", length(x$q_grid), "\n")
  cat("  c0 values:", length(x$c0_grid), "\n")
  cat("  row replicates:", x$B, "\n")
  cat("  surface rows:", nrow(x$surface), "\n")
  cat("  warnings:", nrow(x$warnings), "\n")
  invisible(x)
}

#' Summarize a Perturbation Grid
#'
#' @param object A `fda_perturbation_grid` object.
#' @param ... Unused.
#'
#' @returns A summary object.
#' @export
summary.fda_perturbation_grid <- function(object, ...) {
  structure(
    list(
      q_grid = object$q_grid,
      c0_grid = object$c0_grid,
      B = object$B,
      selectboost_B = object$selectboost_B,
      selector = object$selector,
      surface_summary = summarise_perturbation_grid(object),
      warnings = object$warnings
    ),
    class = "summary.fda_perturbation_grid"
  )
}

#' @export
print.summary.fda_perturbation_grid <- function(x, ...) {
  cat("FDA perturbation grid summary\n")
  cat("  q values:", paste(x$q_grid, collapse = ", "), "\n")
  cat("  c0 values:", paste(x$c0_grid, collapse = ", "), "\n")
  cat("  row replicates:", x$B, "\n")
  cat("  SelectBoost replicates:", x$selectboost_B, "\n")
  print(x$surface_summary, row.names = FALSE)
  invisible(x)
}

#' Summarize Perturbation-Grid Selection Surfaces
#'
#' @param x A `fda_perturbation_grid` object.
#' @param level Optional selection level filter.
#'
#' @returns A compact data frame grouped by `q`, `c0`, and level.
#' @export
summarise_perturbation_grid <- function(x, level = NULL) {
  data <- as_selection_surface_data(x, level = level)
  if (nrow(data) == 0L) {
    return(data.frame())
  }
  split_cols <- intersect(c("level", "q", "c0"), names(data))
  keys <- interaction(data[split_cols], drop = TRUE, lex.order = TRUE)
  do.call(rbind, lapply(split(seq_len(nrow(data)), keys), function(idx) {
    part <- data[idx, , drop = FALSE]
    data.frame(
      level = part$level[1L],
      q = part$q[1L],
      c0 = part$c0[1L],
      n_items = nrow(part),
      n_selected = sum(part$selected, na.rm = TRUE),
      mean_selection = mean(part$selection, na.rm = TRUE),
      max_selection = max(part$max_selection, na.rm = TRUE),
      stringsAsFactors = FALSE
    )
  }))
}

#' @export
selection_map.fda_perturbation_grid <- function(x,
                                                level = c("feature", "group", "basis"),
                                                q = NULL,
                                                c0 = NULL,
                                                ...) {
  level <- match.arg(level)
  data <- as_selection_surface_data(x, level = level)
  if (!is.null(q)) {
    data <- data[data$q %in% q, , drop = FALSE]
  }
  if (!is.null(c0)) {
    data <- data[data$c0 %in% coerce_c0_value(c0), , drop = FALSE]
  }
  data
}

#' @export
selected.fda_perturbation_grid <- function(x,
                                           level = c("feature", "group", "basis"),
                                           threshold = x$cutoff %||% 0,
                                           value = c("selection", "mean_selection", "max_selection"),
                                           ...) {
  level <- match.arg(level)
  value <- match.arg(value)
  data <- selection_map(x, level = level, ...)
  metric <- if (identical(level, "feature")) data$selection else data[[value]]
  data[metric > threshold, , drop = FALSE]
}

#' Extract a Selection Surface
#'
#' Convenience wrapper around [as_selection_surface_data()].
#'
#' @param x A fitted selection object or perturbation grid.
#' @param ... Additional arguments passed to [as_selection_surface_data()].
#'
#' @returns A selection-surface data frame.
#' @export
selection_surface <- function(x, ...) {
  as_selection_surface_data(x, ...)
}

#' Extract Selected Surface Rows
#'
#' Filters a selection surface by threshold.
#'
#' @param x A fitted selection object, perturbation grid, or selection-surface
#'   data frame.
#' @param threshold Selection threshold.
#' @param level Optional level filter.
#' @param value Selection column used for grouped and basis summaries.
#' @param ... Additional arguments passed to [as_selection_surface_data()].
#'
#' @returns A filtered selection-surface data frame.
#' @export
selected_surface <- function(x,
                             threshold = 0,
                             level = NULL,
                             value = c("selection", "mean_selection", "max_selection"),
                             ...) {
  value <- match.arg(value)
  data <- as_selection_surface_data(x, level = level, threshold = threshold, ...)
  metric <- ifelse(data$level == "feature", data$selection, data[[value]])
  data[metric > threshold, , drop = FALSE]
}

#' @export
plot.fda_perturbation_grid <- function(x,
                                       level = c("feature", "group", "basis"),
                                       value = c("selection", "mean_selection", "max_selection"),
                                       ...) {
  level <- match.arg(level)
  value <- match.arg(value)
  data <- selection_map(x, level = level)
  if (nrow(data) == 0L) {
    graphics::plot.new()
    graphics::title("Empty perturbation grid")
    return(invisible(x))
  }
  metric <- if (identical(level, "feature")) data$selection else data[[value]]
  graphics::plot(
    data$c0,
    metric,
    col = as.integer(factor(data$q)),
    pch = 16,
    xlab = "c0",
    ylab = value,
    main = paste("Selection surface:", level),
    ...
  )
  graphics::legend(
    "topright",
    legend = paste("q =", sort(unique(data$q))),
    col = seq_along(sort(unique(data$q))),
    pch = 16,
    bty = "n"
  )
  invisible(x)
}
