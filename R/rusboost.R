#' Random under-sampling function
#' Function to create temporary training dataset using distribution implied
# by weights.
#'
#' @param y_train Data on the target variable.
#' @param weights Weights to be used in sampling data.
#' @param ir Imbalance ratio. Specifies how many times the under-sampled majority instances are over minority instances.
#'
#' @return vector
#'
rus <- function(y_train, w, ir = 1) {

    # Determine the majority class empirically
    tab <- table(y_train)
    maj_class = ifelse(tab[2] >= tab[1], names(tab[2]), names(tab[1]))

    p <- which(y_train != maj_class)
    n <- sample(which(y_train == maj_class), length(p) * ir, replace = TRUE)
    rows <- c(p, n)
    w <- w[rows]/sum(w[rows])

    sample(rows, length(rows), replace = TRUE, prob = w)
}

w.update <- function(prediction, actual, w, smooth, learn_rate = 1) {

    # Pseudo-loss calculation for original AdaBoost
    # p.343 of Efron and Hastie (2016)
    misclass <- as.integer(prediction != actual)
    err <- sum(w * misclass)/sum(w)

    # Update weights with prediction smoothing
    if(err > 0) {
        alpha <- log((1 - err)/err)
    } else {
        alpha <- 0
    }
    w <- pmax(w * exp(alpha * misclass), 1e-8)

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

    # Prepare data
    target <- as.character(stats::as.formula(formula)[[2]])
    data[[target]] <- ifelse
    label <- data[, target]

    # Set up variables
    alpha <- 0
    weakLearners <- list()
    ws <- list()

    # Set initial weights
    w <- rep(1/nrow(data), nrow(data))

    for (i in 1:size) {

        # Get training sample and fit model
        rows_final <- rus(data[[target]], w, ir)
        fm <- rpart::rpart(formula, data = data[rows_final, ],
                           control = control)

        pred <- sign(predict(fm, data))

        # Get updated weights
        new <- w.update(prediction = pred, learn_rate = learn_rate,
                        actual = label, w = w, smooth = 1/length(rows_final))
        w <- new[["w"]]

        # Append model and alpha value to sequence
        weakLearners[[i]] <- fm
        alpha[i] <- new[["alpha"]]
        ws[[i]] <- w
    }
    result <- list(weakLearners = weakLearners, alpha = alpha, w = ws)
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
