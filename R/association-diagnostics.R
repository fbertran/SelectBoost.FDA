association_metadata <- function(x, bandwidth = NULL) {
  fda_x <- as_functional_matrix(x)
  fmap <- fda_x$feature_map
  list(
    blocks = fmap$block,
    positions = fmap$position,
    bandwidth = bandwidth
  )
}

#' Summarize a Functional Association Matrix
#'
#' Computes structural diagnostics for an association matrix, including
#' sparsity, within-block mass, local mass, and effective degree.
#'
#' @param association Square association matrix.
#' @param x Optional functional input used to recover block and position
#'   metadata. If omitted, all features are treated as one block.
#' @param bandwidth Optional lag defining local versus nonlocal mass.
#' @param method Optional method label.
#'
#' @returns A one-row data frame of association diagnostics.
#' @export
summarise_association_structure <- function(association,
                                            x = NULL,
                                            bandwidth = NULL,
                                            method = NA_character_) {
  association <- abs(as.matrix(association))
  if (nrow(association) != ncol(association)) {
    stop("`association` must be a square matrix.", call. = FALSE)
  }
  p <- ncol(association)
  if (is.null(x)) {
    blocks <- rep("block", p)
    positions <- seq_len(p)
  } else {
    meta <- association_metadata(x, bandwidth = bandwidth)
    blocks <- meta$blocks
    positions <- meta$positions
    if (length(blocks) != p) {
      stop("`x` must describe the same number of features as `association`.", call. = FALSE)
    }
  }

  off_diag <- row(association) != col(association)
  same_block <- outer(blocks, blocks, `==`)
  local <- if (is.null(bandwidth)) {
    matrix(NA, nrow = p, ncol = p)
  } else {
    abs(outer(positions, positions, `-`)) <= bandwidth & same_block
  }

  total_mass <- sum(association[off_diag], na.rm = TRUE)
  if (total_mass == 0) {
    total_mass <- NA_real_
  }
  effective_degree <- rowSums(association > sqrt(.Machine$double.eps), na.rm = TRUE) - 1

  data.frame(
    method = method,
    mean_association = mean(association[off_diag], na.rm = TRUE),
    median_association = stats::median(association[off_diag], na.rm = TRUE),
    sparsity = mean(association[off_diag] <= sqrt(.Machine$double.eps), na.rm = TRUE),
    within_block_mass = sum(association[off_diag & same_block], na.rm = TRUE) / total_mass,
    cross_block_mass = sum(association[off_diag & !same_block], na.rm = TRUE) / total_mass,
    local_mass = if (is.null(bandwidth)) NA_real_ else sum(association[off_diag & local], na.rm = TRUE) / total_mass,
    nonlocal_mass = if (is.null(bandwidth)) NA_real_ else sum(association[off_diag & !local], na.rm = TRUE) / total_mass,
    effective_degree_mean = mean(effective_degree, na.rm = TRUE),
    effective_degree_sd = if (length(effective_degree) > 1L) stats::sd(effective_degree, na.rm = TRUE) else 0,
    diag_is_one = isTRUE(all.equal(unname(diag(association)), rep(1, p))),
    stringsAsFactors = FALSE
  )
}

#' Diagnose Functional Association Structures
#'
#' Builds and summarizes one or more FDA-aware association matrices.
#'
#' @param x Any input accepted by [as_functional_matrix()].
#' @param methods Association methods to compare.
#' @param bandwidth,width,step,within_blocks,decay Passed to
#'   [functional_association()].
#'
#' @returns A data frame with one row per association method.
#' @export
diagnose_functional_association <- function(x,
                                            methods = c("correlation", "neighborhood", "hybrid", "interval"),
                                            bandwidth = NULL,
                                            width = NULL,
                                            step = width,
                                            within_blocks = TRUE,
                                            decay = 1) {
  methods <- match.arg(
    methods,
    c("correlation", "neighborhood", "hybrid", "interval"),
    several.ok = TRUE
  )
  rows <- lapply(methods, function(method) {
    current_width <- width
    current_step <- step
    if (identical(method, "interval") && is.null(current_width)) {
      current_width <- default_interval_width(x)
      current_step <- current_step %||% current_width
    }
    association <- functional_association(
      x = x,
      method = method,
      within_blocks = within_blocks,
      bandwidth = bandwidth,
      width = current_width,
      step = current_step,
      decay = decay
    )
    out <- summarise_association_structure(
      association = association,
      x = x,
      bandwidth = bandwidth,
      method = method
    )
    out$within_blocks <- within_blocks
    out$bandwidth <- bandwidth %||% NA_real_
    out$width <- current_width %||% NA_real_
    out$step <- current_step %||% NA_real_
    out
  })
  rbind_fill_data_frames(rows)
}

#' Compare Functional Association Methods
#'
#' Alias for [diagnose_functional_association()] with method-comparison naming.
#'
#' @inheritParams diagnose_functional_association
#'
#' @returns A data frame with association diagnostics.
#' @export
compare_association_methods <- function(x,
                                        methods = c("correlation", "neighborhood", "hybrid", "interval"),
                                        bandwidth = NULL,
                                        width = NULL,
                                        step = width,
                                        within_blocks = TRUE,
                                        decay = 1) {
  diagnose_functional_association(
    x = x,
    methods = methods,
    bandwidth = bandwidth,
    width = width,
    step = step,
    within_blocks = within_blocks,
    decay = decay
  )
}
