resolve_selector <- function(selector,
                             selector_fun,
                             groups,
                             family,
                             selector_args) {
  if (is.function(selector)) {
    selector_fun <- selector
    selector <- "custom"
  }

  if (!is.null(selector_fun)) {
    return(function(X, y) {
      do.call(
        selector_fun,
        c(list(X = X, y = y, groups = groups, family = family), selector_args)
      )
    })
  }

  selector_name <- selector_alias(selector, allow_msgps = FALSE)
  selector_groups <- resolve_selector_groups(selector_name, groups)

  if (identical(selector_name, "lasso")) {
    return(function(X, y) {
      do.call(
        glmnet_coefficients,
        c(list(X = X, y = y, family = family), selector_args)
      )
    })
  }

  if (identical(selector_name, "group_lasso")) {
    return(function(X, y) {
      do.call(
        grpreg_coefficients,
        c(list(X = X, y = y, groups = selector_groups, family = family), selector_args)
      )
    })
  }

  function(X, y) {
    do.call(
      sgl_coefficients,
      c(list(X = X, y = y, groups = selector_groups, family = family), selector_args)
    )
  }
}

coerce_selected <- function(value, p, tol = 1e-12) {
  value <- as.vector(value)
  if (length(value) != p) {
    stop("Base selector must return one coefficient or selection flag per feature.", call. = FALSE)
  }
  if (is.logical(value)) {
    return(value)
  }
  abs(as.numeric(value)) > tol
}

#' Grouped Stability Selection for Functional Predictors
#'
#' Repeatedly subsamples observations, refits a sparse base selector, and
#' computes exact feature- and group-level selection frequencies. This is the
#' generic FDA recipe for basis expansions, discretized curves, or FPCA scores.
#'
#' @param x Any input accepted by `as_functional_matrix()`, or an `fda_design`
#'   object.
#' @param y Response vector. Leave as `NULL` when `x` is an `fda_design`.
#' @param selector Either `"lasso"`, `"group_lasso"`,
#'   `"sparse_group_lasso"`, one of the backend-specific aliases
#'   (`"glmnet"`, `"grpreg"`, `"sgl"`), or a custom function.
#' @param selector_fun Optional custom selector. It must accept `X`, `y`,
#'   `groups`, and `family`, and return either a coefficient vector or a logical
#'   selection vector of length `p`.
#' @param groups Optional grouping structure. Defaults to block-level groups when
#'   `x` is supplied as a list, and otherwise to one group per feature.
#' @param family Model family passed to the built-in selectors.
#' @param B Number of subsampling replicates.
#' @param sample_fraction Fraction of observations drawn without replacement in
#'   each subsample.
#' @param cutoff Stability threshold used to define `selected_features` and
#'   `selected_groups`.
#' @param seed Optional random seed.
#' @param keep_subsamples Should the sampled row indices be returned?
#' @param ... Additional arguments forwarded to the built-in or custom selector.
#'
#' @returns An object of class `fda_stability_selection`.
#' @export
stability_selection_fda <- function(x,
                                    y = NULL,
                                    selector = "group_lasso",
                                    selector_fun = NULL,
                                    groups = NULL,
                                    family = c("gaussian", "binomial"),
                                    B = 100L,
                                    sample_fraction = 0.5,
                                    cutoff = 0.75,
                                    seed = NULL,
                                    keep_subsamples = FALSE,
                                    ...) {
  family_input <- if (missing(family)) NULL else family
  input <- resolve_fit_input(x = x, y = y, family = family_input)
  fda_x <- input$x
  y <- input$y
  family <- input$family

  if (!is.numeric(B) || length(B) != 1L || B < 1) {
    stop("`B` must be a positive integer.", call. = FALSE)
  }
  if (!is.numeric(sample_fraction) ||
      length(sample_fraction) != 1L ||
      sample_fraction <= 0 ||
      sample_fraction > 1) {
    stop("`sample_fraction` must be in `(0, 1]`.", call. = FALSE)
  }
  if (!is.numeric(cutoff) || length(cutoff) != 1L || cutoff <= 0 || cutoff > 1) {
    stop("`cutoff` must be in `(0, 1]`.", call. = FALSE)
  }

  groups <- normalize_groups(
    groups %||% if (length(unique(fda_x$blocks)) > 1L) fda_x$blocks else NULL,
    p = ncol(fda_x$x)
  )
  selector_fn <- resolve_selector(
    selector = selector,
    selector_fun = selector_fun,
    groups = groups,
    family = family,
    selector_args = list(...)
  )

  if (!is.null(seed)) {
    set.seed(seed)
  }

  n <- nrow(fda_x$x)
  subsample_size <- max(1L, floor(sample_fraction * n))
  feature_selected <- matrix(
    FALSE,
    nrow = ncol(fda_x$x),
    ncol = as.integer(B),
    dimnames = list(colnames(fda_x$x), paste0("rep", seq_len(as.integer(B))))
  )

  members <- split_groups(groups)
  group_selected <- matrix(
    FALSE,
    nrow = length(members),
    ncol = as.integer(B),
    dimnames = list(group_names(groups), colnames(feature_selected))
  )

  sampled_indices <- if (isTRUE(keep_subsamples)) vector("list", as.integer(B)) else NULL

  for (b in seq_len(as.integer(B))) {
    idx <- sort(sample.int(n, size = subsample_size, replace = FALSE))
    if (isTRUE(keep_subsamples)) {
      sampled_indices[[b]] <- idx
    }

    selected <- coerce_selected(
      selector_fn(fda_x$x[idx, , drop = FALSE], y[idx]),
      p = ncol(fda_x$x)
    )

    feature_selected[, b] <- selected
    group_selected[, b] <- vapply(members, function(member_idx) {
      any(selected[member_idx])
    }, logical(1))
  }

  feature_frequency <- rowMeans(feature_selected)
  group_frequency <- rowMeans(group_selected)

  result <- list(
    call = match.call(),
    x = fda_x,
    design = input$design,
    groups = groups,
    interval_table = attr(groups, "interval_table", exact = TRUE),
    family = family,
    B = as.integer(B),
    sample_fraction = sample_fraction,
    cutoff = cutoff,
    feature_frequency = feature_frequency,
    group_frequency = group_frequency,
    feature_selected = feature_selected,
    group_selected = group_selected,
    selected_features = names(feature_frequency)[feature_frequency >= cutoff],
    selected_groups = names(group_frequency)[group_frequency >= cutoff],
    sampled_indices = sampled_indices
  )
  class(result) <- c("fda_stability_selection", "fda_selection_fit")
  result
}

