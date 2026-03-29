test_that("selectboost_fda returns feature-by-c0 summaries", {
  data <- make_example_fda_data(n = 60)

  res <- selectboost_fda(
    x = data$x,
    y = data$y,
    mode = "fast",
    selector = "glmnet",
    B = 5,
    steps.seq = c(0.6, 0.2),
    c0lim = FALSE
  )

  expect_s3_class(res, "selectboost_fda_result")
  expect_equal(nrow(res$feature_selection), 6)
  expect_equal(rownames(res$feature_selection), colnames(as_functional_matrix(data$x)$x))
  expect_true(ncol(res$feature_selection) >= 2)
})
