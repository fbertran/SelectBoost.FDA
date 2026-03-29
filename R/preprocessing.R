normalize_predictor_collection <- function(predictors, default_prefix = "predictor") {
  if (inherits(predictors, c("fda_grid", "fda_basis", "fda_scalar", "matrix", "data.frame", "fda_matrix")) ||
      (is.vector(predictors) && !is.list(predictors))) {
    predictors <- list(predictor1 = predictors)
  }

  if (!is.list(predictors) || length(predictors) == 0L) {
    stop("`predictors` must be a predictor object or a non-empty list of predictors.", call. = FALSE)
  }

  predictor_names <- names(predictors)
  if (is.null(predictor_names)) {
    predictor_names <- paste0(default_prefix, seq_along(predictors))
  }
  missing_names <- is.na(predictor_names) | !nzchar(predictor_names)
  predictor_names[missing_names] <- paste0(default_prefix, which(missing_names))
  names(predictors) <- predictor_names
  predictors
}

normalize_scalar_collection <- function(scalar_covariates) {
  if (is.null(scalar_covariates)) {
    return(list())
  }

  if (inherits(scalar_covariates, "fda_scalar")) {
    name <- scalar_covariates$name %||% "scalar1"
    return(stats::setNames(list(scalar_covariates), name))
  }

  if (is.data.frame(scalar_covariates) || is.matrix(scalar_covariates)) {
    values <- as.matrix(scalar_covariates)
    storage.mode(values) <- "double"
    scalar_names <- colnames(values) %||% paste0("scalar", seq_len(ncol(values)))
    return(stats::setNames(lapply(seq_len(ncol(values)), function(j) {
      fda_scalar(values[, j], name = scalar_names[j])
    }), scalar_names))
  }

  if (is.vector(scalar_covariates) && !is.list(scalar_covariates)) {
    return(list(scalar1 = fda_scalar(scalar_covariates, name = "scalar1")))
  }

  if (is.list(scalar_covariates) && length(scalar_covariates) == 0L) {
    return(list())
  }

  if (!is.list(scalar_covariates) || length(scalar_covariates) == 0L) {
    stop("`scalar_covariates` must be NULL, a vector, a matrix/data frame, or a list.", call. = FALSE)
  }

  scalar_names <- names(scalar_covariates)
  if (is.null(scalar_names)) {
    scalar_names <- paste0("scalar", seq_along(scalar_covariates))
  }
  missing_names <- is.na(scalar_names) | !nzchar(scalar_names)
  scalar_names[missing_names] <- paste0("scalar", which(missing_names))

  output <- vector("list", length(scalar_covariates))
  for (i in seq_along(scalar_covariates)) {
    current <- scalar_covariates[[i]]
    output[[i]] <- if (inherits(current, "fda_scalar")) {
      current
    } else {
      fda_scalar(current, name = scalar_names[i])
    }
  }
  names(output) <- scalar_names
  output
}

is_preprocess_spec <- function(x) {
  inherits(x, "fda_preprocess_spec")
}

normalize_spec_map <- function(specs, expected_names, default_spec) {
  if (length(expected_names) == 0L) {
    return(list())
  }

  if (is.null(specs)) {
    specs <- rep(list(default_spec), length(expected_names))
    names(specs) <- expected_names
    return(specs)
  }

  if (is_preprocess_spec(specs)) {
    specs <- rep(list(specs), length(expected_names))
    names(specs) <- expected_names
    return(specs)
  }

  if (!is.list(specs) || length(specs) == 0L) {
    stop("`transforms` must be NULL, a preprocessing spec, or a named list of specs.", call. = FALSE)
  }

  spec_names <- names(specs)
  if (is.null(spec_names)) {
    if (length(specs) != length(expected_names)) {
      stop("Unnamed preprocessing spec lists must have the same length as the predictor list.", call. = FALSE)
    }
    names(specs) <- expected_names
    return(specs)
  }

  unknown <- setdiff(spec_names, expected_names)
  if (length(unknown) > 0L) {
    stop(sprintf(
      "Unknown preprocessing specs supplied for: %s.",
      paste(unknown, collapse = ", ")
    ), call. = FALSE)
  }

  output <- rep(list(default_spec), length(expected_names))
  names(output) <- expected_names
  for (name in spec_names) {
    output[[name]] <- specs[[name]]
  }
  output
}

