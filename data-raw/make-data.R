make_functional_dataset <- function(n,
                                    seed,
                                    grid,
                                    response_noise = 0.45,
                                    age_mean = 50,
                                    age_sd = 7) {
  set.seed(seed)
  latent_signal <- rnorm(n)
  latent_noise <- rnorm(n)
  age <- rnorm(n, mean = age_mean, sd = age_sd)
  treatment <- rbinom(n, size = 1, prob = 0.45)

  signal <- outer(latent_signal, sin(2 * pi * grid)) +
    outer(rnorm(n, sd = 0.3), cos(pi * grid)) +
    matrix(rnorm(n * length(grid), sd = 0.12), nrow = n)

  nuisance <- outer(latent_noise, exp(-((grid - 0.65) / 0.16)^2)) +
    matrix(rnorm(n * length(grid), sd = 0.14), nrow = n)

  response <- 1.8 * signal[, max(2, floor(length(grid) * 0.28))] -
    1.4 * signal[, max(3, floor(length(grid) * 0.67))] +
    0.05 * age - 0.6 * treatment +
    rnorm(n, sd = response_noise)

  list(
    grid = grid,
    response = response,
    predictors = list(signal = signal, nuisance = nuisance),
    scalar_covariates = data.frame(age = age, treatment = treatment)
  )
}

spectra_example <- make_functional_dataset(
  n = 80,
  seed = 101,
  grid = seq(1100, 2500, length.out = 40),
  response_noise = 0.4,
  age_mean = 55,
  age_sd = 6
)

motion_example <- make_functional_dataset(
  n = 70,
  seed = 202,
  grid = seq(0, 1, length.out = 30),
  response_noise = 0.5,
  age_mean = 48,
  age_sd = 8
)

dir.create("data", showWarnings = FALSE)
unlink("data/functional_examples.rda")
save(
  spectra_example,
  file = "data/spectra_example.rda",
  compress = "bzip2",
  version = 2
)
save(
  motion_example,
  file = "data/motion_example.rda",
  compress = "bzip2",
  version = 2
)
