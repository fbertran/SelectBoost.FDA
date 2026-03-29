feature_map_from_block <- function(feature_names,
                                   predictor,
                                   representation,
                                   position,
                                   argval = position,
                                   unit = NA_character_,
                                   basis_type = NA_character_,
                                   block = predictor,
                                   transform = "identity",
                                   source_predictor = predictor,
                                   source_representation = representation,
                                   source_position_start = position,
                                   source_position_end = position,
                                   source_argval_start = argval,
                                   source_argval_end = argval,
                                   domain_start = source_argval_start,
                                   domain_end = source_argval_end,
                                   component = if (identical(representation, "basis")) argval else NA_character_) {
  n_features <- length(feature_names)
  data.frame(
    feature = feature_names,
    predictor = predictor,
    block = block,
    position = as.integer(position),
    argval = as.character(argval),
    representation = representation,
    basis_type = basis_type,
    transform = rep(transform, n_features),
    source_predictor = rep(source_predictor, n_features),
    source_representation = rep(source_representation, n_features),
    source_position_start = as.integer(source_position_start),
    source_position_end = as.integer(source_position_end),
    source_argval_start = as.character(source_argval_start),
    source_argval_end = as.character(source_argval_end),
    domain_start = as.character(domain_start),
    domain_end = as.character(domain_end),
    component = as.character(component),
    unit = rep(unit %||% NA_character_, length(feature_names)),
    stringsAsFactors = FALSE
  )
}

clean_predictor_name <- function(x) {
  if (is.null(x) || length(x) == 0L || is.na(x) || !nzchar(x)) {
    return(NULL)
  }
  x
}

coerce_predictor_block <- function(x, predictor_name = NULL) {
  predictor_name <- clean_predictor_name(predictor_name)

  if (inherits(x, "fda_grid")) {
    predictor_name <- predictor_name %||% x$name %||% "grid"
    mat <- as.matrix(x$values)
    feature_names <- colnames(mat) %||% paste0(predictor_name, "_", seq_len(ncol(mat)))
    colnames(mat) <- feature_names
    return(list(
      matrix = mat,
      feature_map = feature_map_from_block(
        feature_names = feature_names,
        predictor = predictor_name,
        representation = "grid",
        position = seq_len(ncol(mat)),
        argval = x$argvals,
        unit = x$unit,
        transform = "identity",
        source_representation = "grid"
      )
    ))
  }

  if (inherits(x, "fda_basis")) {
    predictor_name <- predictor_name %||% x$name %||% "basis"
    mat <- as.matrix(x$coefficients)
    feature_names <- colnames(mat) %||% x$component_names %||% paste0(predictor_name, "_", seq_len(ncol(mat)))
    colnames(mat) <- feature_names
    return(list(
      matrix = mat,
      feature_map = feature_map_from_block(
        feature_names = feature_names,
        predictor = predictor_name,
        representation = "basis",
        position = seq_len(ncol(mat)),
        argval = x$argvals %||% seq_len(ncol(mat)),
        unit = x$unit,
        basis_type = x$basis_type,
        transform = "identity",
        source_representation = "basis",
        component = x$component_names %||% x$argvals %||% seq_len(ncol(mat))
      )
    ))
  }

  if (inherits(x, "fda_scalar")) {
    predictor_name <- predictor_name %||% x$name %||% "scalar"
    mat <- as.matrix(x$values)
    feature_names <- colnames(mat) %||% paste0(predictor_name, "_", seq_len(ncol(mat)))
    colnames(mat) <- feature_names
    return(list(
      matrix = mat,
      feature_map = feature_map_from_block(
        feature_names = feature_names,
        predictor = predictor_name,
        representation = "scalar",
        position = seq_len(ncol(mat)),
        argval = feature_names,
        unit = x$unit,
        transform = "identity",
        source_representation = "scalar"
      )
    ))
  }

  predictor_name <- predictor_name %||% "block1"
  if (is.vector(x) && !is.list(x)) {
    x <- matrix(x, ncol = 1L)
  } else {
    x <- as.matrix(x)
  }

  storage.mode(x) <- "double"
  feature_names <- colnames(x) %||% paste0(predictor_name, "_", seq_len(ncol(x)))
  colnames(x) <- feature_names

  list(
    matrix = x,
    feature_map = feature_map_from_block(
      feature_names = feature_names,
      predictor = predictor_name,
      representation = "matrix",
      position = seq_len(ncol(x)),
      argval = seq_len(ncol(x)),
      transform = "identity",
      source_representation = "matrix"
    )
  )
}