compute_scaling_parameters <- function(x, center = FALSE, scale = FALSE) {
  center_values <- if (isTRUE(center)) {
    colMeans(x)
  } else {
    rep(0, ncol(x))
  }
  scale_values <- if (isTRUE(scale)) {
    apply(x, 2L, stats::sd)
  } else {
    rep(1, ncol(x))
  }
  scale_values[!is.finite(scale_values) | scale_values == 0] <- 1

  list(
    center = center_values,
    scale = scale_values,
    center_flag = isTRUE(center),
    scale_flag = isTRUE(scale)
  )
}

apply_scaling_parameters <- function(x, params) {
  output <- x
  if (isTRUE(params$center_flag)) {
    output <- sweep(output, 2L, params$center, FUN = "-")
  }
  if (isTRUE(params$scale_flag)) {
    output <- sweep(output, 2L, params$scale, FUN = "/")
  }
  storage.mode(output) <- "double"
  output
}

as_grid_like <- function(x, predictor_name) {
  if (inherits(x, "fda_grid")) {
    return(list(
      values = as.matrix(x$values),
      argvals = x$argvals,
      unit = x$unit,
      name = predictor_name %||% x$name %||% "grid",
      source_representation = "grid"
    ))
  }

  if (inherits(x, "fda_basis")) {
    return(NULL)
  }

  if (inherits(x, "fda_scalar")) {
    return(NULL)
  }

  if (is.vector(x) && !is.list(x)) {
    x <- matrix(x, ncol = 1L)
  } else {
    x <- as.matrix(x)
  }
  storage.mode(x) <- "double"

  list(
    values = x,
    argvals = colnames(x) %||% seq_len(ncol(x)),
    unit = NA_character_,
    name = predictor_name %||% "grid",
    source_representation = "matrix"
  )
}

as_basis_like <- function(x, predictor_name) {
  if (!inherits(x, "fda_basis")) {
    return(NULL)
  }

  list(
    coefficients = as.matrix(x$coefficients),
    argvals = x$argvals %||% seq_len(ncol(x$coefficients)),
    component_names = x$component_names %||% paste0("component", seq_len(ncol(x$coefficients))),
    unit = x$unit,
    basis_type = x$basis_type,
    name = predictor_name %||% x$name %||% "basis",
    source_representation = "basis"
  )
}

coerce_numeric_argvals <- function(argvals, predictor_name, method) {
  numeric_argvals <- suppressWarnings(as.numeric(argvals))
  if (anyNA(numeric_argvals)) {
    stop(sprintf(
      "Predictor `%s` must have numeric `argvals` for `%s` preprocessing.",
      predictor_name,
      method
    ), call. = FALSE)
  }
  numeric_argvals
}

basis_support_from_matrix <- function(basis_matrix, argvals, tol = 1e-12) {
  start_idx <- integer(ncol(basis_matrix))
  end_idx <- integer(ncol(basis_matrix))
  start_argval <- character(ncol(basis_matrix))
  end_argval <- character(ncol(basis_matrix))

  for (j in seq_len(ncol(basis_matrix))) {
    active <- which(abs(basis_matrix[, j]) > tol)
    if (length(active) == 0L) {
      active <- seq_len(nrow(basis_matrix))
    }
    start_idx[j] <- min(active)
    end_idx[j] <- max(active)
    start_argval[j] <- as.character(argvals[start_idx[j]])
    end_argval[j] <- as.character(argvals[end_idx[j]])
  }

  list(
    start_idx = start_idx,
    end_idx = end_idx,
    start_argval = start_argval,
    end_argval = end_argval
  )
}

