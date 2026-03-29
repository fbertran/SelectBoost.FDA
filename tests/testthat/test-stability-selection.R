test_that("grouped stability selection prefers the active functional block", {
  data <- make_example_fda_data()

  res <- stability_selection_fda(
    x = data$x,
    y = data$y,
    selector = "grpreg",
    B = 20,
    seed = 99,
    cutoff = 0.6
  )

  expect_s3_class(res, "fda_stability_selection")
  expect_true(res$group_frequency["signal"] > res$group_frequency["noise"])
  expect_true("signal" %in% res$selected_groups)
})

test_that("interval stability selection returns region-level summaries", {
  data <- make_example_fda_data()

  res <- interval_stability_selection(
    x = data$x,
    y = data$y,
    width = 2,
    selector = "glmnet",
    B = 15,
    seed = 42,
    cutoff = 0.5
  )

  expect_s3_class(res, "fda_interval_stability_selection")
  expect_equal(nrow(res$interval_table), 4)
  expect_true(res$group_frequency["signal[1:2]"] > res$group_frequency["noise[1:2]"])

  interval_map <- selection_map(res, level = "group")
  expect_true(all(c("interval_start", "interval_end", "interval_label", "group_frequency") %in% names(interval_map)))
  expect_true(any(interval_map$interval_label == "signal[1:2]"))
})

test_that("fdboost adapter fails clearly when FDboost is unavailable", {
  if (requireNamespace("FDboost", quietly = TRUE)) {
    skip("FDboost is installed; this test targets the fallback path.")
  }

  expect_error(
    fdboost_stability_selection(structure(list(), class = "FDboost")),
    "Package `FDboost` is required"
  )
})
