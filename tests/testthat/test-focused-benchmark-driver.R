test_that("focused benchmark driver writes quick artifacts to tempdir", {
  skip_on_cran()

  output_dir <- file.path(tempdir(), paste0("selectboost-benchmark-", Sys.getpid()))
  script <- file.path(getwd(), "tools", "run_focused_benchmark.R")
  if (!file.exists(script)) {
    script <- file.path(getwd(), "..", "..", "tools", "run_focused_benchmark.R")
  }
  script <- normalizePath(script, mustWork = TRUE)
  result <- system2(
    file.path(R.home("bin"), "Rscript"),
    c(
      script,
      "--quick",
      "--n-replicates=1",
      "--seed=101",
      paste0("--output-dir=", output_dir)
    ),
    stdout = TRUE,
    stderr = TRUE
  )

  expect_equal(attr(result, "status") %||% 0, 0)
  expected <- c(
    "benchmark_raw_metrics.csv",
    "benchmark_summary_by_setting.csv",
    "benchmark_best_settings.csv",
    "benchmark_precision_recall_paths.csv",
    "benchmark_monotonicity_summary.csv",
    "benchmark_runtime_summary.csv",
    "session_info.txt",
    "config.yml"
  )
  expect_true(all(file.exists(file.path(output_dir, expected))))

  metrics <- utils::read.csv(file.path(output_dir, "benchmark_raw_metrics.csv"))
  expect_true(all(c("method", "level", "f1") %in% names(metrics)))
})
