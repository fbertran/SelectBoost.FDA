with_optional_seed <- function(seed, code) {
  if (is.null(seed)) {
    return(force(code))
  }

  if (!is.numeric(seed) || length(seed) != 1L || is.na(seed)) {
    stop("`seed` must be `NULL` or a single numeric value.", call. = FALSE)
  }

  withr::with_seed(as.integer(seed), code)
}
