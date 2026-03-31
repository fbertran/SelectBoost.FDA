selector_alias <- function(selector, allow_msgps = FALSE) {
  selector <- tolower(selector)
  aliases <- c(
    lasso = "lasso",
    glmnet = "lasso",
    group_lasso = "group_lasso",
    grpreg = "group_lasso",
    sparse_group_lasso = "sparse_group_lasso",
    sgl = "sparse_group_lasso"
  )

  if (isTRUE(allow_msgps)) {
    aliases <- c(aliases, msgps = "msgps")
  }

  if (!selector %in% names(aliases)) {
    stop(sprintf(
      "Unsupported selector `%s`. Supported values are: %s.",
      selector,
      paste(unique(names(aliases)), collapse = ", ")
    ), call. = FALSE)
  }

  unname(aliases[[selector]])
}

selector_requires_group_index <- function(selector_name) {
  selector_name %in% c("group_lasso", "sparse_group_lasso")
}

resolve_selector_groups <- function(selector_name, groups) {
  if (!selector_requires_group_index(selector_name)) {
    return(groups)
  }

  group_index <- group_index_vector(groups)
  if (is.null(group_index)) {
    stop(sprintf(
      "Selector `%s` requires non-overlapping groups. Use `selector = \"lasso\"` for overlapping interval summaries.",
      selector_name
    ), call. = FALSE)
  }

  group_index
}

glmnet_coefficients <- function(X,
                                y,
                                family = "gaussian",
                                alpha = 1,
                                lambda_rule = c("lambda.1se", "lambda.min"),
                                nfolds = 5L,
                                ...) {
  if (!requireNamespace("glmnet", quietly = TRUE)) {
    stop("Package `glmnet` is required for the lasso selector.", call. = FALSE)
  }

  lambda_rule <- match.arg(lambda_rule)
  nfolds <- min(as.integer(nfolds), nrow(X))
  if (nfolds < 3L) {
    stop("At least three observations are required for the glmnet selector.", call. = FALSE)
  }

  fit <- glmnet::cv.glmnet(
    x = X,
    y = y,
    family = family,
    alpha = alpha,
    nfolds = nfolds,
    ...
  )

  as.numeric(stats::coef(fit, s = fit[[lambda_rule]]))[-1L]
}

grpreg_coefficients <- function(X,
                                y,
                                groups,
                                family = "gaussian",
                                penalty = "grLasso",
                                lambda_rule = c("lambda.1se", "lambda.min"),
                                nfolds = 5L,
                                ...) {
  if (!requireNamespace("grpreg", quietly = TRUE)) {
    stop("Package `grpreg` is required for the group lasso selector.", call. = FALSE)
  }

  lambda_rule <- match.arg(lambda_rule)
  nfolds <- min(as.integer(nfolds), nrow(X))
  if (nfolds < 3L) {
    stop("At least three observations are required for the grpreg selector.", call. = FALSE)
  }

  fit <- grpreg::cv.grpreg(
    X = X,
    y = y,
    group = groups,
    family = family,
    penalty = penalty,
    nfolds = nfolds,
    ...
  )

  lambda_value <- if (identical(lambda_rule, "lambda.min")) {
    fit$lambda.min
  } else if (!is.null(fit$lambda.1se)) {
    fit$lambda.1se
  } else {
    threshold <- fit$cve[fit$min] + fit$cvse[fit$min]
    max(fit$lambda[fit$cve <= threshold])
  }

  as.numeric(stats::coef(fit, lambda = lambda_value))[-1L]
}

sgl_coefficients <- function(X,
                             y,
                             groups,
                             family = "gaussian",
                             alpha = 0.95,
                             lambda_rule = c("lambda.1se", "lambda.min"),
                             nfolds = 5L,
                             standardize = TRUE,
                             nlam = 20L,
                             ...) {
  if (!requireNamespace("SGL", quietly = TRUE)) {
    stop("Package `SGL` is required for the sparse-group lasso selector.", call. = FALSE)
  }

  lambda_rule <- match.arg(lambda_rule)
  nfolds <- min(as.integer(nfolds), nrow(X))
  if (nfolds < 3L) {
    stop("At least three observations are required for the sparse-group lasso selector.", call. = FALSE)
  }

  type <- if (identical(family, "binomial")) "logit" else "linear"
  fit <- SGL::cvSGL(
    data = list(x = X, y = y),
    index = as.integer(groups),
    type = type,
    nfold = nfolds,
    alpha = alpha,
    standardize = standardize,
    nlam = as.integer(nlam),
    ...
  )

  min_idx <- which.min(fit$lldiff)
  lambda_idx <- if (identical(lambda_rule, "lambda.min")) {
    min_idx
  } else {
    threshold <- fit$lldiff[min_idx] + fit$llSD[min_idx]
    candidates <- which(fit$lldiff <= threshold)
    min(candidates)
  }

  as.numeric(fit$fit$beta[, lambda_idx])
}
