## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(collapse = TRUE, comment = "#>")

## ----eval = FALSE-------------------------------------------------------------
# system2(
#   file.path(R.home("bin"), "Rscript"),
#   c(
#     "tools/run_focused_benchmark.R",
#     "--quick",
#     "--n-replicates=1",
#     "--seed=20260616",
#     paste0("--output-dir=", file.path(tempdir(), "selectboost_fda_focused_benchmark"))
#   )
# )

## -----------------------------------------------------------------------------
library(SelectBoost.FDA)

report_summary_table()
report_method_table()
report_formula_blocks()[c("selection_surface", "precision_recall")]

## -----------------------------------------------------------------------------
report_benchmark_table(top_n = 5)

## -----------------------------------------------------------------------------
metrics <- data.frame(
  scenario = "localized_dense",
  representation = "grid",
  family = "gaussian",
  method = c("selectboost", "plain_selectboost"),
  level = "feature",
  precision = c(0.8, 0.6),
  recall = c(0.7, 0.6),
  f1 = c(0.746, 0.6),
  jaccard = c(0.59, 0.43),
  selection_rate = c(0.2, 0.3),
  stringsAsFactors = FALSE
)

as_benchmark_summary_data(metrics)

