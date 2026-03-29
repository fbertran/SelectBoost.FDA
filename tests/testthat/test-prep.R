test_that("functional matrices preserve block metadata", {
  x <- list(
    spectra = matrix(1:12, nrow = 3, ncol = 4),
    kinetics = matrix(13:18, nrow = 3, ncol = 2)
  )

  out <- as_functional_matrix(x)

  expect_s3_class(out, "fda_matrix")
  expect_equal(dim(out$x), c(3, 6))
  expect_equal(out$blocks, c(rep("spectra", 4), rep("kinetics", 2)))
  expect_equal(out$positions, c(1:4, 1:2))
})

test_that("interval groups are created within each block", {
  x <- list(
    spectra = matrix(rnorm(20), nrow = 5, ncol = 4),
    kinetics = matrix(rnorm(20), nrow = 5, ncol = 4)
  )

  groups <- functional_interval_groups(x, width = 2)
  interval_table <- attr(groups, "interval_table")

  expect_equal(as.integer(groups), c(1, 1, 2, 2, 3, 3, 4, 4))
  expect_equal(interval_table$label, c(
    "spectra[1:2]",
    "spectra[3:4]",
    "kinetics[1:2]",
    "kinetics[3:4]"
  ))
})

test_that("association matrices respect block and lag constraints", {
  set.seed(10)
  x <- list(
    a = matrix(rnorm(30), nrow = 10, ncol = 3),
    b = matrix(rnorm(30), nrow = 10, ncol = 3)
  )

  assoc <- functional_association(x, within_blocks = TRUE, bandwidth = 1)

  expect_equal(assoc[1, 4], 0)
  expect_equal(assoc[1, 3], 0)
  expect_equal(unname(diag(assoc)), rep(1, 6))
})
