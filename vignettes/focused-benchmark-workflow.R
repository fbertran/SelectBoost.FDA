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
#     "--n-grid=50,100",
#     "--grid-length-grid=30,75",
#     "--snr-grid=0.5,1,2,4",
#     "--checkpoint-every=1",
#     paste0("--output-dir=", file.path(tempdir(), "selectboost_fda_focused_benchmark"))
#   )
# )

## ----eval = FALSE-------------------------------------------------------------
# system2(
#   file.path(R.home("bin"), "Rscript"),
#   c(
#     "tools/run_focused_benchmark.R",
#     "--medium",
#     "--seed=20260616",
#     "--representation-grid=grid,bspline",
#     "--scenario-grid=localized_dense,confounded_blocks,smooth_sparse",
#     "--n-grid=50,100",
#     "--grid-length-grid=30,75",
#     "--snr-grid=0.5,1,2,4",
#     "--q-grid=0.5,0.632,0.8",
#     "--c0-grid=0.9,0.7,0.5,0.3",
#     "--association-grid=correlation,neighborhood,hybrid,interval",
#     "--bandwidth-grid=4,8",
#     "--checkpoint-every=100",
#     "--assessment-summary",
#     "--save-surfaces",
#     "--surface-use-main-settings",
#     "--save-association-diagnostics",
#     "--bootstrap-reps=2000",
#     paste0("--output-dir=", file.path(tempdir(), "selectboost_fda_focused_campaign"))
#   )
# )

## ----eval = FALSE-------------------------------------------------------------
# system2(
#   file.path(R.home("bin"), "Rscript"),
#   c(
#     "tools/run_focused_benchmark.R",
#     "--medium",
#     "--seed=20260616",
#     paste0("--output-dir=", file.path(tempdir(), "selectboost_fda_focused_n30"))
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

