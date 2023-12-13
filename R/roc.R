#'  A function returning data for a ROC plot.
#'
#'  A function returning data for a ROC plot.
#'
#' @param scores Probability that response is true or 1.
#' @param response Responses coded as logical or 0-or-1.
#'
#' @return tbl_df
#' @export
roc <- function(scores, response) {

  thresholds <- seq(0, 1, 0.00025)
  thresholds[1] <- -Inf
  thresholds[length(thresholds)] <- Inf

  fn_fun <- function(threshold) {
      sum(response[scores < threshold])
  }

  tn_fun <- function(threshold) {
      sum(!response[scores < threshold])
  }

  n_pos <- sum(response)
  n_neg <- sum(!response)

  fn <- unlist(lapply(thresholds, fn_fun))
  tn <- unlist(lapply(thresholds, tn_fun))

  tpr <- 1 - fn/n_pos
  fpr <- 1 - tn/n_neg
  dplyr::tibble(fpr, tpr) %>% dplyr::distinct()
}

#'  Confusion statistics.
#'
#'  A function returning sensitivity and precision.
#'
#' @param scores Probability that response is true or 1.
#' @param response Responses coded as logical or 0-or-1.
#' @param predicted Predicted value coded as 0-or-1.
#' @param k Percentage to classify as TRUE or 1.
#'
#' @return vector including sensitivity and precision
#' @export
confusion_stats <- function(scores, response, predicted = NULL, k = NULL) {

  # Organize data
  if (is.null(k)) {
    predicted <- as.numeric(scores >= 0.5)
  } else {
    predicted <- as.numeric(scores >= stats::quantile(scores, 1 - k))
  }

  response <- as.integer(response)

  tp <- sum(response & predicted)
  fp <- sum(!response & predicted)
  fn <- sum(response & !predicted)
  tn <- sum(!response & !predicted)
  c(sensitivity = tp/(tp + fn),
    precision = tp/(tp + fp))
}

#'  Calculate metric: NDCG at k
#'
#'  A function returning NDCG-at-k metric.
#'
#' @param scores Probability that response is true or 1.
#' @param response Responses coded as logical or 0-1.
#' @param k Percentage to classify as TRUE or 1.
#'
#' @return vector including sensitivity and precision
#' @export
ndcg <- function(scores, response, k = 0.01) {

  ranks <- sort(scores, index.return = TRUE, decreasing = TRUE)$ix
  response <- as.integer(response)

  kn <- round(length(response)*k)
  kz <- min(kn, sum(response))

  first_best <- c(rep(1, kz), rep(0, kn - kz))

  z <- sum((as.integer(first_best) == 1)/log(1:kn + 1, 2))
  dcg_at_k <- sum((response[ranks][1:kn] == 1)/log(1:kn + 1, 2))

  res <- ifelse(z > 0, dcg_at_k/z, 0)
  names(res) <- paste0("ndcg_",k)
  res
}

#'  Area under curve
#'
#'  A function returning AUC.
#'
#' @param scores Probability that response is true or 1.
#' @param response Responses coded as logical or 0-or-1.
#'
#' @return vector including AUC
#' @export
#' @source \url{https://blog.mbq.me/augh-roc/}
#' @source \url{https://stackoverflow.com/questions/4903092/calculate-auc-in-r}
auc <- function(scores, response) {
  response <- as.integer(response)

  n_neg <- sum(!response)
  n_pos <- sum(response)
  U  <- sum(rank(scores)[!response]) - n_neg * (n_neg + 1) / 2

  return(c(auc = 1 - U / n_neg / n_pos))
}