fit_identity_transform <- function(x, predictor_name, spec) {
  scalar_input <- inherits(x, "fda_scalar")
  basis_input <- as_basis_like(x, predictor_name)
  grid_input <- as_grid_like(x, predictor_name)

  if (scalar_input) {
    values <- as.matrix(x$values)
    storage.mode(values) <- "double"
    feature_names <- colnames(values) %||% predictor_name
    colnames(values) <- feature_names
    scaling <- compute_scaling_parameters(values, center = spec$center, scale = spec$scale)
    transformed <- apply_scaling_parameters(values, scaling)
    return(list(
      name = predictor_name,
      method = spec$method,
      representation = "scalar",
      basis_type = NA_character_,
      feature_names = feature_names,
      transform = spec$method,
      unit = x$unit,
      params = scaling,
      apply = function(new_x) {
        new_values <- as.matrix(if (inherits(new_x, "fda_scalar")) new_x$values else new_x)
        storage.mode(new_values) <- "double"
        if (ncol(new_values) != length(feature_names)) {
          stop(sprintf("Scalar covariate `%s` must keep the same number of columns.", predictor_name), call. = FALSE)
        }
        colnames(new_values) <- feature_names
        apply_scaling_parameters(new_values, scaling)
      },
      feature_map = feature_map_from_block(
        feature_names = feature_names,
        predictor = predictor_name,
        representation = "scalar",
        position = seq_len(length(feature_names)),
        argval = feature_names,
        unit = x$unit,
        transform = spec$method,
        source_representation = "scalar"
      ),
      transformed = transformed
    ))
  }

  if (!is.null(basis_input)) {
    values <- basis_input$coefficients
    feature_names <- colnames(values) %||% basis_input$component_names
    colnames(values) <- feature_names
    scaling <- compute_scaling_parameters(values, center = spec$center, scale = spec$scale)
    transformed <- apply_scaling_parameters(values, scaling)
    return(list(
      name = predictor_name,
      method = spec$method,
      representation = "basis",
      basis_type = basis_input$basis_type,
      feature_names = feature_names,
      transform = spec$method,
      unit = basis_input$unit,
      argvals = basis_input$argvals,
      params = scaling,
      apply = function(new_x) {
        new_basis <- as_basis_like(new_x, predictor_name)
        if (is.null(new_basis)) {
          stop(sprintf("Predictor `%s` must be supplied as `fda_basis` for this preprocessor.", predictor_name), call. = FALSE)
        }
        values_new <- new_basis$coefficients
        if (ncol(values_new) != length(feature_names)) {
          stop(sprintf("Basis predictor `%s` must keep the same number of coefficients.", predictor_name), call. = FALSE)
        }
        colnames(values_new) <- feature_names
        apply_scaling_parameters(values_new, scaling)
      },
      feature_map = feature_map_from_block(
        feature_names = feature_names,
        predictor = predictor_name,
        representation = "basis",
        position = seq_len(length(feature_names)),
        argval = basis_input$component_names,
        unit = basis_input$unit,
        basis_type = basis_input$basis_type,
        transform = spec$method,
        source_representation = basis_input$source_representation,
        component = basis_input$component_names
      ),
      transformed = transformed
    ))
  }

  if (is.null(grid_input)) {
    stop(sprintf("Predictor `%s` is not supported by the identity transform.", predictor_name), call. = FALSE)
  }

  values <- grid_input$values
  feature_names <- colnames(values) %||% paste0(predictor_name, "_", seq_len(ncol(values)))
  colnames(values) <- feature_names
  scaling <- compute_scaling_parameters(values, center = spec$center, scale = spec$scale)
  transformed <- apply_scaling_parameters(values, scaling)

  list(
    name = predictor_name,
    method = spec$method,
    representation = "grid",
    basis_type = NA_character_,
    feature_names = feature_names,
    transform = spec$method,
    unit = grid_input$unit,
    argvals = grid_input$argvals,
    params = scaling,
    apply = function(new_x) {
      new_grid <- as_grid_like(new_x, predictor_name)
      if (is.null(new_grid)) {
        stop(sprintf("Predictor `%s` must be supplied on a common grid for this preprocessor.", predictor_name), call. = FALSE)
      }
      values_new <- new_grid$values
      if (ncol(values_new) != length(feature_names)) {
        stop(sprintf("Grid predictor `%s` must keep the same number of grid points.", predictor_name), call. = FALSE)
      }
      if (!is.null(new_grid$argvals) && !identical(as.character(new_grid$argvals), as.character(grid_input$argvals))) {
        stop(sprintf("Grid predictor `%s` must keep the same `argvals` when reusing a fitted preprocessor.", predictor_name), call. = FALSE)
      }
      colnames(values_new) <- feature_names
      apply_scaling_parameters(values_new, scaling)
    },
    feature_map = feature_map_from_block(
      feature_names = feature_names,
      predictor = predictor_name,
      representation = "grid",
      position = seq_len(length(feature_names)),
      argval = grid_input$argvals,
      unit = grid_input$unit,
      transform = spec$method,
      source_representation = grid_input$source_representation
    ),
    transformed = transformed
  )
}

