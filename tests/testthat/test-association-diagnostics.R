test_that("association diagnostics summarize block and local structure", {
  data <- make_example_fda_data(n = 20)
  assoc <- functional_association(
    data$x,
    method = "neighborhood",
    within_blocks = TRUE,
    bandwidth = 1
  )
  summary <- summarise_association_structure(
    assoc,
    x = data$x,
    bandwidth = 1,
    method = "neighborhood"
  )

  expect_true(summary$diag_is_one)
  expect_equal(summary$cross_block_mass, 0)
  expect_true(summary$within_block_mass > 0)
  expect_true(summary$effective_degree_mean >= 0)
})

test_that("association method comparisons return one row per method", {
  data <- make_example_fda_data(n = 20)
  comparison <- compare_association_methods(
    data$x,
    methods = c("correlation", "neighborhood", "hybrid", "interval"),
    bandwidth = 1,
    width = 2
  )

  expect_equal(sort(comparison$method), sort(c("correlation", "neighborhood", "hybrid", "interval")))
  expect_true(all(c("sparsity", "local_mass", "nonlocal_mass") %in% names(comparison)))
})