assemble_functional_matrix <- function(blocks, center = FALSE, scale = FALSE) {
  if (!is.list(blocks) || length(blocks) == 0L) {
    stop("`blocks` must be a non-empty list.", call. = FALSE)
  }

  block_names <- names(blocks)
  if (is.null(block_names)) {
    block_names <- rep.int(NA_character_, length(blocks))
  }
  coerced <- vector("list", length(blocks))
  n_obs <- NULL

  for (i in seq_along(blocks)) {
    coerced[[i]] <- coerce_predictor_block(
      blocks[[i]],
      predictor_name = block_names[i]
    )

    if (is.null(n_obs)) {
      n_obs <- nrow(coerced[[i]]$matrix)
    } else if (nrow(coerced[[i]]$matrix) != n_obs) {
      stop("All functional predictors must have the same number of rows.", call. = FALSE)
    }
  }

  mat <- do.call(cbind, lapply(coerced, `[[`, "matrix"))
  if (isTRUE(center) || isTRUE(scale)) {
    mat <- base::scale(mat, center = center, scale = scale)
  }

  feature_map <- do.call(rbind, lapply(coerced, `[[`, "feature_map"))
  feature_map$feature_index <- seq_len(nrow(feature_map))
  colnames(mat) <- feature_map$feature

  result <- list(
    x = mat,
    blocks = feature_map$block,
    positions = feature_map$position,
    feature_map = feature_map
  )
  class(result) <- "fda_matrix"
  result
}

resolve_fit_input <- function(x, y = NULL, family = NULL) {
  if (inherits(x, "fda_design")) {
    if (!is.null(y)) {
      stop("Do not supply `y` when `x` is an `fda_design` object.", call. = FALSE)
    }
    if (!is.null(family) && !identical(family, x$family)) {
      stop("`family` must match the family stored in `x`.", call. = FALSE)
    }
    if (is.null(x$response)) {
      stop("`x` does not contain a response. Build the design with `response = ...` before fitting.", call. = FALSE)
    }

    y <- validate_xy(x$matrix, x$response, family = x$family)
    return(list(
      x = x$matrix,
      y = y,
      family = x$family,
      design = x
    ))
  }

  if (is.null(y)) {
    stop("`y` must be supplied unless `x` is an `fda_design` object.", call. = FALSE)
  }

  resolved_family <- if (is.null(family)) {
    "gaussian"
  } else {
    match.arg(family, c("gaussian", "binomial"))
  }

  fda_x <- as_functional_matrix(x)
  y <- validate_xy(fda_x, y, family = resolved_family)

  list(
    x = fda_x,
    y = y,
    family = resolved_family,
    design = NULL
  )
}

#' Functional Predictor on a Common Grid
#'
#' Constructor for one discretized functional predictor sampled on a common
#' grid.
#'
#' @param values Numeric matrix with one row per observation.
#' @param argvals Optional vector of grid values. Defaults to
#'   `seq_len(ncol(values))`.
#' @param name Optional predictor name.
#' @param unit Optional unit for the grid axis.
#'
#' @returns An object of class `fda_grid`.
#' @export
fda_grid <- function(values, argvals = NULL, name = NULL, unit = NULL) {
  values <- as.matrix(values)
  storage.mode(values) <- "double"

  if (is.null(argvals)) {
    argvals <- seq_len(ncol(values))
  }
  if (length(argvals) != ncol(values)) {
    stop("`argvals` must have one entry per column in `values`.", call. = FALSE)
  }

  result <- list(
    values = values,
    argvals = argvals,
    name = name %||% "grid",
    unit = unit
  )
  class(result) <- c("fda_grid", "fda_predictor")
  result
}

#' @export
print.fda_grid <- function(x, ...) {
  cat("FDA grid predictor\n")
  cat("  name:", x$name, "\n")
  cat("  observations:", nrow(x$values), "\n")
  cat("  grid points:", ncol(x$values), "\n")
  invisible(x)
}

