#' Generate simulated data as described in Gow, Ormazabal and Taylor (2010).
#'
#' Function to generate simulated panel data as described in Gow, Ormazabal and
#' Taylor (2010).
#'
#' @param N Number of firms
#' @param T Number of years
#' @param Xvol Cross-sectional correlation of *X*
#' @param Evol Cross-sectional correlation of errors
#' @param rho_X Autocorrelation coefficient for firm-effect portion of *X*
#' @param rho_E Autocorrelation coefficient for firm-effect portion of epsilon
#'
#' @return tibble
#' @export
#' @importFrom tibble tibble
#' @examples
#' set.seed(2021)
#' test <- get_got_data(N = 500, T = 10, Xvol = 0.75,
#'                      Evol = 0.75, rho_X = 0.5, rho_E = 0.5)
#' test
get_got_data <- function(N = 400, T = 20, Xvol, Evol, rho_X, rho_E) {

  # Basic assumptions about stochastic processes
  beta <- 1  # y = x + epsilon
  Xbar <- 0  # E[X] = 0

  # Distributional assumptions
  sigma_X <- 1   # Standard deviation of the independent variable
  sigma_E <- 2   # Standard deviation of errors

  # Generate X values ----
  sigma_mu_T <- sqrt(Xvol)*sigma_X
  sigma_mu_F <- sqrt(sigma_X^2 - sigma_mu_T^2)

  # Generate YEAR effects for X
  mu_T <- t(matrix(stats::rnorm(T) * sigma_mu_T, ncol = 1) %*% rep(1,N))

  # Generate FIRM effects for X
  v <- matrix(stats::rnorm(N*T), nrow=N) * sqrt(1-rho_X^2) * sigma_mu_F

  mu_F <- matrix(nrow = N, ncol = T)
  mu_F[ , 1] <- v[, 1]
  for (t in 2:T) {
    mu_F[, t] <- mu_F[ , t-1] * rho_X + v[ ,t]
  }

  X <- Xbar + mu_T + mu_F;

  ##########
  # GENERATE epsilon VALUES
  ##########
  sigma_gamma_T <- sqrt(Evol)*sigma_E;
  sigma_gamma_F <- sqrt(sigma_E^2 - sigma_gamma_T^2);

  # Generate YEAR effects for epsilon
  gamma_T <- t(matrix(stats::rnorm(T) * sigma_gamma_T, ncol=1) %*% matrix(rep(1, N), nrow=1))

  # Generate FIRM effects for epsilon
  nu <- matrix(stats::rnorm(N*T), nrow=N) * sqrt(1-rho_E^2)*sigma_gamma_F;

  gamma_F <- matrix(nrow = N, ncol = T)
  gamma_F[ ,1] <- nu[ ,1]
  for (t in 2:T) {
    gamma_F[ , t] <- gamma_F[ , t-1] * rho_X + nu[ ,t]
  }

  epsilon <- gamma_T + gamma_F;

  # Generate FIRM variables
  firm <- matrix(1:N, ncol = 1) %*% matrix(rep(1, T), nrow=1)

  # Generate YEAR variables
  year <- t(matrix(1:T, ncol = 1) %*% matrix(rep(1, N), nrow=1))

  # Calculate y using population model
  y <- beta * X + epsilon;

  # Return data, converting matrices into vectors.
  tibble::tibble(y = as.vector(y),
                 x = as.vector(X),
                 firm = as.vector(as.integer(firm)),
                 year = as.vector(as.integer(year)))
}
