test_that("precision-recall paths handle empty and perfect selections", {
  surface <- data.frame(
    feature = c("a", "b", "c"),
    predictor = "signal",
    level = "feature",
    c0 = 0.5,
    selection = c(1, 0, 0),
    stringsAsFactors = FALSE
  )
  truth <- list(
    active_features = "a",
    feature_universe = c("a", "b", "c")
  )

  pr <- precision_recall_curve_fda(
    surface,
    truth = truth,
    level = "feature",
    threshold_grid = c(0, 0.5, 1.1)
  )

  expect_true(all(c("precision", "recall", "f1", "jaccard") %in% names(pr)))
  expect_equal(pr$f1[pr$threshold == 0.5], 1)
  expect_true(is.na(pr$precision[pr$threshold == 1.1]))
})

test_that("best threshold summaries choose maximum F1", {
  pr <- data.frame(
    method = "selectboost",
    level = "feature",
    threshold = c(0, 0.5, 0.9),
    precision = c(0.5, 1, 1),
    recall = c(1, 1, 0.5),
    f1 = c(2 / 3, 1, 2 / 3),
    jaccard = c(0.5, 1, 0.5),
    selection_rate = c(1, 0.5, 0.25),
    stringsAsFactors = FALSE
  )

  best <- best_threshold_fda(pr, metric = "f1")
  summary <- summarise_precision_recall_fda(pr)

  expect_equal(best$threshold, 0.5)
  expect_equal(summary$best_threshold, 0.5)
  expect_equal(summary$f1, 1)
})