#' Basis-Expanded Functional Predictor
#'
#' Constructor for a functional predictor represented by basis coefficients or
#' FPCA scores.
#'
#' @param coefficients Numeric matrix with one row per observation.
#' @param basis_type Label describing the representation.
#' @param argvals Optional labels or positions for basis functions/components.
#' @param component_names Optional names for coefficient columns.
#' @param name Optional predictor name.
#' @param unit Optional unit for the basis domain.
#'
#' @returns An object of class `fda_basis`.
#' @export
fda_basis <- function(coefficients,
                      basis_type = c("generic", "spline", "wavelet", "fpca"),
                      argvals = NULL,
                      component_names = NULL,
                      name = NULL,
                      unit = NULL) {
  coefficients <- as.matrix(coefficients)
  storage.mode(coefficients) <- "double"
  basis_type <- match.arg(basis_type)

  if (is.null(argvals)) {
    argvals <- seq_len(ncol(coefficients))
  }
  if (length(argvals) != ncol(coefficients)) {
    stop("`argvals` must have one entry per coefficient column.", call. = FALSE)
  }
  if (!is.null(component_names) && length(component_names) != ncol(coefficients)) {
    stop("`component_names` must have one entry per coefficient column.", call. = FALSE)
  }

  result <- list(
    coefficients = coefficients,
    basis_type = basis_type,
    argvals = argvals,
    component_names = component_names,
    name = name %||% "basis",
    unit = unit
  )
  class(result) <- c("fda_basis", "fda_predictor")
  result
}

#' @export
print.fda_basis <- function(x, ...) {
  cat("FDA basis predictor\n")
  cat("  name:", x$name, "\n")
  cat("  representation:", x$basis_type, "\n")
  cat("  observations:", nrow(x$coefficients), "\n")
  cat("  coefficients:", ncol(x$coefficients), "\n")
  invisible(x)
}

#' Functional Design Object
#'
#' Bundles the response, functional predictors, family, and a reversible feature
#' map. This is the FDA-native entry point for the higher-level fitting
#' functions.
#'
#' @param response Response vector.
#' @param predictors A single predictor or a named list of predictors. Elements
#'   can be `fda_grid`, `fda_basis`, `fda_scalar`, matrices, data frames, or
#'   numeric vectors.
#' @param scalar_covariates Optional scalar covariates supplied separately from
#'   the functional predictors.
#' @param family Model family.
#' @param id Optional observation identifiers.
#' @param center,scale Backward-compatible shortcuts for applying an identity
#'   transform with centering and scaling to the functional predictors.
#' @param transforms Optional preprocessing specs for the functional predictors.
#' @param scalar_transform Optional preprocessing specs for scalar covariates.
#' @param preprocessor Optional fitted `fda_preprocessor`. When supplied, it is
#'   reused instead of fitting preprocessing from the current data.
#'
#' @returns An object of class `fda_design`.
#' @export
fda_design <- function(response = NULL,
                       predictors,
                       scalar_covariates = NULL,
                       family = c("gaussian", "binomial"),
                       id = NULL,
                       center = FALSE,
                       scale = FALSE,
                       transforms = NULL,
                       scalar_transform = NULL,
                       preprocessor = NULL) {
  family <- match.arg(family)
  predictors <- normalize_predictor_collection(predictors)
  scalar_covariates <- normalize_scalar_collection(scalar_covariates)

  if (!is.null(preprocessor)) {
    if (!inherits(preprocessor, "fda_preprocessor")) {
      stop("`preprocessor` must inherit from class `fda_preprocessor`.", call. = FALSE)
    }
    if (!is.null(transforms) || !is.null(scalar_transform) || isTRUE(center) || isTRUE(scale)) {
      stop("When `preprocessor` is supplied, do not also pass `transforms`, `scalar_transform`, `center`, or `scale`.", call. = FALSE)
    }
  } else {
    transform_specs <- normalize_spec_map(
      specs = transforms,
      expected_names = names(predictors),
      default_spec = fda_identity(center = center, scale = scale)
    )
    scalar_specs <- normalize_spec_map(
      specs = scalar_transform,
      expected_names = names(scalar_covariates),
      default_spec = fda_identity()
    )
    preprocessor <- fit_fda_preprocessor(
      predictors = predictors,
      scalar_covariates = scalar_covariates,
      transforms = transform_specs,
      scalar_transform = scalar_specs
    )
  }

  fda_x <- apply_fda_preprocessor(
    object = preprocessor,
    predictors = predictors,
    scalar_covariates = scalar_covariates
  )
  if (!is.null(response)) {
    response <- validate_xy(fda_x, response, family = family)
  }

  if (is.null(id)) {
    id <- seq_len(nrow(fda_x$x))
  }
  if (length(id) != nrow(fda_x$x)) {
    stop("`id` must have one entry per observation.", call. = FALSE)
  }

  result <- list(
    response = response,
    predictors = predictors,
    scalar_covariates = scalar_covariates,
    family = family,
    id = id,
    matrix = fda_x,
    feature_map = fda_x$feature_map,
    preprocessor = preprocessor
  )
  class(result) <- "fda_design"
  result
}

