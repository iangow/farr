make_prediction_ensemble <- function(alpha = c(0.2, 0.3, 0.5)) {
  control <- rpart::rpart.control(minsplit = 2, minbucket = 1, cp = 0, xval = 0)
  positive <- rpart::rpart(
    y ~ x, data = data.frame(x = 1:4, y = factor(c("1", "1", "1", "-1"))),
    method = "class", control = control
  )
  mixed <- rpart::rpart(
    y ~ x, data = data.frame(x = 1:4, y = factor(c("-1", "-1", "1", "1"))),
    method = "class", control = control
  )
  structure(list(weakLearners = list(positive, mixed, positive), alpha = alpha),
            class = "rusboost")
}

test_that("probabilities apply unequal weights to weak learner columns", {
  model <- make_prediction_ensemble()
  expect_equal(predict(model, data.frame(x = 1:3)), c(0.7, 0.7, 1))

  # A rectangular matrix, zero weight, and an all-negative vote row.
  model$alpha <- c(0.2, 0, 0.5)
  expect_equal(predict(model, data.frame(x = c(1:4, 1))), c(1, 1, 1, 0, 1))
  expect_equal(predict(make_prediction_ensemble(c(1, 1, 1)),
                       data.frame(x = 1:4)), c(2 / 3, 2 / 3, 1, 1 / 3))
})

test_that("predictions preserve row order and do not depend on batch size", {
  model <- make_prediction_ensemble()
  data <- data.frame(x = c(1:4, 1, 3, 2))
  expected <- c(0.7, 0.7, 1, 0.3, 0.7, 1, 0.7)
  permutation <- c(3, 7, 1, 4, 6, 2, 5)

  expect_equal(predict(model, data), expected)
  expect_equal(predict(model, data[permutation, , drop = FALSE]),
               expected[permutation])
  batches <- list(1, 2:3, 4:7)
  batched <- unlist(lapply(batches, function(i) predict(model, data[i, , drop = FALSE])),
                    use.names = FALSE)
  expect_equal(batched, expected)
  expect_true(all(batched >= 0 & batched <= 1))
})

test_that("one observation and one weak learner retain matrix dimensions", {
  model <- make_prediction_ensemble()
  expect_equal(predict(model, data.frame(x = 1)), 0.7)
  expect_equal(unname(predict(model, data.frame(x = 1), type = "class")), 1)

  model$weakLearners <- model$weakLearners[2]
  model$alpha <- 0.3
  expect_equal(predict(model, data.frame(x = 1:4)), c(0, 0, 1, 1))
  expect_equal(predict(model, data.frame(x = 3)), 1)
  expect_equal(unname(predict(model, data.frame(x = 1:4), type = "class")),
               c(-1, -1, 1, 1))
})

test_that("class predictions still use the weighted signed vote", {
  model <- make_prediction_ensemble()
  expect_equal(unname(predict(model, data.frame(x = 1:4), type = "class")),
               c(1, 1, 1, -1))
  model$alpha <- c(0.1, 0.8, 0.1)
  expect_equal(unname(predict(model, data.frame(x = 1:4), type = "class")),
               c(-1, -1, 1, 1))
})

test_that("probability weights define a finite nonnegative weighted mean", {
  model <- make_prediction_ensemble()
  for (weights in list(c(-0.2, 0.3, 0.5), c(NA, 0.3, 0.5), c(Inf, 0.3, 0.5),
                       c(NaN, 0.3, 0.5), c(0, 0, 0), c(1, 2),
                       rep(.Machine$double.xmax, 3), c("a", "b", "c"))) {
    model$alpha <- weights
    expect_error(predict(model, data.frame(x = 1:3)),
                 "finite, nonnegative weight")
  }
  model$weakLearners <- list()
  model$alpha <- numeric()
  expect_error(predict(model, data.frame(x = 1:3)), "positive finite total")
})
