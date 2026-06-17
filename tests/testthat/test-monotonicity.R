test_that("monotonicity diagnostics flag artificial violations", {
  surface <- data.frame(
    feature = c("a", "a", "b", "b"),
    level = "feature",
    c0 = c(0.2, 0.5, 0.2, 0.5),
    q = NA_real_,
    selection = c(0.8, 0.9, 0.4, 0.2),
    stringsAsFactors = FALSE
  )

  diagnostic <- check_selection_monotonicity(
    surface,
    axis = "c0",
    direction = "nonincreasing",
    level = "feature"
  )
  summary <- summarise_monotonicity(diagnostic)

  expect_s3_class(diagnostic, "fda_monotonicity_diagnostic")
  expect_equal(sum(!diagnostic$is_monotone), 1)
  expect_equal(summary$n_paths, 2)
  expect_equal(summary$n_monotone, 1)
})

test_that("monotone enforcement removes cumulative violations", {
  surface <- data.frame(
    feature = c("a", "a", "a"),
    level = "feature",
    c0 = c(0.1, 0.5, 0.9),
    selection = c(0.7, 0.8, 0.2),
    stringsAsFactors = FALSE
  )

  enforced <- enforce_monotone_selection(
    surface,
    axis = "c0",
    direction = "nonincreasing",
    method = "cummin",
    level = "feature"
  )

  expect_true("adjusted_value" %in% names(enforced))
  expect_true(all(diff(enforced$adjusted_value) <= 0))
})