#' @export
print.fda_design <- function(x, ...) {
  cat("FDA design\n")
  cat("  observations:", nrow(x$matrix$x), "\n")
  cat("  features:", ncol(x$matrix$x), "\n")
  cat("  functional predictors:", length(x$predictors), "\n")
  cat("  scalar covariates:", length(x$scalar_covariates %||% list()), "\n")
  cat("  family:", x$family, "\n")
  cat("  response available:", !is.null(x$response), "\n")
  invisible(x)
}

#' @export
summary.fda_design <- function(object, ...) {
  predictor_counts <- stats::aggregate(
    feature ~ predictor + representation,
    data = object$feature_map,
    FUN = length
  )
  names(predictor_counts)[names(predictor_counts) == "feature"] <- "n_features"

  result <- list(
    n_observations = nrow(object$matrix$x),
    n_features = ncol(object$matrix$x),
    family = object$family,
    has_response = !is.null(object$response),
    n_functional_predictors = length(object$predictors),
    n_scalar_covariates = length(object$scalar_covariates %||% list()),
    predictors = predictor_counts
  )
  class(result) <- "summary.fda_design"
  result
}

#' @export
print.summary.fda_design <- function(x, ...) {
  cat("FDA design summary\n")
  cat("  observations:", x$n_observations, "\n")
  cat("  features:", x$n_features, "\n")
  cat("  family:", x$family, "\n")
  cat("  response available:", x$has_response, "\n")
  cat("  functional predictors:", x$n_functional_predictors, "\n")
  cat("  scalar covariates:", x$n_scalar_covariates, "\n")
  print(x$predictors, row.names = FALSE)
  invisible(x)
}

#' Fit Grouped Stability Selection from an FDA Design
#'
#' @param design An `fda_design` object.
#' @param ... Additional arguments forwarded to `stability_selection_fda()`.
#'
#' @returns An object inheriting from `fda_stability_selection`.
#' @export
fit_stability <- function(design, ...) {
  if (!inherits(design, "fda_design")) {
    stop("`design` must inherit from class `fda_design`.", call. = FALSE)
  }

  result <- stability_selection_fda(x = design, ...)
  result$design <- design
  class(result) <- c("fda_selection_fit", "fda_stability_fit", class(result))
  result
}

#' Fit SelectBoost from an FDA Design
#'
#' @param design An `fda_design` object.
#' @param ... Additional arguments forwarded to `selectboost_fda()`.
#'
#' @returns An object inheriting from `selectboost_fda_result`.
#' @export
fit_selectboost <- function(design, ...) {
  if (!inherits(design, "fda_design")) {
    stop("`design` must inherit from class `fda_design`.", call. = FALSE)
  }

  result <- selectboost_fda(x = design, ...)
  result$design <- design
  class(result) <- c("fda_selection_fit", "fda_selectboost_fit", class(result))
  result
}

