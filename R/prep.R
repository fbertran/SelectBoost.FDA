# Internal utilities -------------------------------------------------------

`%||%` <- function(x, y) {
  if (is.null(x)) {
    y
  } else {
    x
  }
}

check_no_missing <- function(x, name) {
  if (anyNA(x)) {
    stop(sprintf("`%s` must not contain missing values.", name), call. = FALSE)
  }
}

normalize_response <- function(y, family) {
  if (!identical(family, "binomial")) {
    return(y)
  }

  if (is.factor(y)) {
    if (nlevels(y) != 2L) {
      stop("`y` must have exactly two levels for `family = \"binomial\"`.", call. = FALSE)
    }
    return(as.integer(y == levels(y)[2L]))
  }

  if (is.logical(y)) {
    return(as.integer(y))
  }

  if (is.numeric(y)) {
    values <- sort(unique(stats::na.omit(y)))
    if (!all(values %in% c(0, 1))) {
      stop("Numeric binomial responses must be coded as 0/1.", call. = FALSE)
    }
    return(as.numeric(y))
  }

  stop("Unsupported response type for `family = \"binomial\"`.", call. = FALSE)
}

validate_xy <- function(x, y, family = "gaussian") {
  if (!inherits(x, "fda_matrix")) {
    stop("`x` must inherit from class `fda_matrix`.", call. = FALSE)
  }

  if (length(y) != nrow(x$x)) {
    stop("`y` must have one entry per observation.", call. = FALSE)
  }

  check_no_missing(x$x, "x")
  check_no_missing(y, "y")
  normalize_response(y, family = family)
}

normalize_groups <- function(groups, p) {
  if (is.null(groups)) {
    values <- seq_len(p)
    attr(values, "group_labels") <- as.character(values)
    return(values)
  }

  if (inherits(groups, "fda_group_list")) {
    labels <- attr(groups, "group_labels", exact = TRUE) %||% names(groups) %||% paste0("group", seq_along(groups))
    attr(groups, "group_labels") <- labels

    for (i in seq_along(groups)) {
      idx <- sort(unique(as.integer(groups[[i]])))
      if (length(idx) == 0L) {
        next
      }
      if (any(idx < 1L | idx > p)) {
        stop("Group indices must be between 1 and `ncol(x)`.", call. = FALSE)
      }
      groups[[i]] <- idx
    }

    return(groups)
  }

  if (is.list(groups)) {
    membership <- rep.int(NA_integer_, p)
    labels <- names(groups) %||% paste0("group", seq_along(groups))
    for (i in seq_along(groups)) {
      idx <- as.integer(groups[[i]])
      if (length(idx) == 0L) {
        next
      }
      if (any(idx < 1L | idx > p)) {
        stop("Group indices must be between 1 and `ncol(x)`.", call. = FALSE)
      }
      if (any(!is.na(membership[idx]))) {
        stop("Overlapping groups must inherit from class `fda_group_list`.", call. = FALSE)
      }
      membership[idx] <- i
    }
    if (anyNA(membership)) {
      stop("List-based groups must cover every feature exactly once.", call. = FALSE)
    }
    attr(membership, "group_labels") <- labels
    return(membership)
  }

  if (length(groups) != p) {
    stop("`groups` must be NULL, a length-`p` vector, or a disjoint list of indices.", call. = FALSE)
  }

  original_labels <- attr(groups, "group_labels", exact = TRUE)
  groups_factor <- factor(groups, levels = unique(groups))
  values <- as.integer(groups_factor)
  attr(values, "group_labels") <- original_labels %||% levels(groups_factor)
  values
}

split_groups <- function(groups) {
  if (inherits(groups, "fda_group_list")) {
    return(groups)
  }
  split(seq_along(groups), groups)
}

group_names <- function(groups) {
  if (inherits(groups, "fda_group_list")) {
    return(attr(groups, "group_labels", exact = TRUE) %||% names(groups) %||% paste0("group", seq_along(groups)))
  }
  attr(groups, "group_labels") %||% as.character(sort(unique(groups)))
}

groups_overlap <- function(groups) {
  inherits(groups, "fda_group_list") && isTRUE(attr(groups, "overlap", exact = TRUE))
}