fit_bspline_transform <- function(x, predictor_name, spec) {
  grid_input <- as_grid_like(x, predictor_name)
  if (is.null(grid_input)) {
    stop("Spline basis preprocessing requires a grid-based functional predictor.", call. = FALSE)
  }

  values <- grid_input$values
  argvals <- grid_input$argvals
  numeric_argvals <- coerce_numeric_argvals(argvals, predictor_name, "bspline")
  basis_matrix <- splines::bs(
    x = numeric_argvals,
    df = spec$df,
    degree = spec$degree,
    intercept = spec$intercept
  )
  coefficients <- t(qr.solve(basis_matrix, t(values)))
  scaling <- compute_scaling_parameters(coefficients, center = spec$center, scale = spec$scale)
  transformed <- apply_scaling_parameters(coefficients, scaling)
  component_names <- paste0("B", seq_len(ncol(coefficients)))
  colnames(transformed) <- paste0(predictor_name, "_", component_names)
  support <- basis_support_from_matrix(basis_matrix, argvals)

  basis_args <- list(
    degree = attr(basis_matrix, "degree"),
    knots = attr(basis_matrix, "knots"),
    Boundary.knots = attr(basis_matrix, "Boundary.knots"),
    intercept = attr(basis_matrix, "intercept")
  )

  list(
    name = predictor_name,
    method = spec$method,
    representation = "basis",
    basis_type = "spline",
    feature_names = colnames(transformed),
    transform = spec$method,
    unit = grid_input$unit,
    argvals = component_names,
    params = scaling,
    basis_args = basis_args,
    support = support,
    apply = function(new_x) {
      new_grid <- as_grid_like(new_x, predictor_name)
      if (is.null(new_grid)) {
        stop(sprintf("Predictor `%s` must be grid-based for spline preprocessing.", predictor_name), call. = FALSE)
      }
      new_numeric_argvals <- coerce_numeric_argvals(new_grid$argvals, predictor_name, "bspline")
      new_basis <- splines::bs(
        x = new_numeric_argvals,
        degree = basis_args$degree,
        knots = basis_args$knots,
        Boundary.knots = basis_args$Boundary.knots,
        intercept = basis_args$intercept
      )
      coeff_new <- t(qr.solve(new_basis, t(new_grid$values)))
      scaled <- apply_scaling_parameters(coeff_new, scaling)
      colnames(scaled) <- colnames(transformed)
      scaled
    },
    feature_map = feature_map_from_block(
      feature_names = colnames(transformed),
      predictor = predictor_name,
      representation = "basis",
      position = seq_len(ncol(transformed)),
      argval = component_names,
      unit = grid_input$unit,
      basis_type = "spline",
      transform = spec$method,
      source_representation = grid_input$source_representation,
      source_position_start = support$start_idx,
      source_position_end = support$end_idx,
      source_argval_start = support$start_argval,
      source_argval_end = support$end_argval,
      domain_start = support$start_argval,
      domain_end = support$end_argval,
      component = component_names
    ),
    transformed = transformed
  )
}

