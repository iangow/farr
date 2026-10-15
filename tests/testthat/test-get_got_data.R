set.seed(2021)

temp <- get_got_data(N = 500, T = 10, Xvol = 0.75,
                     Evol = 0.75, rho_X = 0.5, rho_E = 0.5)

test_that("get_got_data works", {
  expect_equal(length(unique(temp$firm)), 500)
})

test_that("firm-specific errors use rho_E independently of rho_X", {
  N <- 3
  T <- 4

  # Recover the four sets of innovations using the function's documented
  # variances, then solve the AR(1) processes with an independent filter.
  set.seed(42)
  year_x <- rep(stats::rnorm(T) * 0.5, each = N)
  firm_x <- matrix(stats::rnorm(N * T), nrow = N) * sqrt(0.75)
  year_e <- rep(stats::rnorm(T) * 1.2, each = N)
  firm_e <- matrix(stats::rnorm(N * T), nrow = N) * 1.6

  filter_firms <- function(innovations, rho) {
    t(apply(innovations * sqrt(1 - rho^2), 1, function(x) {
      as.numeric(stats::filter(x, filter = rho, method = "recursive", init = 0))
    }))
  }

  for (rho in list(c(0, 0.9), c(0.25, -0.5), c(-0.6, 0))) {
    rho_x <- rho[1]
    rho_e <- rho[2]
    set.seed(42)
    actual <- get_got_data(N = N, T = T, Xvol = 0.25, Evol = 0.36,
                           rho_X = rho_x, rho_E = rho_e)

    expected_x <- year_x + as.vector(filter_firms(firm_x, rho_x))
    expected_e <- year_e + as.vector(filter_firms(firm_e, rho_e))
    expect_equal(actual$x, expected_x)
    expect_equal(actual$y - actual$x, expected_e)
    expect_identical(actual$firm, rep(seq_len(N), T))
    expect_identical(actual$year, rep(seq_len(T), each = N))

    # Changing error persistence must leave the predictor path unchanged.
    set.seed(42)
    same_rho <- get_got_data(N = N, T = T, Xvol = 0.25, Evol = 0.36,
                             rho_X = rho_x, rho_E = rho_x)
    expect_identical(actual$x, same_rho$x)
  }
})

test_that("equal persistence parameters retain existing seeded output", {
  # Captured before the #29 correction, using the same seed and parameters.
  set.seed(42)
  actual <- get_got_data(N = 2, T = 3, Xvol = 0.25, Evol = 0.36,
                         rho_X = 0.5, rho_E = 0.5)
  expect_equal(actual$x, c(1.16012617729411, 0.988680465929084,
                          -0.124618995906267, 1.00289303355903,
                          0.189434971754735, 2.33800305070499))
  expect_equal(actual$y, c(-0.839592580738634, 0.527122500100451,
                          0.294258206883555, 3.25678481558517,
                          1.96605385018287, 1.74510901478622))
})
