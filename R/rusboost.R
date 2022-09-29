#' Random under-sampling function
#' Function to create temporary training dataset using distribution implied
# by weights.
#'
#' @param y_train df on the target variable.
#' @param weights Weights to be used in sampling data.
#' @param ir Imbalance ratio. Specifies how many times the under-sampled majority instances are over minority instances.
#'
#' @return vector
#'
rus <- function(y_train, weights, ir = 1) {

    # Determine the majority class empirically
    tab <- table(y_train)
    maj_class = ifelse(tab[2] >= tab[1], names(tab[2]), names(tab[1]))

    p <- which(y_train != maj_class)

    rows_major_class <- which(y_train == maj_class)
    w <- w[rows_major_class]/sum(w[rows_major_class])

    n <- sample(rows_major_class, length(p) * ir, replace = FALSE)
    rows <- c(p, n)
}

w.update <- function(prediction, response, w) {

    # Pseudo-loss calculation for original AdaBoost
    # p.339 of ESLII
    misclass <- as.integer(prediction != response)
    err <- sum(w * misclass)/sum(w)
    # Update weights with prediction smoothing
    if(err > 0) {
        alpha <- log((1 - err)/err)
    } else {
        alpha <- 0
    }
    w <- w * exp(alpha * misclass)

    # Scale weights
    w <- w / sum(w)

    return(list(w = w, alpha = alpha, err = err))
}

#' RUSBoost for two-class problems
#'
#' @param formula A formula specify predictors and target variable. Target variable should be a factor of 0 and 1. Predictors can be either numerical and categorical.
#' @param df A df frame used for training the model, i.e. training set.
#' @param size Ensemble size, i.e. number of weak learners in the ensemble model
#' @param ir Imbalance ratio. Specifies how many times the under-sampled majority instances are over minority instances.
#' @param control Control object passed onto rpart function.
#'
#' @return rusboost object
#' @importFrom stats predict
#' @export
#'
rusboost <- function(formula, df, size, ir = 1, control) {

    formula <- stats::as.formula(formula)
    environment(formula) <- environment()

    # Prepare df
    df <- as.data.frame(df)
    target <- as.character(stats::as.formula(formula)[[2]])
    df[[target]] <- ifelse(df[[target]]=="1", 1, -1)
    label <- df[[target]]

    # Set up variables
    alpha <- 0
    weakLearners <- list()
    ws <- list()

    # Set initial weights
    # df$wt <- rep(1/nrow(df), nrow(df))
    df$wt <- rep(1/nrow(df), nrow(df))
    for (i in 1:size) {

        # Get training sample and fit model
        rows_final <- rus(df[[target]], df$wt, ir)
        wts <- df[rows_final, ]$wt
        fm <- rpart::rpart(formula = formula,
                           data = df[rows_final, ],
                           weights = wts,
                           method = "class",
                           control = control)

        pred <- as.integer(as.character(predict(fm, df, type = "class")))

        # Get updated weights
        new <- w.update(prediction = pred, response = label, w = df$wt)
        if (new[["err"]] > 0.5) break
        df$wt <- new[["w"]]

        # Append model and alpha value to sequence
        weakLearners[[i]] <- fm
        alpha[i] <- new[["alpha"]]
        ws[[i]] <- df$wt
    }
    result <- list(weakLearners = weakLearners, alpha = alpha, w = ws,
                   formula = formula)
    attr(result, "class") <- "rusboost"
    return(result)
}

rowCumSums <- function(x) {
    t(apply(x, MARGIN=1, cumsum))
}

sigmoidal <- function(x) {
    1/(1 + exp(-2 * x))
}

#' @method predict rusboost
#' @export
predict.rusboost <- function(object, newdata, type = "prob", ...) {
    models <- object[["weakLearners"]]
    alpha <- object[["alpha"]]

    predict_class <- function(x) {
        predict(x, newdata, type = "class") == "1"
    }

    c_b <- lapply(models, predict_class)
    g_b <- mapply("*", c_b, alpha)
    # G_b <- rowCumSums(g_b)

    # Weight models
    C_b <- rowSums(g_b)

    if (type == "class") {
        return(sign(C_b))
    }
    else if (type == "prob") {
        return(sigmoidal(C_b))
    }
}