fit_fpca_transform <- function(x, predictor_name, spec) {
  grid_input <- as_grid_like(x, predictor_name)
  if (is.null(grid_input)) {
    stop("FPCA preprocessing requires a grid-based functional predictor.", call. = FALSE)
  }

  fit <- stats::prcomp(
    x = grid_input$values,
    center = isTRUE(spec$center),
    scale. = isTRUE(spec$scale)
  )

  n_components <- spec$n_components
  if (!is.null(spec$variance_explained)) {
    explained <- cumsum(fit$sdev ^ 2) / sum(fit$sdev ^ 2)
    n_components <- which(explained >= spec$variance_explained)[1]
  }
  n_components <- max(1L, min(as.integer(n_components), ncol(fit$x)))
  scores <- fit$x[, seq_len(n_components), drop = FALSE]
  component_names <- paste0("PC", seq_len(n_components))
  colnames(scores) <- paste0(predictor_name, "_", component_names)

  domain_start <- rep(as.character(grid_input$argvals[1]), n_components)
  domain_end <- rep(as.character(grid_input$argvals[length(grid_input$argvals)]), n_components)

  list(
    name = predictor_name,
    method = spec$method,
    representation = "basis",
    basis_type = "fpca",
    feature_names = colnames(scores),
    transform = spec$method,
    unit = grid_input$unit,
    argvals = component_names,
    rotation = fit$rotation[, seq_len(n_components), drop = FALSE],
    center = fit$center,
    scale = fit$scale %||% FALSE,
    sdev = fit$sdev[seq_len(n_components)],
    source_argvals = grid_input$argvals,
    apply = function(new_x) {
      new_grid <- as_grid_like(new_x, predictor_name)
      if (is.null(new_grid)) {
        stop(sprintf("Predictor `%s` must be grid-based for FPCA preprocessing.", predictor_name), call. = FALSE)
      }
      if (!identical(as.character(new_grid$argvals), as.character(grid_input$argvals))) {
        stop(sprintf("Predictor `%s` must keep the same `argvals` for FPCA preprocessing.", predictor_name), call. = FALSE)
      }
      centered <- scale(
        new_grid$values,
        center = fit$center,
        scale = fit$scale %||% FALSE
      )
      scores_new <- centered %*% fit$rotation[, seq_len(n_components), drop = FALSE]
      colnames(scores_new) <- colnames(scores)
      scores_new
    },
    feature_map = feature_map_from_block(
      feature_names = colnames(scores),
      predictor = predictor_name,
      representation = "basis",
      position = seq_len(n_components),
      argval = component_names,
      unit = grid_input$unit,
      basis_type = "fpca",
      transform = spec$method,
      source_representation = grid_input$source_representation,
      source_position_start = rep(1L, n_components),
      source_position_end = rep(length(grid_input$argvals), n_components),
      source_argval_start = domain_start,
      source_argval_end = domain_end,
      domain_start = domain_start,
      domain_end = domain_end,
      component = component_names
    ),
    transformed = scores
  )
}

fit_one_preprocess <- function(x, predictor_name, spec) {
  if (!is_preprocess_spec(spec)) {
    stop(sprintf("Preprocessing specification for `%s` must be created with `fda_identity()`, `fda_standardize()`, `fda_bspline()`, or `fda_fpca()`.", predictor_name), call. = FALSE)
  }

  if (identical(spec$method, "bspline")) {
    return(fit_bspline_transform(x, predictor_name, spec))
  }
  if (identical(spec$method, "fpca")) {
    return(fit_fpca_transform(x, predictor_name, spec))
  }
  fit_identity_transform(x, predictor_name, spec)
}

build_fda_matrix_from_fits <- function(fits) {
  if (length(fits) == 0L) {
    stop("At least one predictor is required to build an FDA matrix.", call. = FALSE)
  }

  matrices <- lapply(fits, `[[`, "transformed")
  feature_map <- do.call(rbind, lapply(fits, `[[`, "feature_map"))
  feature_map$feature_index <- seq_len(nrow(feature_map))
  x <- do.call(cbind, matrices)
  colnames(x) <- feature_map$feature

  structure(
    list(
      x = x,
      blocks = feature_map$block,
      positions = feature_map$position,
      feature_map = feature_map
    ),
    class = "fda_matrix"
  )
}

#' Scalar Predictor Constructor
#'
#' Wraps scalar covariates so they can participate in the same feature-mapping
#' and preprocessing machinery as functional predictors.
#'
#' @param values Numeric vector or matrix with one row per observation.
#' @param name Optional predictor name.
#' @param unit Optional unit label.
#'
#' @returns An object of class `fda_scalar`.
#' @export
fda_scalar <- function(values, name = NULL, unit = NULL) {
  if (is.vector(values) && !is.list(values)) {
    values <- matrix(values, ncol = 1L)
  } else {
    values <- as.matrix(values)
  }
  storage.mode(values) <- "double"

  feature_names <- colnames(values)
  if (is.null(feature_names)) {
    feature_names <- if (!is.null(name) && ncol(values) == 1L) name else paste0(name %||% "scalar", "_", seq_len(ncol(values)))
    colnames(values) <- feature_names
  }

  structure(
    list(
      values = values,
      name = name %||% if (ncol(values) == 1L) colnames(values)[1] else "scalar",
      unit = unit
    ),
    class = c("fda_scalar", "fda_predictor")
  )
}

