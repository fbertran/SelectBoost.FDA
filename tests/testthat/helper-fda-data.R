make_example_fda_data <- function(n = 80) {
  set.seed(123)
  z1 <- rnorm(n)
  z2 <- rnorm(n)

  signal <- cbind(
    z1 + rnorm(n, sd = 0.15),
    z1 + rnorm(n, sd = 0.15),
    z1 + rnorm(n, sd = 0.15)
  )
  noise <- cbind(
    z2 + rnorm(n, sd = 0.15),
    z2 + rnorm(n, sd = 0.15),
    z2 + rnorm(n, sd = 0.15)
  )
  y <- 1.5 * signal[, 1] - 1.25 * signal[, 2] + rnorm(n, sd = 0.4)

  list(x = list(signal = signal, noise = noise), y = y)
}

make_preprocess_example <- function(n = 80, seed = 2026) {
  set.seed(seed)
  grid <- seq(0, 1, length.out = 30)
  latent_signal <- rnorm(n)
  latent_noise <- rnorm(n)
  age <- rnorm(n, mean = 50, sd = 7)
  treatment <- rbinom(n, size = 1, prob = 0.45)

  signal <- outer(latent_signal, sin(2 * pi * grid)) +
    outer(rnorm(n, sd = 0.3), cos(pi * grid)) +
    matrix(rnorm(n * length(grid), sd = 0.12), nrow = n)

  nuisance <- outer(latent_noise, exp(-((grid - 0.65) / 0.16)^2)) +
    matrix(rnorm(n * length(grid), sd = 0.14), nrow = n)

  y <- 1.8 * signal[, 8] - 1.4 * signal[, 20] + 0.05 * age - 0.6 * treatment +
    rnorm(n, sd = 0.45)

  list(
    grid = grid,
    predictors = list(signal = signal, nuisance = nuisance),
    scalar_covariates = data.frame(age = age, treatment = treatment),
    y = y
  )
}
