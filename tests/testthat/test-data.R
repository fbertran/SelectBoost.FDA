test_that("package datasets support end-to-end design construction", {
  data("spectra_example", package = "SelectBoost.FDA")
  data("motion_example", package = "SelectBoost.FDA")

  spectra_design <- fda_design(
    response = spectra_example$response,
    predictors = list(
      signal = fda_grid(spectra_example$predictors$signal, argvals = spectra_example$grid, name = "signal"),
      nuisance = fda_grid(spectra_example$predictors$nuisance, argvals = spectra_example$grid, name = "nuisance")
    ),
    scalar_covariates = spectra_example$scalar_covariates,
    scalar_transform = fda_standardize(),
    family = "gaussian"
  )

  motion_design <- fda_design(
    response = motion_example$response,
    predictors = list(
      signal = fda_grid(motion_example$predictors$signal, argvals = motion_example$grid, name = "signal"),
      nuisance = fda_grid(motion_example$predictors$nuisance, argvals = motion_example$grid, name = "nuisance")
    ),
    scalar_covariates = motion_example$scalar_covariates,
    transforms = list(
      signal = fda_fpca(n_components = 3),
      nuisance = fda_bspline(df = 5)
    ),
    scalar_transform = fda_standardize(),
    family = "gaussian"
  )

  expect_s3_class(spectra_design, "fda_design")
  expect_s3_class(motion_design, "fda_design")
  expect_true(any(selection_map(motion_design)$basis_type == "fpca"))
  expect_true(any(selection_map(motion_design)$basis_type == "spline"))
})

test_that("saved benchmark summaries are shipped with the package", {
  benchmark_dir <- system.file("extdata", "benchmarks", package = "SelectBoost.FDA")
  top_settings_path <- file.path(benchmark_dir, "selectboost_sensitivity_top_settings.csv")
  performance_path <- file.path(benchmark_dir, "selectboost_sensitivity_feature_performance.csv")

  expect_true(nzchar(benchmark_dir))
  expect_true(file.exists(top_settings_path))
  expect_true(file.exists(performance_path))

  top_settings <- utils::read.csv(top_settings_path, stringsAsFactors = FALSE)
  performance <- utils::read.csv(performance_path, stringsAsFactors = FALSE)

  expect_true(all(c(
    "scenario",
    "association_method",
    "selectboost_f1_mean",
    "plain_selectboost_f1_mean",
    "delta_mean",
    "win_rate"
  ) %in% names(top_settings)))
  expect_true(all(c("method", "f1_mean") %in% names(performance)))
})
