resolve_selectboost_selector <- function(selector,
                                         selector_fun,
                                         groups,
                                         family,
                                         selector_args) {
  if (is.function(selector)) {
    selector_fun <- selector
    selector <- "custom"
  }

  if (!is.null(selector_fun)) {
    return(function(X, Y, ...) {
      do.call(
        selector_fun,
        c(list(X = X, y = Y, groups = groups, family = family), selector_args, list(...))
      )
    })
  }

  selector <- match.arg(selector, c("msgps", "glmnet", "grpreg"))

  if (identical(selector, "msgps")) {
    return(function(X, Y, ...) {
      do.call(SelectBoost::lasso_msgps_AICc, c(list(X = X, Y = Y), selector_args, list(...)))
    })
  }

  if (identical(selector, "glmnet")) {
    return(function(X, Y, ...) {
      do.call(
        glmnet_coefficients,
        c(list(X = X, y = Y, family = family), selector_args, list(...))
      )
    })
  }

  function(X, Y, ...) {
    do.call(
      grpreg_coefficients,
      c(list(X = X, y = Y, groups = groups, family = family), selector_args, list(...))
    )
  }
}

#' FDA-Oriented SelectBoost Wrapper
#'
#' Wraps [SelectBoost::fastboost()] or [SelectBoost::autoboost()] while adding
#' FDA-specific structure through block-aware and region-aware grouping.
#'
#' @param x Any input accepted by `as_functional_matrix()`, or an `fda_design`
#'   object.
#' @param y Response vector. Leave as `NULL` when `x` is an `fda_design`.
#' @param mode `"fast"` for a fixed `c0` grid or `"auto"` for the adaptive
#'   version.
#' @param selector Base selector used inside SelectBoost. Choose from `"msgps"`,
#'   `"glmnet"`, `"grpreg"`, or provide a custom function.
#' @param selector_fun Optional custom base selector. It must return a
#'   coefficient vector of length `p`.
#' @param selector_args Optional named list of arguments forwarded to the base
#'   selector.
#' @param groups Optional feature groups used by grouped base selectors such as
#'   `"grpreg"`. Defaults to block-level groups for list inputs.
#' @param family Model family passed to built-in selectors.
#' @param association Optional custom association matrix used to define
#'   FDA-aware groups.
#' @param group_method Functional grouping backend: threshold-based or
#'   community-based.
#' @param within_blocks Should SelectBoost groups stay within functional blocks?
#' @param bandwidth Optional maximum within-block lag retained in groups.
#' @param ... Additional arguments passed to `SelectBoost::fastboost()` or
#'   `SelectBoost::autoboost()`.
#'
#' @returns An object of class `selectboost_fda_result`.
#' @export
selectboost_fda <- function(x,
                            y = NULL,
                            mode = c("fast", "auto"),
                            selector = c("msgps", "glmnet", "grpreg"),
                            selector_fun = NULL,
                            selector_args = list(),
                            groups = NULL,
                            family = c("gaussian", "binomial"),
                            association = NULL,
                            group_method = c("threshold", "community"),
                            within_blocks = TRUE,
                            bandwidth = NULL,
                            ...) {
  family_input <- if (missing(family)) NULL else family
  input <- resolve_fit_input(x = x, y = y, family = family_input)
  fda_x <- input$x
  y <- input$y
  mode <- match.arg(mode)
  family <- input$family
  group_method <- match.arg(group_method)

  groups <- normalize_groups(
    groups %||% if (length(unique(fda_x$blocks)) > 1L) fda_x$blocks else NULL,
    p = ncol(fda_x$x)
  )

  group_fn <- make_functional_grouping_function(
    x = fda_x,
    association = association,
    method = group_method,
    within_blocks = within_blocks,
    bandwidth = bandwidth
  )
  selector_fn <- resolve_selectboost_selector(
    selector = selector,
    selector_fun = selector_fun,
    groups = groups,
    family = family,
    selector_args = selector_args
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
    within_blocks = within_blocks,
    bandwidth = bandwidth,
    feature_selection = feature_selection
  )
  class(output) <- c("selectboost_fda_result", "fda_selection_fit")
  output
}

#' @export
print.selectboost_fda_result <- function(x, ...) {
  cat("FDA SelectBoost result\n")
  cat("  family:", x$family, "\n")
  cat("  mode:", x$mode, "\n")
  cat("  features:", nrow(x$feature_selection), "\n")
  cat("  groups:", length(unique(x$groups)), "\n")
  cat("  c0 values:", ncol(x$feature_selection), "\n")
  invisible(x)
}