group_index_vector <- function(groups) {
  if (inherits(groups, "fda_group_list")) {
    if (groups_overlap(groups)) {
      return(NULL)
    }

    p <- max(unlist(groups, use.names = FALSE))
    membership <- rep.int(NA_integer_, p)
    for (i in seq_along(groups)) {
      membership[groups[[i]]] <- i
    }
    attr(membership, "group_labels") <- group_names(groups)
    return(membership)
  }

  groups
}

feature_group_labels <- function(groups, p) {
  labels <- group_names(groups)
  if (!inherits(groups, "fda_group_list")) {
    return(labels[groups])
  }

  members <- split_groups(groups)
  output <- rep.int(NA_character_, p)
  for (j in seq_len(p)) {
    current <- labels[vapply(members, function(idx) j %in% idx, logical(1))]
    output[j] <- if (length(current) == 0L) NA_character_ else paste(current, collapse = " | ")
  }
  output
}

mask_by_structure <- function(association, blocks, positions, within_blocks = TRUE, bandwidth = NULL) {
  p <- ncol(association)
  mask <- matrix(TRUE, nrow = p, ncol = p)

  if (within_blocks) {
    mask <- mask & outer(blocks, blocks, `==`)
  }

  if (!is.null(bandwidth)) {
    if (!is.numeric(bandwidth) || length(bandwidth) != 1L || bandwidth < 0) {
      stop("`bandwidth` must be a single non-negative number.", call. = FALSE)
    }
    bandwidth <- as.numeric(bandwidth)
    mask <- mask & (abs(outer(positions, positions, `-`)) <= bandwidth)
  }

  association[!mask] <- 0
  diag(association) <- 1
  association
}


#' Flatten Functional Predictors Into a Matrix
#'
#' Accepts a standard numeric matrix/data frame or a named list of functional
#' blocks. List inputs are column-bound while preserving the original block
#' membership of each coefficient, which is later reused for grouped stability
#' selection and FDA-aware SelectBoost grouping.
#'
#' @param x A numeric matrix/data frame, an `fda_grid`, an `fda_basis`, an
#'   `fda_design`, or a list of such objects. Each list element is treated as
#'   one functional block.
#' @param center,scale Passed to [base::scale()] when either argument is `TRUE`.
#'
#' @returns An object of class `fda_matrix` with elements `x`, `blocks`, and
#'   `positions`.
#' @export
as_functional_matrix <- function(x, center = FALSE, scale = FALSE) {
  if (inherits(x, "fda_matrix")) {
    return(x)
  }

  if (inherits(x, "fda_design")) {
    return(x$matrix)
  }

  if (inherits(x, c("fda_grid", "fda_basis", "fda_scalar")) ||
      is.matrix(x) ||
      is.data.frame(x) ||
      (is.vector(x) && !is.list(x))) {
    return(assemble_functional_matrix(
      blocks = list(block1 = x),
      center = center,
      scale = scale
    ))
  }

  if (!is.list(x) || length(x) == 0L) {
    stop("`x` must be a matrix, data frame, predictor object, or a non-empty list of blocks.", call. = FALSE)
  }

  assemble_functional_matrix(blocks = x, center = center, scale = scale)
}

#' @export
print.fda_matrix <- function(x, ...) {
  cat("Functional predictor matrix\n")
  cat("  observations:", nrow(x$x), "\n")
  cat("  features:", ncol(x$x), "\n")
  cat("  blocks:", length(unique(x$blocks)), "\n")
  invisible(x)
}

#' Block-Level Groups for Functional Predictors
#'
#' Returns one group label per column, with each functional block defining a
#' group.
#'
#' @param x Any input accepted by `as_functional_matrix()`.
#'
#' @returns An integer vector of group memberships.
#' @export
functional_block_groups <- function(x) {
  fda_x <- as_functional_matrix(x)
  groups <- normalize_groups(fda_x$blocks, p = ncol(fda_x$x))
  names(groups) <- colnames(fda_x$x)
  groups
}

