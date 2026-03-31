default_interval_width <- function(x) {
  fda_x <- as_functional_matrix(x)
  per_block <- tapply(fda_x$positions, fda_x$blocks, max)
  max(2L, floor(stats::median(as.numeric(per_block)) / 5))
}

next_seed <- function(seed, i) {
  if (is.null(seed)) {
    return(NULL)
  }
  as.integer(seed) + i - 1L
}

rbind_fill_data_frames <- function(dfs) {
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

summarise_calibration_stability <- function(fit, setting) {
  cbind(
    setting,
    data.frame(
      n_selected_features = length(fit$selected_features),
      n_selected_groups = length(fit$selected_groups),
      mean_feature_frequency = mean(fit$feature_frequency),
      max_feature_frequency = max(fit$feature_frequency),
      mean_group_frequency = mean(fit$group_frequency),
      max_group_frequency = max(fit$group_frequency),
      stringsAsFactors = FALSE
    )
  )
}

summarise_calibration_selectboost <- function(fit) {
  group_map <- selection_map(fit, level = "group")
  do.call(rbind, lapply(split(group_map, group_map$c0), function(part) {
    data.frame(
      c0 = part$c0[1],
      n_selected_features = sum(fit$feature_selection[, part$c0[1]] > 0),
      n_selected_groups = sum(part$max_selection > 0),
      mean_feature_selection = mean(fit$feature_selection[, part$c0[1]]),
      max_feature_selection = max(fit$feature_selection[, part$c0[1]]),
      mean_group_selection = mean(part$mean_selection),
      max_group_selection = max(part$max_selection),
      stringsAsFactors = FALSE
    )
  }))
}

#' Suggest a c0 Grid for FDA-SelectBoost
#'
#' Builds a data-driven `c0` grid from an FDA-aware association matrix.
#'
#' @param x Any input accepted by [as_functional_matrix()].
#' @param n Number of grid values to return.
#' @param method Grid construction rule: `"quantile"` or `"linear"`.
#' @param association_method Association structure passed to
#'   [functional_association()].
#' @param within_blocks,bandwidth,interval_groups,width,step,decay Passed to
#'   [functional_association()].
#'
#' @returns A decreasing numeric vector of `c0` values.
#' @export
suggest_c0_grid <- function(x,
                            n = 5L,
                            method = c("quantile", "linear"),
                            association_method = c("correlation", "neighborhood", "hybrid", "interval"),
                            within_blocks = TRUE,
                            bandwidth = NULL,
                            interval_groups = NULL,
                            width = NULL,
                            step = width,
                            decay = 1) {
  method <- match.arg(method)
  association_method <- match.arg(association_method)
  association <- functional_association(
    x = x,
    method = association_method,
    within_blocks = within_blocks,
    bandwidth = bandwidth,
    interval_groups = interval_groups,
    width = width,
    step = step,
    decay = decay
  )

  values <- association[upper.tri(association)]
  values <- values[is.finite(values) & values > 0]
  if (length(values) == 0L) {
    return(c(1, 0.5, 0))
  }

  grid <- if (identical(method, "quantile")) {
    stats::quantile(values, probs = seq(0.2, 0.9, length.out = as.integer(n)), names = FALSE)
  } else {
    seq(min(values), max(values), length.out = as.integer(n))
  }

  sort(unique(as.numeric(grid)), decreasing = TRUE)
}

#' Calibrate Stability-Selection Parameters
#'
#' Runs grouped stability selection over a grid of subsampling fractions and
#' cutoff values.
#'
#' @param design An `fda_design` object.
#' @param selector Base selector passed to [fit_stability()].
#' @param sample_fraction_grid Candidate subsampling fractions.
#' @param cutoff_grid Candidate cutoff values.
#' @param keep_fits Should the fitted objects be stored in the result?
#' @param seed Optional seed used to create deterministic per-grid seeds.
#' @param ... Additional arguments passed to [fit_stability()].
#'
#' @returns An object of class `fda_calibration_grid`.
#' @export
calibrate_stability_selection <- function(design,
                                          selector = "group_lasso",
                                          sample_fraction_grid = c(0.5, 0.632, 0.75),
                                          cutoff_grid = c(0.6, 0.75, 0.9),
                                          keep_fits = FALSE,
                                          seed = NULL,
                                          ...) {
  if (!inherits(design, "fda_design")) {
    stop("`design` must inherit from class `fda_design`.", call. = FALSE)
  }

  grid <- expand.grid(
    sample_fraction = sample_fraction_grid,
    cutoff = cutoff_grid,
    stringsAsFactors = FALSE
  )

  fits <- if (isTRUE(keep_fits)) vector("list", nrow(grid)) else NULL
  summary_rows <- vector("list", nrow(grid))

  for (i in seq_len(nrow(grid))) {
    fit <- fit_stability(
      design,
      selector = selector,
      sample_fraction = grid$sample_fraction[i],
      cutoff = grid$cutoff[i],
      seed = next_seed(seed, i),
      ...
    )
    if (isTRUE(keep_fits)) {
      fits[[i]] <- fit
    }
    summary_rows[[i]] <- summarise_calibration_stability(fit, grid[i, , drop = FALSE])
  }

  structure(
    list(
      type = "stability_selection",
      grid = do.call(rbind, summary_rows),
      fits = fits
    ),
    class = "fda_calibration_grid"
  )
}

#' Calibrate Interval Widths
#'
#' Runs interval stability selection over candidate interval widths.
#'
#' @param design An `fda_design` object.
#' @param widths Candidate interval widths.
#' @param step Optional step size. Defaults to `widths`.
#' @param overlap Should the interval groups overlap?
#' @param selector Base selector passed to [interval_stability_selection()].
#' @param keep_fits Should the fitted objects be stored in the result?
#' @param seed Optional seed used to create deterministic per-grid seeds.
#' @param ... Additional arguments passed to [interval_stability_selection()].
#'
#' @returns An object of class `fda_calibration_grid`.
#' @export
calibrate_interval_width <- function(design,
                                     widths,
                                     step = NULL,
                                     overlap = FALSE,
                                     selector = "lasso",
                                     keep_fits = FALSE,
                                     seed = NULL,
                                     ...) {
  if (!inherits(design, "fda_design")) {
    stop("`design` must inherit from class `fda_design`.", call. = FALSE)
  }

  widths <- as.integer(widths)
  if (any(widths < 1L)) {
    stop("`widths` must contain positive integers.", call. = FALSE)
  }

  fits <- if (isTRUE(keep_fits)) vector("list", length(widths)) else NULL
  summary_rows <- vector("list", length(widths))

  for (i in seq_along(widths)) {
    current_step <- step %||% if (isTRUE(overlap)) max(1L, widths[i] %/% 2L) else widths[i]
    interval_groups <- functional_interval_groups(
      x = design,
      width = widths[i],
      step = current_step,
      overlap = overlap
    )
    fit <- stability_selection_fda(
      x = design,
      selector = selector,
      groups = interval_groups,
      seed = next_seed(seed, i),
      ...
    )
    fit$interval_table <- attr(interval_groups, "interval_table", exact = TRUE)
    class(fit) <- c("fda_interval_stability_selection", class(fit))

    if (isTRUE(keep_fits)) {
      fits[[i]] <- fit
    }
    summary_rows[[i]] <- cbind(
      data.frame(width = widths[i], step = current_step, overlap = overlap, stringsAsFactors = FALSE),
      summarise_calibration_stability(fit, data.frame(dummy = 1))[setdiff(names(summarise_calibration_stability(fit, data.frame(dummy = 1))), "dummy")]
    )
  }

  structure(
    list(
      type = "interval_width",
      grid = do.call(rbind, summary_rows),
      fits = fits
    ),
    class = "fda_calibration_grid"
  )
}

#' Calibrate SelectBoost c0 Values
#'
#' Runs FDA-SelectBoost on a user-provided or suggested `c0` grid.
#'
#' @param design An `fda_design` object.
#' @param selector Base selector passed to [fit_selectboost()].
#' @param c0_grid Optional explicit `c0` grid.
#' @param grid_method Rule used by [suggest_c0_grid()] when `c0_grid` is
#'   omitted.
#' @param association_method Passed to [suggest_c0_grid()] and
#'   [fit_selectboost()].
#' @param keep_fit Should the fitted object be stored in the result?
#' @param ... Additional arguments passed to [fit_selectboost()].
#'
#' @returns An object of class `fda_calibration_grid`.
#' @export
calibrate_selectboost <- function(design,
                                  selector = "msgps",
                                  c0_grid = NULL,
                                  grid_method = c("quantile", "linear"),
                                  association_method = c("correlation", "neighborhood", "hybrid", "interval"),
                                  keep_fit = TRUE,
                                  ...) {
  if (!inherits(design, "fda_design")) {
    stop("`design` must inherit from class `fda_design`.", call. = FALSE)
  }

  grid_method <- match.arg(grid_method)
  association_method <- match.arg(association_method)
  if (is.null(c0_grid)) {
    c0_grid <- suggest_c0_grid(
      x = design,
      method = grid_method,
      association_method = association_method
    )
  }

  fit <- fit_selectboost(
    design,
    selector = selector,
    mode = "fast",
    association_method = association_method,
    steps.seq = c0_grid,
    c0lim = FALSE,
    ...
  )

  structure(
    list(
      type = "selectboost",
      grid = summarise_calibration_selectboost(fit),
      fits = if (isTRUE(keep_fit)) list(fit) else NULL
    ),
    class = "fda_calibration_grid"
  )
}

#' @export
print.fda_calibration_grid <- function(x, ...) {
  cat("FDA calibration grid\n")
  cat("  type:", x$type, "\n")
  cat("  rows:", nrow(x$grid), "\n")
  invisible(x)
}

compare_fit_summary <- function(fit, method) {
  if (inherits(fit, "selectboost_fda_result")) {
    summary_rows <- summarise_calibration_selectboost(fit)
    summary_rows$method <- method
    summary_rows
  } else if (inherits(fit, "fda_stability_selection")) {
    out <- data.frame(
      method = method,
      n_selected_features = length(fit$selected_features),
      n_selected_groups = length(fit$selected_groups),
      mean_feature_frequency = mean(fit$feature_frequency),
      max_feature_frequency = max(fit$feature_frequency),
      mean_group_frequency = mean(fit$group_frequency),
      max_group_frequency = max(fit$group_frequency),
      stringsAsFactors = FALSE
    )
    if (inherits(fit, "fda_interval_stability_selection")) {
      out$width <- unique(fit$interval_table$end - fit$interval_table$start + 1L)[1]
    }
    out
  } else {
    data.frame(method = method, stringsAsFactors = FALSE)
  }
}

#' Compare FDA Selection Methods
#'
#' Runs multiple selection workflows on the same `fda_design` object and
#' returns both the fitted objects and a comparison table.
#'
#' @param design An `fda_design` object.
#' @param methods Methods to run. Supported values are `"stability"`,
#'   `"interval"`, `"selectboost"`, `"plain_selectboost"`, and `"fdboost"`.
#' @param stability_args,interval_args,selectboost_args,plain_selectboost_args Named lists of
#'   arguments passed to the corresponding fitting functions.
#' @param fdboost_model Optional fitted `FDboost` object used when
#'   `methods` includes `"fdboost"`.
#' @param fdboost_args Additional arguments passed to
#'   [fdboost_stability_selection()].
#'
#' @returns An object of class `fda_method_comparison`.
#' @examples
#' sim <- simulate_fda_scenario(n = 24, grid_length = 16, seed = 1)
#' comparison <- compare_selection_methods(
#'   sim$design,
#'   methods = c("selectboost", "plain_selectboost"),
#'   selectboost_args = list(B = 3, steps.seq = 0.5, c0lim = FALSE),
#'   plain_selectboost_args = list(B = 3, steps.seq = 0.5, c0lim = FALSE)
#' )
#' summary(comparison)
#' @export
compare_selection_methods <- function(design,
                                      methods = c("stability", "interval", "selectboost"),
                                      stability_args = list(),
                                      interval_args = list(),
                                      selectboost_args = list(),
                                      plain_selectboost_args = list(),
                                      fdboost_model = NULL,
                                      fdboost_args = list()) {
  if (!inherits(design, "fda_design")) {
    stop("`design` must inherit from class `fda_design`.", call. = FALSE)
  }

  methods <- match.arg(
    methods,
    c("stability", "interval", "selectboost", "plain_selectboost", "fdboost"),
    several.ok = TRUE
  )
  fits <- list()

  if ("stability" %in% methods) {
    fits$stability <- do.call(
      fit_stability,
      c(list(design = design), stability_args)
    )
  }

  if ("interval" %in% methods) {
    interval_args <- interval_args %||% list()
    if (is.null(interval_args$width)) {
      interval_args$width <- default_interval_width(design)
    }
    if (is.null(interval_args$step)) {
      interval_args$step <- interval_args$width
    }
    fits$interval <- do.call(
      interval_stability_selection,
      c(list(x = design), interval_args)
    )
  }

  if ("selectboost" %in% methods) {
    selectboost_args <- selectboost_args %||% list()
    if (is.null(selectboost_args$mode)) {
      selectboost_args$mode <- "fast"
    }
    if (identical(selectboost_args$mode, "fast") && is.null(selectboost_args$steps.seq)) {
      selectboost_args$steps.seq <- suggest_c0_grid(design)
      selectboost_args$c0lim <- FALSE
    }
    fits$selectboost <- do.call(
      fit_selectboost,
      c(list(design = design), selectboost_args)
    )
  }

  if ("plain_selectboost" %in% methods) {
    plain_selectboost_args <- plain_selectboost_args %||% list()
    if (is.null(plain_selectboost_args$mode)) {
      plain_selectboost_args$mode <- "fast"
    }
    if (identical(plain_selectboost_args$mode, "fast") && is.null(plain_selectboost_args$steps.seq)) {
      plain_selectboost_args$steps.seq <- suggest_c0_grid(design)
      plain_selectboost_args$c0lim <- FALSE
    }
    fits$plain_selectboost <- do.call(
      plain_selectboost,
      c(list(x = design), plain_selectboost_args)
    )
  }

  if ("fdboost" %in% methods) {
    if (is.null(fdboost_model)) {
      stop("`fdboost_model` must be supplied when `methods` includes `\"fdboost\"`.", call. = FALSE)
    }
    fits$fdboost <- do.call(
      fdboost_stability_selection,
      c(list(model = fdboost_model), fdboost_args)
    )
  }

  summary_table <- rbind_fill_data_frames(Map(compare_fit_summary, fits, names(fits)))

  structure(
    list(
      design = design,
      fits = fits,
      summary_table = summary_table
    ),
    class = "fda_method_comparison"
  )
}

#' @export
print.fda_method_comparison <- function(x, ...) {
  cat("FDA method comparison\n")
  cat("  methods:", paste(names(x$fits), collapse = ", "), "\n")
  cat("  rows:", nrow(x$summary_table), "\n")
  invisible(x)
}

#' @export
summary.fda_method_comparison <- function(object, ...) {
  structure(
    list(
      methods = names(object$fits),
      summary_table = object$summary_table
    ),
    class = "summary.fda_method_comparison"
  )
}

#' @export
print.summary.fda_method_comparison <- function(x, ...) {
  cat("FDA method comparison summary\n")
  cat("  methods:", paste(x$methods, collapse = ", "), "\n")
  print(x$summary_table, row.names = FALSE)
  invisible(x)
}

#' @export
selection_map.fda_method_comparison <- function(x,
                                                level = c("feature", "group", "basis"),
                                                ...) {
  maps <- lapply(names(x$fits), function(method) {
    fit <- x$fits[[method]]
    if (inherits(fit, c("fda_stability_selection", "selectboost_fda_result"))) {
      out <- selection_map(fit, level = level, ...)
      out$method <- method
      return(out)
    }
    NULL
  })
  rbind_fill_data_frames(maps)
}

#' @export
selected.fda_method_comparison <- function(x, ...) {
  maps <- lapply(names(x$fits), function(method) {
    fit <- x$fits[[method]]
    if (inherits(fit, c("fda_stability_selection", "selectboost_fda_result"))) {
      out <- selected(fit, ...)
      out$method <- method
      return(out)
    }
    NULL
  })
  rbind_fill_data_frames(maps)
}

#' Build an FDA Design from a Formula
#'
#' Supports additive formulas of the form `y ~ signal + noise + age + batch`,
#' where functional terms are supplied as matrices, `fda_grid`, or `fda_basis`
#' objects in `data`, and scalar terms are expanded through
#' [stats::model.matrix()].
#'
#' @param formula An additive formula with a single response.
#' @param data A list or data frame containing the variables referenced in
#'   `formula`.
#' @param family,transforms,scalar_transform,preprocessor,center,scale Passed to
#'   [fda_design()].
#'
#' @returns An object of class `fda_design`.
#' @export
fda_design_formula <- function(formula,
                               data,
                               family = c("gaussian", "binomial"),
                               transforms = NULL,
                               scalar_transform = NULL,
                               preprocessor = NULL,
                               center = FALSE,
                               scale = FALSE) {
  if (!inherits(formula, "formula")) {
    stop("`formula` must inherit from class `formula`.", call. = FALSE)
  }
  if (!is.list(data) && !is.data.frame(data)) {
    stop("`data` must be a list or data frame.", call. = FALSE)
  }

  terms_obj <- stats::terms(formula)
  labels <- attr(terms_obj, "term.labels")
  if (length(labels) == 0L) {
    stop("The formula must contain at least one predictor term.", call. = FALSE)
  }
  if (any(grepl("[:*^()/]", labels)) || any(labels == ".")) {
    stop("Only additive formulas with named terms are supported.", call. = FALSE)
  }

  response_name <- all.vars(formula[[2L]])
  if (length(response_name) != 1L) {
    stop("The formula must have a single response variable.", call. = FALSE)
  }
  response <- data[[response_name]]
  if (is.null(response)) {
    stop(sprintf("Response `%s` was not found in `data`.", response_name), call. = FALSE)
  }

  functional_predictors <- list()
  scalar_terms <- list()

  for (label in labels) {
    value <- data[[label]]
    if (is.null(value)) {
      stop(sprintf("Predictor `%s` was not found in `data`.", label), call. = FALSE)
    }

    is_functional <- inherits(value, c("fda_grid", "fda_basis")) ||
      (is.matrix(value) && ncol(value) > 1L)

    if (is_functional) {
      functional_predictors[[label]] <- value
    } else if (inherits(value, "fda_scalar")) {
      scalar_terms[[label]] <- as.data.frame(value$values)
    } else {
      scalar_terms[[label]] <- value
    }
  }

  if (length(functional_predictors) == 0L) {
    stop("The formula interface requires at least one functional predictor.", call. = FALSE)
  }

  scalar_covariates <- if (length(scalar_terms) == 0L) {
    NULL
  } else {
    scalar_df <- as.data.frame(scalar_terms, stringsAsFactors = TRUE)
    stats::model.matrix(
      object = stats::as.formula(paste("~ 0 +", paste(names(scalar_df), collapse = " + "))),
      data = scalar_df
    )
  }

  fda_design(
    response = response,
    predictors = functional_predictors,
    scalar_covariates = scalar_covariates,
    family = match.arg(family),
    center = center,
    scale = scale,
    transforms = transforms,
    scalar_transform = scalar_transform,
    preprocessor = preprocessor
  )
}

#' Fit Stability Selection from a Formula
#'
#' @param formula,data,family,transforms,scalar_transform,preprocessor,center,scale
#'   Passed to [fda_design_formula()].
#' @param ... Additional arguments passed to [fit_stability()].
#'
#' @returns An object inheriting from `fda_stability_selection`.
#' @export
fit_stability_formula <- function(formula,
                                  data,
                                  family = c("gaussian", "binomial"),
                                  transforms = NULL,
                                  scalar_transform = NULL,
                                  preprocessor = NULL,
                                  center = FALSE,
                                  scale = FALSE,
                                  ...) {
  design <- fda_design_formula(
    formula = formula,
    data = data,
    family = family,
    transforms = transforms,
    scalar_transform = scalar_transform,
    preprocessor = preprocessor,
    center = center,
    scale = scale
  )
  fit_stability(design, ...)
}

#' Fit FDA-SelectBoost from a Formula
#'
#' @param formula,data,family,transforms,scalar_transform,preprocessor,center,scale
#'   Passed to [fda_design_formula()].
#' @param ... Additional arguments passed to [fit_selectboost()].
#'
#' @returns An object inheriting from `selectboost_fda_result`.
#' @export
fit_selectboost_formula <- function(formula,
                                    data,
                                    family = c("gaussian", "binomial"),
                                    transforms = NULL,
                                    scalar_transform = NULL,
                                    preprocessor = NULL,
                                    center = FALSE,
                                    scale = FALSE,
                                    ...) {
  design <- fda_design_formula(
    formula = formula,
    data = data,
    family = family,
    transforms = transforms,
    scalar_transform = scalar_transform,
    preprocessor = preprocessor,
    center = center,
    scale = scale
  )
  fit_selectboost(design, ...)
}
