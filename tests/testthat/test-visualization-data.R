test_that("selection surface extraction returns documented columns", {
  surface <- data.frame(
    feature = c("x1", "x1", "x2", "x2"),
    predictor = "signal",
    level = "feature",
    q = c(0.5, 0.5, 0.5, 0.5),
    c0 = c(0.2, 0.6, 0.2, 0.6),
    selection = c(0.8, 0.4, 0.1, 0.2),
    stringsAsFactors = FALSE
  )

  out <- as_selection_surface_data(surface)

  expect_true(all(selection_surface_columns() %in% names(out)))
  expect_equal(nrow(out), 4)
  expect_type(out$selected, "logical")
})

test_that("association heatmap extraction preserves matrix symmetry", {
  data <- make_example_fda_data(n = 16)
  heatmap <- as_association_heatmap_data(
    data$x,
    method = "neighborhood",
    within_blocks = TRUE,
    bandwidth = 1
  )

  expect_true(all(c("feature_i", "feature_j", "association", "same_block") %in% names(heatmap)))
  reverse <- merge(
    heatmap,
    heatmap,
    by.x = c("feature_i", "feature_j"),
    by.y = c("feature_j", "feature_i"),
    suffixes = c("_ij", "_ji")
  )
  expect_equal(reverse$association_ij, reverse$association_ji)
  expect_true(all(heatmap$association[!heatmap$same_block] == 0))
})

test_that("functional interval map extraction preserves domain boundaries", {
  sim <- simulate_fda_scenario(n = 20, grid_length = 12, include_scalar = FALSE, seed = 10)
  groups <- functional_interval_groups(sim$design, width = 3)
  fit <- stability_selection_fda(
    sim$design,
    selector_fun = function(X, y, groups, family) colMeans(abs(X)) > 0,
    groups = groups,
    B = 2,
    cutoff = 0.5,
    seed = 11
  )
  fit$interval_table <- attr(groups, "interval_table")

  interval_map <- as_functional_interval_map_data(fit)

  expect_true(all(c("interval_label", "domain_start", "domain_end", "selection") %in% names(interval_map)))
  expect_true(nrow(interval_map) > 0)
  expect_true(all(interval_map$interval_start <= interval_map$interval_end))
})

test_that("benchmark summary extraction normalizes expected columns", {
  metrics <- data.frame(
    scenario = "localized_dense",
    representation = "grid",
    family = "gaussian",
    method = c("selectboost", "plain_selectboost"),
    level = "feature",
    precision = c(1, 0.5),
    recall = c(0.5, 0.5),
    f1 = c(2 / 3, 0.5),
    jaccard = c(0.5, 1 / 3),
    selection_rate = c(0.2, 0.3),
    stringsAsFactors = FALSE
  )

  out <- as_benchmark_summary_data(metrics)

  expect_true(all(c("scenario", "method", "f1_mean", "selection_rate_mean") %in% names(out)))
  expect_equal(nrow(out), 2)
})
