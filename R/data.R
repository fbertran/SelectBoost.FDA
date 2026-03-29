#' Spectroscopy-Style Functional Example
#'
#' Simulated dense spectra with one signal block, one nuisance block, and two
#' scalar covariates. The response is continuous and depends on localized
#' regions of the signal spectrum plus the scalar covariates.
#'
#' @format A list with four components:
#' \describe{
#'   \item{grid}{Numeric vector of wavelength locations.}
#'   \item{response}{Numeric response vector.}
#'   \item{predictors}{Named list of functional predictor matrices.}
#'   \item{scalar_covariates}{Data frame with scalar covariates.}
#' }
#' @source Simulated for package examples.
"spectra_example"

#' Smooth Trajectory Functional Example
#'
#' Simulated smooth trajectories used to demonstrate spline-basis and FPCA
#' preprocessing from raw curves.
#'
#' @format A list with four components:
#' \describe{
#'   \item{grid}{Numeric vector of observation times.}
#'   \item{response}{Numeric response vector.}
#'   \item{predictors}{Named list of functional predictor matrices.}
#'   \item{scalar_covariates}{Data frame with scalar covariates.}
#' }
#' @source Simulated for package examples.
"motion_example"