#' Interval Stability Selection
#'
#' Convenience wrapper around `stability_selection_fda()` that first creates
#' non-overlapping interval groups within each functional block.
#'
#' @param x Any input accepted by `as_functional_matrix()`, or an `fda_design`
#'   object.
#' @param y Response vector. Leave as `NULL` when `x` is an `fda_design`.
#' @param width Positive interval width.
#' @param step Step size between interval starts.
#' @param overlap Logical; should the interval groups overlap?
#' @param ... Additional arguments forwarded to `stability_selection_fda()`.
#'
#' @returns An object of class `fda_interval_stability_selection`.
#' @export
interval_stability_selection <- function(x, y = NULL, width, step = width, overlap = FALSE, ...) {
  interval_groups <- functional_interval_groups(
    x = x,
    width = width,
    step = step,
    overlap = overlap
  )
  result <- stability_selection_fda(x = x, y = y, groups = interval_groups, ...)
  result$interval_table <- attr(interval_groups, "interval_table")
  class(result) <- c("fda_interval_stability_selection", class(result))
  result
}

#' Stability Selection for FDboost Fits
#'
#' Thin adapter to the `stabsel.FDboost()` method. This is the native route when
#' the model itself is already fitted with `FDboost`.
#'
#' @param model A fitted `FDboost` object.
#' @param ... Additional arguments forwarded to [stabs::stabsel()].
#'
#' @returns A `stabsel` object.
#' @export
fdboost_stability_selection <- function(model, ...) {
  if (!requireNamespace("FDboost", quietly = TRUE)) {
    stop("Package `FDboost` is required for `fdboost_stability_selection()`.", call. = FALSE)
  }
  if (!requireNamespace("stabs", quietly = TRUE)) {
    stop("Package `stabs` is required for `fdboost_stability_selection()`.", call. = FALSE)
  }
  stabs::stabsel(model, ...)
}

#' @export
print.fda_stability_selection <- function(x, ...) {
  cat("FDA stability selection\n")
  cat("  family:", x$family, "\n")
  cat("  features:", ncol(x$x$x), "\n")
  cat("  groups:", length(group_names(x$groups)), "\n")
  cat("  replicates:", x$B, "\n")
  cat("  cutoff:", x$cutoff, "\n")
  invisible(x)
}