#' Interval Groups for Discretized Functional Predictors
#'
#' Creates non-overlapping interval groups within each functional block. This is
#' useful when one wants region-level stability summaries instead of pointwise
#' selection frequencies.
#'
#' @param x Any input accepted by `as_functional_matrix()`.
#' @param width Positive integer interval width within each block.
#' @param step Step size between interval starts. Only non-overlapping intervals
#'   are supported by default.
#' @param overlap Logical; should intervals be allowed to overlap? When `TRUE`,
#'   the result is returned as an overlapping group structure.
#'
#' @returns Either an integer group vector with an `interval_table` attribute or
#'   an overlapping group structure of class `fda_group_list`.
#' @export
functional_interval_groups <- function(x, width, step = width, overlap = FALSE) {
  fda_x <- as_functional_matrix(x)

  if (!is.numeric(width) || length(width) != 1L || width < 1) {
    stop("`width` must be a positive integer.", call. = FALSE)
  }
  if (!is.numeric(step) || length(step) != 1L || step < 1) {
    stop("`step` must be a positive integer.", call. = FALSE)
  }

  width <- as.integer(width)
  step <- as.integer(step)
  if (!isTRUE(overlap) && step != width) {
    stop("When `overlap = FALSE`, `step` must equal `width`.", call. = FALSE)
  }

  groups <- if (isTRUE(overlap)) vector("list", 0L) else integer(ncol(fda_x$x))
  interval_table <- vector("list", 0L)
  counter <- 1L

  for (block_name in unique(fda_x$blocks)) {
    idx <- which(fda_x$blocks == block_name)
    starts <- seq.int(1L, length(idx), by = step)
    for (start in starts) {
      end <- min(length(idx), start + width - 1L)
      current_idx <- idx[start:end]
      if (isTRUE(overlap)) {
        groups[[counter]] <- current_idx
      } else {
        groups[current_idx] <- counter
      }
      interval_table[[counter]] <- data.frame(
        group = counter,
        block = block_name,
        start = start,
        end = end,
        label = sprintf("%s[%d:%d]", block_name, start, end),
        stringsAsFactors = FALSE
      )
      counter <- counter + 1L
    }
  }

  interval_table <- do.call(rbind, interval_table)
  if (isTRUE(overlap)) {
    names(groups) <- interval_table$label
    attr(groups, "group_labels") <- interval_table$label
    attr(groups, "interval_table") <- interval_table
    attr(groups, "overlap") <- TRUE
    class(groups) <- c("fda_group_list", class(groups))
    return(groups)
  }

  attr(groups, "group_labels") <- interval_table$label
  attr(groups, "interval_table") <- interval_table
  names(groups) <- colnames(fda_x$x)
  groups
}

#' Functional Association Matrix
#'
#' Computes or post-processes an absolute association matrix for discretized or
#' basis-expanded functional predictors.
#'
#' @param x Any input accepted by `as_functional_matrix()`.
#' @param association Optional square association matrix supplied by the user.
#'   When omitted, `abs(stats::cor(X))` is used.
#' @param method Association structure. `"correlation"` uses the absolute
#'   correlation matrix, `"neighborhood"` uses local positional similarity,
#'   `"hybrid"` multiplies correlation by a neighborhood kernel, and
#'   `"interval"` induces associations within interval groups.
#' @param within_blocks Should cross-block associations be zeroed out?
#' @param bandwidth Optional maximum within-block lag retained in the
#'   association matrix.
#' @param interval_groups Optional interval grouping used when
#'   `method = "interval"`.
#' @param width,step Interval parameters used when `method = "interval"` and
#'   `interval_groups` is omitted.
#' @param decay Positive exponent controlling the neighborhood kernel.
#'
#' @returns A square absolute association matrix with unit diagonal.
#' @export
functional_association <- function(x,
                                   association = NULL,
                                   method = c("correlation", "neighborhood", "hybrid", "interval"),
                                   within_blocks = TRUE,
                                   bandwidth = NULL,
                                   interval_groups = NULL,
                                   width = NULL,
                                   step = width,
                                   decay = 1) {
  fda_x <- as_functional_matrix(x)
  p <- ncol(fda_x$x)
  method <- match.arg(method)

  if (is.null(association)) {
    if (identical(method, "correlation")) {
      association <- abs(stats::cor(fda_x$x))
    } else if (identical(method, "neighborhood")) {
      distance <- abs(outer(fda_x$positions, fda_x$positions, `-`))
      association <- 1 / (1 + distance ^ decay)
    } else if (identical(method, "hybrid")) {
      distance <- abs(outer(fda_x$positions, fda_x$positions, `-`))
      neighborhood <- 1 / (1 + distance ^ decay)
      association <- abs(stats::cor(fda_x$x)) * neighborhood
    } else {
      if (is.null(interval_groups)) {
        if (is.null(width)) {
          stop("`width` must be supplied when `method = \"interval\"` and `interval_groups` is omitted.", call. = FALSE)
        }
        interval_groups <- functional_interval_groups(
          x = fda_x,
          width = width,
          step = step,
          overlap = step < width
        )
      }
      interval_groups <- normalize_groups(interval_groups, p = p)
      association <- matrix(0, nrow = p, ncol = p)
      for (member_idx in split_groups(interval_groups)) {
        association[member_idx, member_idx] <- 1
      }
    }
  } else {
    association <- as.matrix(association)
    if (!identical(dim(association), c(p, p))) {
      stop("`association` must be a square `p x p` matrix.", call. = FALSE)
    }
    association <- abs(association)
  }

  if (is.null(colnames(association))) {
    colnames(association) <- colnames(fda_x$x)
  }
  if (is.null(rownames(association))) {
    rownames(association) <- colnames(fda_x$x)
  }

  mask_by_structure(
    association = association,
    blocks = fda_x$blocks,
    positions = fda_x$positions,
    within_blocks = within_blocks,
    bandwidth = bandwidth
  )
}