#' @export
print.fda_scalar <- function(x, ...) {
  cat("FDA scalar predictor\n")
  cat("  name:", x$name, "\n")
  cat("  observations:", nrow(x$values), "\n")
  cat("  covariates:", ncol(x$values), "\n")
  invisible(x)
}

#' Identity Preprocessing Spec
#'
#' @param center,scale Logical flags controlling column-wise centering and
#'   scaling of the transformed features.
#'
#' @returns An object of class `fda_preprocess_spec`.
#' @export
fda_identity <- function(center = FALSE, scale = FALSE) {
  structure(
    list(
      method = "identity",
      center = isTRUE(center),
      scale = isTRUE(scale)
    ),
    class = "fda_preprocess_spec"
  )
}

#' Standardization Preprocessing Spec
#'
#' @param center,scale Logical flags controlling column-wise centering and
#'   scaling. Both default to `TRUE`.
#'
#' @returns An object of class `fda_preprocess_spec`.
#' @export
fda_standardize <- function(center = TRUE, scale = TRUE) {
  structure(
    list(
      method = "standardize",
      center = isTRUE(center),
      scale = isTRUE(scale)
    ),
    class = "fda_preprocess_spec"
  )
}

#' Spline-Basis Preprocessing Spec
#'
#' @param df Degrees of freedom used by [splines::bs()].
#' @param degree Spline degree.
#' @param intercept Should the spline basis include an intercept column?
#' @param center,scale Logical flags controlling column-wise centering and
#'   scaling of the resulting coefficients.
#'
#' @returns An object of class `fda_preprocess_spec`.
#' @export
fda_bspline <- function(df = 6L,
                        degree = 3L,
                        intercept = TRUE,
                        center = FALSE,
                        scale = FALSE) {
  structure(
    list(
      method = "bspline",
      df = as.integer(df),
      degree = as.integer(degree),
      intercept = isTRUE(intercept),
      center = isTRUE(center),
      scale = isTRUE(scale)
    ),
    class = "fda_preprocess_spec"
  )
}

#' FPCA Preprocessing Spec
#'
#' @param n_components Number of principal components to retain.
#' @param variance_explained Optional cumulative explained variance target in
#'   `(0, 1]`. When supplied, it overrides `n_components`.
#' @param center,scale Passed to [stats::prcomp()].
#'
#' @returns An object of class `fda_preprocess_spec`.
#' @export
fda_fpca <- function(n_components = 3L,
                     variance_explained = NULL,
                     center = TRUE,
                     scale = FALSE) {
  if (!is.null(variance_explained) &&
      (!is.numeric(variance_explained) || length(variance_explained) != 1L ||
        variance_explained <= 0 || variance_explained > 1)) {
    stop("`variance_explained` must be a single number in `(0, 1]`.", call. = FALSE)
  }

  structure(
    list(
      method = "fpca",
      n_components = as.integer(n_components),
      variance_explained = variance_explained,
      center = isTRUE(center),
      scale = isTRUE(scale)
    ),
    class = "fda_preprocess_spec"
  )
}

#' Fit an FDA Preprocessor
#'
#' Learns train/test-safe preprocessing transforms for functional predictors and
#' optional scalar covariates. The fitted object can be reused to create
#' compatible `fda_design` objects on new data.
#'
#' @param predictors One predictor or a named list of predictors.
#' @param scalar_covariates Optional scalar covariates supplied as a vector,
#'   matrix/data frame, `fda_scalar`, or a named list.
#' @param transforms Optional preprocessing specs for functional predictors.
#' @param scalar_transform Optional preprocessing specs for scalar covariates.
#'
#' @returns An object of class `fda_preprocessor`.
#' @export
fit_fda_preprocessor <- function(predictors,
                                 scalar_covariates = NULL,
                                 transforms = NULL,
                                 scalar_transform = NULL) {
  predictors <- normalize_predictor_collection(predictors)
  scalar_covariates <- normalize_scalar_collection(scalar_covariates)

  transform_specs <- normalize_spec_map(
    specs = transforms,
    expected_names = names(predictors),
    default_spec = fda_identity()
  )
  scalar_specs <- normalize_spec_map(
    specs = scalar_transform,
    expected_names = names(scalar_covariates),
    default_spec = fda_identity()
  )

  fitted_predictors <- lapply(names(predictors), function(name) {
    fit_one_preprocess(predictors[[name]], name, transform_specs[[name]])
  })
  names(fitted_predictors) <- names(predictors)

  fitted_scalars <- lapply(names(scalar_covariates), function(name) {
    fit_one_preprocess(scalar_covariates[[name]], name, scalar_specs[[name]])
  })
  names(fitted_scalars) <- names(scalar_covariates)

  all_fits <- c(fitted_predictors, fitted_scalars)
  feature_map <- if (length(all_fits) > 0L) {
    do.call(rbind, lapply(all_fits, `[[`, "feature_map"))
  } else {
    data.frame()
  }

  structure(
    list(
      predictors = fitted_predictors,
      scalar_covariates = fitted_scalars,
      feature_map = feature_map
    ),
    class = "fda_preprocessor"
  )
}

