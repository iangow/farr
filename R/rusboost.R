# Random under-sampling
rus <- function(y_train, wts, ir = 1) {
  # ir = Imbalance Ratio. (how many times majority instances are over minority instances)

  tab <- table(y_train)
  maj_class = ifelse(tab[2] >= tab[1], names(tab[2]), names(tab[1]))

  p <- which(y_train != maj_class)
  n <- sample(which(y_train == maj_class), length(p) * ir, replace = TRUE)
  rows <- c(p, n)
  w <- wts[rows]/sum(wts[rows])

  sample(rows, length(rows), replace = TRUE, prob = w)
}

w.update <- function(prob, prediction, actual, w, smooth, learn_rate = 1) {

  # Pseudo-loss calculation for AdaBoost.M2
  f <- which(prediction != actual)
  diff <- ifelse(actual[f] == "1", prob[f, "0"], prob[f, "1"])
  err <- sum( w[f] * diff)

  # Update weights with prediction smoothing, dealing with err == 0
  alpha <- learn_rate * (err + smooth) / (1 - err + smooth)
  w[f] <- rep(1/length(f), length(f)) * alpha^(1 - diff)

  # Scale weights
  w <- w / sum(w)

  return(list(w = w, alpha = alpha))
}

#' RUSBoost for two-class problems
#'
#' @param formula A formula specify predictors and target variable. Target variable should be a factor of 0 and 1. Predictors can be either numerical and categorical.
#' @param data A data frame used for training the model, i.e. training set.
#' @param size Ensemble size, i.e. number of weak learners in the ensemble model
#' @param ir Imbalance ratio. Specifies how many times the under-sampled majority instances are over minority instances.
#' @param learn_rate Learning rate.
#' @param control Control object passed onto rpart function.
#'
#' @return rusboost object
#' @importFrom stats predict
#' @export
#'
rusboost <- function(formula, data, size, ir = 1, learn_rate = 1,
                     control) {
    target <- as.character(stats::as.formula(formula)[[2]])
    weakLearners <- list()
    alpha <- 0
    w <- rep(1/nrow(data), nrow(data))
    label <- data[, target]

    for (i in 1:size) {

        # Get training sample
        rows_final <- rus(data[[target]], w, ir)

        # Fit model
        fm <- rpart::rpart(formula, data = data[rows_final, ],
                           control = control)
        prob <- predict(fm, data, type = "prob")
        pred <- predict(fm, data, type = "class")

        # Get updated weights
        new <- w.update(prob = prob, prediction = pred, learn_rate = learn_rate,
                          actual = label, w = w, smooth = 1/length(rows_final))
        w <- new[["w"]]
        weakLearners[[i]] <- fm
        alpha[i] <- new[["alpha"]]
    }
    result <- list(weakLearners = weakLearners, alpha = alpha)
    attr(result, "class") <- "rusboost"
    return(result)
}

#' @method predict rusboost
#' @export
predict.rusboost <- function(object, newdata, type = "prob", ...) {
  models <- object[["weakLearners"]]
  alpha <- object[["alpha"]]

  a <- log(1/alpha) / sum(log(1/alpha)) # normalize alpha values

  predict_pos <- function(model) {
    predict(model, newdata, type = "prob")[, "1"]
  }

  probs <- lapply(models, predict_pos)

  # Weight models
  prob <- rowSums(mapply("*", probs, a))

  if (type == "class") {
    pred <- as.factor(as.integer(prob > 0.5))
    return(pred)
  }
  else if (type == "prob") {
    return(prob)
  }
}
