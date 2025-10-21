#' Random under-sampling function
#'
#' Function to create temporary training dataset using distribution implied
#' by w.
#'
#' @param y_train df on the target variable.
#' @param ir Imbalance ratio. Specifies how many times the under-sampled majority instances are over minority instances.
#' @details
#' Following MATLAB, function samples observations of the minority class with
#' replacement and observations of the majority class without replacement.
#' @return vector
#'
rus <- function(y_train, ir = 1) {

    # Determine the majority class empirically
    tab <- table(y_train)
    maj_class = ifelse(tab[2] >= tab[1], names(tab[2]), names(tab[1]))

    rows_minor_class <- which(y_train != maj_class)
    p <- sample(rows_minor_class, length(rows_minor_class), replace = TRUE)

    rows_major_class <- which(y_train == maj_class)
    n <- sample(rows_major_class, length(p) * ir, replace = FALSE)

    rows <- c(p, n)
    return(rows)
}

w.update <- function(prediction, response, w, learn_rate) {

    # Pseudo-loss calculation for original AdaBoost
    # p.339 of ESLII
    misclass <- as.integer(prediction != response)
    err <- sum(w * misclass)/sum(w)
    # print(paste("err:", err))
    # Update weights with prediction smoothing
    if (err > 0 && err < 1/2) {
        alpha <- learn_rate * log((1 - err)/err)
    } else {
        alpha <- 0
    }

    w <- w * exp(alpha * misclass)

    # Scale w
    w <- w / sum(w)
    # print(paste("sum(w):", sum(w)))
    return(list(w = w, alpha = alpha, err = err))
}

#' RUSBoost for two-class problems
#'
#' RUSBoost for two-class problems.
#'
#' @param formula A formula specify predictors and target variable. Target variable should be a factor of 0 and 1. Predictors can be either numerical and categorical.
#' @param df A df frame used for training the model, i.e. training set.
#' @param size Ensemble size, i.e. number of weak learners in the ensemble model
#' @param ir Imbalance ratio. Specifies how many times the under-sampled majority instances are over minority instances.
#' @param learn_rate Default of 1.
#' @param rus TRUE for random undersampling; FALSE for AdaBoost with full sample
#' @param control Control object passed onto rpart function.
#'
#' @return rusboost object
#' @importFrom stats predict
#' @export
#'
rusboost <- function(formula, df, size, ir = 1, learn_rate = 1, rus = TRUE, control) {

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

    # Set initial w
    # df$wt <- rep(1/nrow(df), nrow(df))
    df$wt <- rep(1/nrow(df), nrow(df))

    for (i in 1:size) {

        # Get training sample and fit model
        if (rus) {
            rows_final <- rus(df[[target]], ir)
            wts <- df[rows_final, ]$wt
            train_data <- df[rows_final, ]
        } else {
            train_data <- df
            wts <- df$wt
        }

        fm <- rpart::rpart(formula = formula,
                           data = train_data,
                           weights = wts,
                           method = "class",
                           control = control)

        pred <- as.integer(as.character(predict(fm, df, type = "class")))

        # Get updated w
        new <- w.update(prediction = pred, response = label, w = df$wt,
                        learn_rate = learn_rate)

        # If alpha is zero (perhaps because err > 0.5) *and*
        # we're running regular AdaBoost, then stop here.
        # May make sense to continue if using RUSBoost due to randomness of sampling.
        if (new[["alpha"]] == 0 && !rus) break
        df$wt <- new[["w"]]

        # Append model, alpha value, and weight vector to sequence
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
        ifelse(predict(x, newdata, type = "class") == "1", 1, -1)
    }

    c_b <- lapply(models, predict_class)
    g_b <- mapply("*", c_b, alpha)
    # G_b <- rowCumSums(g_b)

    # Weight models
    C_b <- rowSums(g_b)

    if (type == "class") {
        return(sign(C_b))
    } else if (type =="prob") {
        rowSums(ifelse(g_b > 0, 1, 0)*alpha)/sum(alpha)
    }
}

