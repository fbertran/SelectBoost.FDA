test_that("report extractors return stable tables and formulas", {
  summary_table <- report_summary_table()
  method_table <- report_method_table()
  formulas <- report_formula_blocks()

  expect_true(all(c("Component", "Role", "Output") %in% names(summary_table)))
  expect_true(all(c("Method", "Perturbation", "Group structure", "Output", "Best suited for") %in% names(method_table)))
  expect_true(is.list(formulas))
  expect_true(all(vapply(formulas, is.character, logical(1))))
  expect_true("selection_surface" %in% names(formulas))
})

test_that("report benchmark table normalizes benchmark rows", {
  rows <- data.frame(
    scenario = "confounded_blocks",
    association_method = "hybrid",
    bandwidth = 4,
    selectboost_f1_mean = 0.7,
    plain_selectboost_f1_mean = 0.5,
    delta_mean = 0.2,
    win_rate = 1,
    stringsAsFactors = FALSE
  )

  out <- report_benchmark_table(rows)

  expect_equal(names(out), c("Scenario", "Association", "Bandwidth", "F1 FDA-aware", "F1 plain", "Delta", "Win rate"))
  expect_equal(out$Delta, 0.2)
})
