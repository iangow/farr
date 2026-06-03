# RUSBoost for two-class problems

RUSBoost for two-class problems.

## Usage

``` r
rusboost(formula, df, size, ir = 1, learn_rate = 1, rus = TRUE, control)
```

## Arguments

- formula:

  A formula specify predictors and target variable. Target variable
  should be a factor of 0 and 1. Predictors can be either numerical and
  categorical.

- df:

  A df frame used for training the model, i.e. training set.

- size:

  Ensemble size, i.e. number of weak learners in the ensemble model

- ir:

  Imbalance ratio. Specifies how many times the under-sampled majority
  instances are over minority instances.

- learn_rate:

  Default of 1.

- rus:

  TRUE for random undersampling; FALSE for AdaBoost with full sample

- control:

  Control object passed onto rpart function.

## Value

rusboost object
