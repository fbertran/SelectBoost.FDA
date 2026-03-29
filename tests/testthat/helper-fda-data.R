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
