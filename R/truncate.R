#' Truncate a vector.
#'
#' Truncate a vector at prob and 1 - prob.
#' Extreme values are turned in NA values.
#'
#' @param x A vector to be winsorized
#' @param prob Level (two-sided) for winsorization (e.g., 0.01 gives 1% and 99%)
#' @param p_low Optional lower level for winsorization (e.g., 0.01 gives 1%)
#' @param p_high Optional upper level for winsorization (e.g., 0.99 gives 99%)
#'
#' @return vector
#' @export
#' @examples
#' trunced <- truncate(1:100, prob = 0.05)
#' min(trunced, na.rm = TRUE)
#' max(trunced, na.rm = TRUE)
truncate <- function(x, prob = 0.01, p_low = prob, p_high = 1 - prob) {
    cuts <- stats::quantile(x, probs = c(p_low, p_high), type = 2, na.rm = TRUE)
    x[x < cuts[1]] <- NA
    x[x > cuts[2]] <- NA
    x
}