decorate_selection_feature_map <- function(map) {
  map$basis_component <- ifelse(
    map$representation == "basis",
    ifelse(
      is.na(map$component) | !nzchar(map$component),
      ifelse(is.na(map$argval) | !nzchar(map$argval), map$feature, map$argval),
      map$component
    ),
    NA_character_
  )
  same_domain <- is.na(map$domain_start) | is.na(map$domain_end) | map$domain_start == map$domain_end
  raw_label <- ifelse(same_domain, map$argval, paste0(map$domain_start, " - ", map$domain_end))
  map$domain_label <- ifelse(
    is.na(map$unit) | !nzchar(map$unit),
    raw_label,
    paste0(raw_label, " ", map$unit)
  )
  map
}

attach_group_metadata <- function(map,
                                  groups = NULL,
                                  group_frequency = NULL,
                                  cutoff = NULL,
                                  interval_table = NULL,
                                  selected_groups = NULL) {
  if (is.null(groups)) {
    return(map)
  }

  map$group_id <- unname(groups[map$feature_index])
  map$group <- group_names(groups)[map$group_id]

  if (!is.null(group_frequency)) {
    map$group_frequency <- unname(group_frequency[map$group])
  }

  if (!is.null(cutoff) && "group_frequency" %in% names(map)) {
    map$group_selected <- map$group_frequency >= cutoff
  } else if (!is.null(selected_groups)) {
    map$group_selected <- map$group %in% selected_groups
  }

  if (!is.null(interval_table)) {
    idx <- match(map$group_id, interval_table$group)
    map$interval_start <- interval_table$start[idx]
    map$interval_end <- interval_table$end[idx]
    map$interval_label <- interval_table$label[idx]
  }

  map
}

summarise_selection_map <- function(map, level = c("feature", "group", "basis")) {
  level <- match.arg(level)

  if (identical(level, "feature")) {
    return(map)
  }

  if (identical(level, "group")) {
    if (!"group_id" %in% names(map)) {
      map$group_id <- map$block
      map$group <- map$predictor
    }

    split_keys <- if ("c0" %in% names(map)) {
      interaction(map$c0, map$group_id, drop = TRUE, lex.order = TRUE)
    } else {
      interaction(map$group_id, drop = TRUE, lex.order = TRUE)
    }

    return(do.call(rbind, lapply(split(seq_len(nrow(map)), split_keys), function(idx) {
      rows <- map[idx, , drop = FALSE]
      rows <- rows[order(rows$position), , drop = FALSE]

      out <- data.frame(
        predictor = paste(unique(rows$predictor), collapse = ", "),
        group_id = rows$group_id[1],
        group = rows$group[1],
        representation = paste(unique(rows$representation), collapse = ", "),
        basis_type = paste(unique(stats::na.omit(rows$basis_type)), collapse = ", "),
        source_representation = paste(unique(rows$source_representation), collapse = ", "),
        n_features = nrow(rows),
        start_position = min(rows$position),
        end_position = max(rows$position),
        start_argval = rows$argval[1],
        end_argval = rows$argval[nrow(rows)],
        domain_start = rows$domain_start[1],
        domain_end = rows$domain_end[nrow(rows)],
        stringsAsFactors = FALSE
      )

      if ("c0" %in% names(rows)) {
        out$c0 <- rows$c0[1]
      }
      if ("feature_frequency" %in% names(rows)) {
        out$mean_feature_frequency <- mean(rows$feature_frequency)
        out$max_feature_frequency <- max(rows$feature_frequency)
      }
      if ("selected" %in% names(rows)) {
        out$selected_features <- sum(rows$selected)
      }
      if ("group_frequency" %in% names(rows)) {
        out$group_frequency <- rows$group_frequency[1]
      }
      if ("group_selected" %in% names(rows)) {
        out$group_selected <- rows$group_selected[1]
      }
      if ("selection" %in% names(rows)) {
        out$mean_selection <- mean(rows$selection)
        out$max_selection <- max(rows$selection)
        out$selected_features <- sum(rows$selection > 0)
      }
      if ("interval_start" %in% names(rows)) {
        out$interval_start <- rows$interval_start[1]
        out$interval_end <- rows$interval_end[1]
        out$interval_label <- rows$interval_label[1]
      }

      out
    })))
  }

  rows <- map[map$representation == "basis", , drop = FALSE]
  if (nrow(rows) == 0L) {
    return(rows[0, intersect(c(
      "predictor", "representation", "basis_type", "c0"
    ), names(rows)), drop = FALSE])
  }

  split_keys <- if ("c0" %in% names(rows)) {
    interaction(rows$c0, rows$predictor, rows$basis_type, drop = TRUE, lex.order = TRUE)
  } else {
    interaction(rows$predictor, rows$basis_type, drop = TRUE, lex.order = TRUE)
  }

  do.call(rbind, lapply(split(seq_len(nrow(rows)), split_keys), function(idx) {
    part <- rows[idx, , drop = FALSE]
    part <- part[order(part$position), , drop = FALSE]

    out <- data.frame(
      predictor = part$predictor[1],
      representation = "basis",
      basis_type = part$basis_type[1],
      source_representation = paste(unique(part$source_representation), collapse = ", "),
      n_components = nrow(part),
      first_component = part$basis_component[1],
      last_component = part$basis_component[nrow(part)],
      components = paste(part$basis_component, collapse = ", "),
      domain_start = part$domain_start[1],
      domain_end = part$domain_end[nrow(part)],
      stringsAsFactors = FALSE
    )

    if ("c0" %in% names(part)) {
      out$c0 <- part$c0[1]
    }
    if ("feature_frequency" %in% names(part)) {
      out$mean_feature_frequency <- mean(part$feature_frequency)
      out$max_feature_frequency <- max(part$feature_frequency)
    }
    if ("selected" %in% names(part)) {
      out$selected_components <- sum(part$selected)
    }
    if ("selection" %in% names(part)) {
      out$mean_selection <- mean(part$selection)
      out$max_selection <- max(part$selection)
      out$selected_components <- sum(part$selection > 0)
    }

    out
  }))
}

