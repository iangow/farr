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
#' Both classes must be present, with no missing responses. The requested
#' majority sample size must be a positive integer no larger than the majority
#' class; fractional imbalance ratios are allowed if they meet this requirement.
#' @return vector
#'
rus <- function(y_train, ir = 1) {

    # Determine the majority class from the two observed classes.
    tab <- table(y_train)
    tab <- tab[tab > 0]
    if (anyNA(y_train) || length(tab) != 2L) {
        stop("Random undersampling requires two nonempty classes and no missing responses.")
    }
    maj_class <- if (tab[2] >= tab[1]) names(tab)[2] else names(tab)[1]
    rows_minor_class <- which(y_train != maj_class)
    rows_major_class <- which(y_train == maj_class)

    if (!is.numeric(ir) || is.complex(ir) || length(ir) != 1L ||
        !is.finite(ir) || ir <= 0) {
        stop("`ir` must be a positive finite number.")
    }
    n_major <- length(rows_minor_class) * ir
    if (!is.finite(n_major) || n_major < 1 || n_major != floor(n_major) ||
        n_major > length(rows_major_class)) {
        stop("The requested majority sample must be a positive integer no larger ",
             "than the majority class.")
    }

    # Sample positions: sample(5, 1) would draw from 1:5, not just row 5.
    p <- rows_minor_class[sample.int(length(rows_minor_class),
                                     length(rows_minor_class), replace = TRUE)]
    n <- rows_major_class[sample.int(length(rows_major_class), n_major,
                                     replace = FALSE)]

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
#' @param size Positive integer giving the maximum number of weak-learner attempts.
#' @param ir Imbalance ratio. Specifies how many times the under-sampled majority instances are over minority instances.
#' @param learn_rate Positive finite learning rate. Default of 1.
#' @param rus TRUE for random undersampling; FALSE for AdaBoost with full sample
#' @param control Control object passed onto rpart function.
#'
#' @details
#' A learner that correctly classifies every observation in the full training
#' data stops training successfully. It replaces any earlier learners and is
#' returned as the sole predictive learner with voting weight 1, a finite
#' representation of its limiting vote. Its observation-weight vector is the
#' normalized vector used for that attempt.
#'
#' Learners with weighted error at least one half receive no vote. AdaBoost
#' (`rus = FALSE`) stops at such a learner; RUSBoost skips it and tries another
#' sample, up to `size` attempts. Training raises an error if no usable learner
#' is found. The response must contain two nonmissing classes, including class 1.
#' @return `rusboost()` returns an object of class `rusboost`, a list
#'   containing fitted trees (`weakLearners`), their voting weights (`alpha`),
#'   observation-weight vectors (`w`), and the training `formula`.
#'   `predict()` returns a numeric vector of weighted positive-vote shares for
#'   `type = "prob"`, or classes -1 and 1 (0 for a tied vote) for `type = "class"`.
#' @importFrom stats predict
#' @export
#'
#' @examples
#' training <- data.frame(x = 1:8, y = factor(c(rep(0, 4), rep(1, 4))))
#' control <- rpart::rpart.control(minsplit = 2, minbucket = 1, cp = 0, xval = 0)
#' fit <- rusboost(y ~ x, training, size = 3, rus = FALSE, control = control)
#' predict(fit, training, type = "prob")
#' predict(fit, training, type = "class")
rusboost <- function(formula, df, size, ir = 1, learn_rate = 1, rus = TRUE, control) {

    if (!is.numeric(size) || is.complex(size) || length(size) != 1L ||
        !is.finite(size) || size < 1 || size != floor(size)) {
        stop("`size` must be a positive integer.")
    }
    if (!is.numeric(learn_rate) || is.complex(learn_rate) || length(learn_rate) != 1L ||
        !is.finite(learn_rate) || learn_rate <= 0) {
        stop("`learn_rate` must be a positive finite number.")
    }

    formula <- stats::as.formula(formula)
    environment(formula) <- environment()

    # Prepare df
    df <- as.data.frame(df)
    target <- as.character(stats::as.formula(formula)[[2]])
    response <- as.character(df[[target]])
    if (anyNA(response) || length(unique(response)) != 2L || !any(response == "1")) {
        stop("Training response must contain two nonempty classes, including class 1, ",
             "and no missing values.")
    }
    df[[target]] <- ifelse(response == "1", 1, -1)
    label <- df[[target]]

    # Set up variables
    alpha <- numeric()
    weakLearners <- list()
    ws <- list()

    # Set initial w
    # df$wt <- rep(1/nrow(df), nrow(df))
    df$wt <- rep(1/nrow(df), nrow(df))

    for (i in seq_len(size)) {

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

        # A perfect learner on the full data dominates the limiting vote.
        # Check every prediction, not just a potentially zero-weighted error.
        if (all(pred == label)) {
            weakLearners <- list(fm)
            alpha <- 1
            ws <- list(df$wt)
            break
        }

        # Get updated w
        new <- w.update(prediction = pred, response = label, w = df$wt,
                        learn_rate = learn_rate)

        # AdaBoost stops at an unusable learner; RUSBoost can try another sample.
        if (new[["alpha"]] == 0 && !rus) break
        # Preserve normalization even for skipped RUS attempts: tiny changes in
        # observation weights can affect split ties in a later tree.
        df$wt <- new[["w"]]
        if (new[["alpha"]] == 0) next

        # Keep the retained learners and their weights aligned when attempts skip.
        j <- length(weakLearners) + 1L
        weakLearners[[j]] <- fm
        alpha[j] <- new[["alpha"]]
        ws[[j]] <- df$wt
    }
    if (length(weakLearners) == 0L) {
        stop("No usable weak learner was fitted.")
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

#' @rdname rusboost
#' @param object A fitted `rusboost` object.
#' @param newdata A data frame containing the predictors used in training.
#' @param type Prediction type: `"prob"` for the weighted share of positive
#'   votes, or `"class"` for the sign of the weighted class vote.
#' @param ... Additional arguments; currently unused.
#' @method predict rusboost
#' @export
predict.rusboost <- function(object, newdata, type = "prob", ...) {
    models <- object[["weakLearners"]]
    alpha <- object[["alpha"]]

    if (type == "prob" &&
        (!is.numeric(alpha) || is.complex(alpha) || !is.null(dim(alpha)) ||
         length(alpha) != length(models) || any(!is.finite(alpha)) ||
         any(alpha < 0) || !is.finite(sum(alpha)) || sum(alpha) <= 0)) {
        stop("Probability predictions require one finite, nonnegative weight ",
             "per weak learner and a positive finite total weight.")
    }

    predict_class <- function(x) {
        ifelse(predict(x, newdata, type = "class") == "1", 1, -1)
    }

    # Keep observations in rows and weak learners in columns, including when
    # there is only one observation or one weak learner.
    c_b <- do.call(cbind, lapply(models, predict_class))
    g_b <- sweep(c_b, 2, alpha, "*")
    # G_b <- rowCumSums(g_b)

    # Weight models
    C_b <- rowSums(g_b)

    if (type == "class") {
        return(sign(C_b))
    } else if (type =="prob") {
        as.numeric((c_b > 0) %*% alpha) / sum(alpha)
    }
}