#' Apply an FDA Preprocessor
#'
#' Applies a fitted preprocessor to new functional predictors and optional
#' scalar covariates, returning an `fda_matrix` object compatible with the
#' selection routines.
#'
#' @param object A fitted `fda_preprocessor`.
#' @param predictors New functional predictors.
#' @param scalar_covariates Optional scalar covariates.
#' @param ... Not used.
#'
#' @returns An object of class `fda_matrix`.
#' @export
apply_fda_preprocessor <- function(object,
                                   predictors,
                                   scalar_covariates = NULL,
                                   ...) {
  if (!inherits(object, "fda_preprocessor")) {
    stop("`object` must inherit from class `fda_preprocessor`.", call. = FALSE)
  }

  predictors <- normalize_predictor_collection(predictors)
  scalar_covariates <- normalize_scalar_collection(scalar_covariates)

  expected_predictors <- names(object$predictors)
  expected_scalars <- names(object$scalar_covariates)
  if (!setequal(names(predictors), expected_predictors)) {
    stop(sprintf(
      "Predictors must match the fitted preprocessor. Expected: %s.",
      paste(expected_predictors, collapse = ", ")
    ), call. = FALSE)
  }
  if (!setequal(names(scalar_covariates), expected_scalars)) {
    stop(sprintf(
      "Scalar covariates must match the fitted preprocessor. Expected: %s.",
      paste(expected_scalars, collapse = ", ")
    ), call. = FALSE)
  }

  fitted <- vector("list", length(expected_predictors) + length(expected_scalars))
  counter <- 1L

  for (name in expected_predictors) {
    fit <- object$predictors[[name]]
    transformed <- fit$apply(predictors[[name]])
    fit$transformed <- transformed
    fitted[[counter]] <- fit
    counter <- counter + 1L
  }

  for (name in expected_scalars) {
    fit <- object$scalar_covariates[[name]]
    transformed <- fit$apply(scalar_covariates[[name]])
    fit$transformed <- transformed
    fitted[[counter]] <- fit
    counter <- counter + 1L
  }

  names(fitted) <- c(expected_predictors, expected_scalars)
  build_fda_matrix_from_fits(fitted)
}

#' @export
print.fda_preprocessor <- function(x, ...) {
  total_predictors <- length(x$predictors) + length(x$scalar_covariates)
  cat("FDA preprocessor\n")
  cat("  functional predictors:", length(x$predictors), "\n")
  cat("  scalar covariates:", length(x$scalar_covariates), "\n")
  cat("  total blocks:", total_predictors, "\n")
  invisible(x)
}

#' @export
summary.fda_preprocessor <- function(object, ...) {
  fits <- c(object$predictors, object$scalar_covariates)
  data <- do.call(rbind, lapply(fits, function(fit) {
    data.frame(
      predictor = fit$name,
      representation = fit$representation,
      transform = fit$transform,
      n_features = length(fit$feature_names),
      stringsAsFactors = FALSE
    )
  }))

  structure(
    list(
      predictors = data,
      n_predictors = nrow(data)
    ),
    class = "summary.fda_preprocessor"
  )
}

#' @export
print.summary.fda_preprocessor <- function(x, ...) {
  cat("FDA preprocessor summary\n")
  cat("  predictors:", x$n_predictors, "\n")
  print(x$predictors, row.names = FALSE)
  invisible(x)
}