#' Feature-Level Selection Map
#'
#' Returns a feature map augmented with selection summaries from a fit object.
#'
#' @param x An `fda_design`, `fda_stability_selection`, or
#'   `selectboost_fda_result` object.
#' @param level Summary level. `"feature"` returns one row per coefficient,
#'   `"group"` returns one row per stability/interval group, and `"basis"`
#'   returns one row per basis-expanded predictor.
#' @param ... Additional arguments passed to the relevant method.
#'
#' @returns A data frame.
#' @export
selection_map <- function(x, level = c("feature", "group", "basis"), ...) {
  UseMethod("selection_map")
}

#' @export
selection_map.fda_design <- function(x, level = c("feature", "group", "basis"), ...) {
  map <- decorate_selection_feature_map(x$feature_map)
  summarise_selection_map(map, level = match.arg(level))
}

#' @export
selection_map.fda_stability_selection <- function(x,
                                                  level = c("feature", "group", "basis"),
                                                  cutoff = x$cutoff,
                                                  ...) {
  map <- decorate_selection_feature_map(x$x$feature_map)
  map$feature_frequency <- unname(x$feature_frequency[map$feature])
  map$selected <- map$feature_frequency >= cutoff
  map <- attach_group_metadata(
    map = map,
    groups = x$groups,
    group_frequency = x$group_frequency,
    cutoff = cutoff,
    interval_table = x$interval_table %||% NULL,
    selected_groups = x$selected_groups
  )
  summarise_selection_map(map, level = match.arg(level))
}

#' @export
selection_map.selectboost_fda_result <- function(x,
                                                 level = c("feature", "group", "basis"),
                                                 c0 = NULL,
                                                 ...) {
  feature_map <- decorate_selection_feature_map(x$x$feature_map)
  selection <- x$feature_selection

  if (!is.null(c0)) {
    if (!c0 %in% colnames(selection)) {
      stop("`c0` must match one of the SelectBoost columns.", call. = FALSE)
    }
    feature_map$selection <- selection[, c0]
    feature_map$c0 <- c0
    feature_map <- attach_group_metadata(map = feature_map, groups = x$groups)
    return(summarise_selection_map(feature_map, level = match.arg(level)))
  }

  output <- feature_map[rep(seq_len(nrow(feature_map)), times = ncol(selection)), , drop = FALSE]
  output$c0 <- rep(colnames(selection), each = nrow(feature_map))
  output$selection <- as.vector(selection)
  output <- attach_group_metadata(map = output, groups = x$groups)
  summarise_selection_map(output, level = match.arg(level))
}

