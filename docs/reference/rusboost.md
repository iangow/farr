# RUSBoost for two-class problems

RUSBoost for two-class problems.

## Usage

``` r
rusboost(formula, df, size, ir = 1, learn_rate = 1, rus = TRUE, control)

# S3 method for class 'rusboost'
predict(object, newdata, type = "prob", ...)
```

## Arguments

- formula:

  A formula specify predictors and target variable. Target variable
  should be a factor of 0 and 1. Predictors can be either numerical and
  categorical.

- df:

  A df frame used for training the model, i.e. training set.

- size:

  Positive integer giving the maximum number of weak-learner attempts.

- ir:

  Imbalance ratio. Specifies how many times the under-sampled majority
  instances are over minority instances.

- learn_rate:

  Positive finite learning rate. Default of 1.

- rus:

  TRUE for random undersampling; FALSE for AdaBoost with full sample

- control:

  Control object passed onto rpart function.

- object:

  A fitted `rusboost` object.

- newdata:

  A data frame containing the predictors used in training.

- type:

  Prediction type: `"prob"` for the weighted share of positive votes, or
  `"class"` for the sign of the weighted class vote.

- ...:

  Additional arguments; currently unused.

## Value

`rusboost()` returns an object of class `rusboost`, a list containing
fitted trees (`weakLearners`), their voting weights (`alpha`),
observation-weight vectors (`w`), and the training `formula`.
[`predict()`](https://rdrr.io/r/stats/predict.html) returns a numeric
vector of weighted positive-vote shares for `type = "prob"`, or classes
-1 and 1 (0 for a tied vote) for `type = "class"`.

## Details

A learner that correctly classifies every observation in the full
training data stops training successfully. It replaces any earlier
learners and is returned as the sole predictive learner with voting
weight 1, a finite representation of its limiting vote. Its
observation-weight vector is the normalized vector used for that
attempt.

Learners with weighted error at least one half receive no vote. AdaBoost
(`rus = FALSE`) stops at such a learner; RUSBoost skips it and tries
another sample, up to `size` attempts. Training raises an error if no
usable learner is found. The response must contain two nonmissing
classes, including class 1.

## Examples

``` r
training <- data.frame(x = 1:8, y = factor(c(rep(0, 4), rep(1, 4))))
control <- rpart::rpart.control(minsplit = 2, minbucket = 1, cp = 0, xval = 0)
fit <- rusboost(y ~ x, training, size = 3, rus = FALSE, control = control)
predict(fit, training, type = "prob")
#> [1] 0 0 0 0 1 1 1 1
predict(fit, training, type = "class")
#> [1] -1 -1 -1 -1  1  1  1  1
```
