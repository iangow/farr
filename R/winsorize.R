#' Winsorize a vector.
#'
#' Winsorize a vector at prob and 1 - prob.
#'
#' @param x A vector to be winsorized
#' @param prob Level (two-sided) for winsorization (e.g., 0.01 gives 1% and 99%)
#' @param p_low Optional lower level for winsorization (e.g., 0.01 gives 1%)
#' @param p_high Optional upper level for winsorization (e.g., 0.99 gives 99%)
#'
#' @return vector
#' @export
#' @examples
#' winsorized <- winsorize(1:100, prob = 0.05)
#' min(winsorized, na.rm = TRUE)
#' max(winsorized, na.rm = TRUE)
winsorize <- function(x, prob = 0.01, p_low = prob, p_high = 1 - prob) {
    cuts <- stats::quantile(x, probs = c(p_low, p_high), type = 2, na.rm = TRUE)
    x[x < cuts[1]] <- cuts[1]
    x[x > cuts[2]] <- cuts[2]
    x
}