selection_fit_metadata <- function(object) {
  list(
    family = object$family,
    n_features = ncol(object$x$x),
    n_groups = length(unique(object$groups)),
    n_predictors = length(unique(object$x$feature_map$predictor))
  )
}

#' Extract Selected Features or Groups
#'
#' Returns the selected rows from [selection_map()] for stability-selection or
#' SelectBoost fits.
#'
#' @param x A fitted selection object.
#' @param ... Additional arguments passed to the relevant method.
#'
#' @returns A data frame.
#' @export
selected <- function(x, ...) {
  UseMethod("selected")
}

#' @export
selected.fda_stability_selection <- function(x,
                                             level = c("feature", "group", "basis"),
                                             cutoff = x$cutoff,
                                             ...) {
  level <- match.arg(level)
  map <- selection_map(x, level = level, cutoff = cutoff, ...)
  keep <- if (identical(level, "feature")) {
    map$selected
  } else if (identical(level, "group")) {
    map$group_selected
  } else {
    map$selected_components > 0
  }
  map[keep %in% TRUE, , drop = FALSE]
}

#' @export
selected.selectboost_fda_result <- function(x,
                                            level = c("feature", "group", "basis"),
                                            c0 = NULL,
                                            threshold = 0,
                                            value = c("max", "mean"),
                                            ...) {
  level <- match.arg(level)
  value <- match.arg(value)
  map <- selection_map(x, level = level, c0 = c0, ...)
  keep <- if (identical(level, "feature")) {
    map$selection > threshold
  } else if (identical(level, "group")) {
    metric <- if (identical(value, "mean")) map$mean_selection else map$max_selection
    metric > threshold
  } else {
    metric <- if (identical(value, "mean")) map$mean_selection else map$max_selection
    metric > threshold
  }
  map[keep %in% TRUE, , drop = FALSE]
}

#' @export
summary.fda_stability_selection <- function(object, ...) {
  meta <- selection_fit_metadata(object)
  result <- list(
    method = "stability_selection",
    family = meta$family,
    n_features = meta$n_features,
    n_groups = meta$n_groups,
    n_predictors = meta$n_predictors,
    B = object$B,
    sample_fraction = object$sample_fraction,
    cutoff = object$cutoff,
    n_selected_features = length(object$selected_features),
    n_selected_groups = length(object$selected_groups),
    top_features = utils::head(sort(object$feature_frequency, decreasing = TRUE), 10L),
    top_groups = utils::head(sort(object$group_frequency, decreasing = TRUE), 10L)
  )
  class(result) <- "summary.fda_stability_selection"
  result
}

#' @export
print.summary.fda_stability_selection <- function(x, ...) {
  cat("FDA stability selection summary\n")
  cat("  family:", x$family, "\n")
  cat("  predictors:", x$n_predictors, "\n")
  cat("  features:", x$n_features, "\n")
  cat("  groups:", x$n_groups, "\n")
  cat("  replicates:", x$B, "\n")
  cat("  sample fraction:", x$sample_fraction, "\n")
  cat("  cutoff:", x$cutoff, "\n")
  cat("  selected features:", x$n_selected_features, "\n")
  cat("  selected groups:", x$n_selected_groups, "\n")
  invisible(x)
}

#' @export
summary.selectboost_fda_result <- function(object, ...) {
  counts <- colSums(object$feature_selection > 0)
  meta <- selection_fit_metadata(object)
  result <- list(
    method = "selectboost",
    family = meta$family,
    n_features = meta$n_features,
    n_groups = meta$n_groups,
    n_predictors = meta$n_predictors,
    mode = object$mode,
    n_c0 = ncol(object$feature_selection),
    selected_by_c0 = counts
  )
  class(result) <- "summary.selectboost_fda_result"
  result
}

#' @export
print.summary.selectboost_fda_result <- function(x, ...) {
  cat("FDA SelectBoost summary\n")
  cat("  family:", x$family, "\n")
  cat("  predictors:", x$n_predictors, "\n")
  cat("  mode:", x$mode, "\n")
  cat("  features:", x$n_features, "\n")
  cat("  groups:", x$n_groups, "\n")
  cat("  c0 values:", x$n_c0, "\n")
  invisible(x)
}