#' FDA-Aware Grouping Function for SelectBoost
#'
#' Builds a closure that can be passed directly to `group=` in
#' [SelectBoost::fastboost()] or [SelectBoost::autoboost()]. The returned
#' grouping function respects functional block boundaries and can optionally
#' restrict groups to local neighborhoods along the observation grid.
#'
#' @param x Any input accepted by `as_functional_matrix()`.
#' @param association Optional square association matrix. When omitted, the
#'   correlation matrix supplied by `SelectBoost` is reused after applying the
#'   FDA-specific masks.
#' @param method Grouping strategy. `"threshold"` wraps
#'   [SelectBoost::group_func_1()] and `"community"` wraps
#'   [SelectBoost::group_func_2()].
#' @param association_method Association structure passed to
#'   [functional_association()].
#' @param within_blocks Should groups be restricted to features coming from the
#'   same functional block?
#' @param bandwidth Optional maximum within-block lag retained in groups.
#' @param interval_groups,width,step,decay Additional arguments passed to
#'   [functional_association()] when using region-aware associations.
#'
#' @returns A function with signature `(absXcor, c0)` compatible with
#'   `SelectBoost`.
#' @export
make_functional_grouping_function <- function(x,
                                              association = NULL,
                                              method = c("threshold", "community"),
                                              association_method = c("correlation", "neighborhood", "hybrid", "interval"),
                                              within_blocks = TRUE,
                                              bandwidth = NULL,
                                              interval_groups = NULL,
                                              width = NULL,
                                              step = width,
                                              decay = 1) {
  fda_x <- as_functional_matrix(x)
  method <- match.arg(method)
  association_method <- match.arg(association_method)
  fixed_association <- NULL

  if (!is.null(association)) {
    fixed_association <- functional_association(
      x = fda_x,
      association = association,
      method = association_method,
      within_blocks = within_blocks,
      bandwidth = bandwidth,
      interval_groups = interval_groups,
      width = width,
      step = step,
      decay = decay
    )
  }

  function(absXcor, c0) {
    current_association <- fixed_association
    if (is.null(current_association)) {
      current_association <- functional_association(
        x = fda_x,
        association = abs(absXcor),
        method = association_method,
        within_blocks = within_blocks,
        bandwidth = bandwidth,
        interval_groups = interval_groups,
        width = width,
        step = step,
        decay = decay
      )
    }

    if (identical(method, "threshold")) {
      return(SelectBoost::group_func_1(current_association, c0 = c0))
    }

    SelectBoost::group_func_2(current_association, c0 = c0)
  }
}
