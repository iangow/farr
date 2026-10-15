boost_control <- function() {
  rpart::rpart.control(minsplit = 2, minbucket = 1, cp = 0, xval = 0)
}

boost_training_fixture <- function() {
  data <- data.frame(x = 1:8, y = factor(rep(c(0, 1), each = 4)))
  signed <- data
  signed$y <- factor(rep(c(-1, 1), each = 4))
  perfect <- rpart::rpart(y ~ x, signed, method = "class", control = boost_control())
  signed$y <- factor(c(rep(-1, 6), rep(1, 2)))
  imperfect <- rpart::rpart(y ~ x, signed, method = "class", control = boost_control())
  signed$y <- factor(rep(c(1, -1), each = 4))
  bad <- rpart::rpart(y ~ x, signed, method = "class", control = boost_control())
  list(data = data, perfect = perfect, imperfect = imperfect, bad = bad)
}

for (use_rus in c(FALSE, TRUE)) {
  label <- if (use_rus) "RUSBoost" else "AdaBoost"

  test_that(paste(label, "retains a perfect first learner with finite weight"), {
    # Repeated predictor values make the classes separable under every RUS draw.
    data <- data.frame(x = rep(1:2, each = 4), y = factor(rep(c(0, 1), each = 4)))
    set.seed(32)
    fit <- rusboost(y ~ x, data, size = 3, rus = use_rus, control = boost_control())
    expect_length(fit$weakLearners, 1)
    expect_equal(fit$alpha, 1)
    expect_length(fit$w, 1)
    expect_equal(fit$w[[1]], rep(1 / 8, 8))
    expect_equal(predict(fit, data), rep(c(0, 1), each = 4))
    expect_equal(unname(predict(fit, data, type = "class")), rep(c(-1, 1), each = 4))
  })

  test_that(paste(label, "replaces previous learners when a later learner is perfect"), {
    fixture <- boost_training_fixture()
    calls <- 0L
    local_mocked_bindings(rpart = function(...) {
      calls <<- calls + 1L
      if (calls == 1L) fixture$imperfect else fixture$perfect
    }, .package = "rpart")
    # The first learner is perfect on these sampled rows, but not on the full data.
    local_mocked_bindings(rus = function(...) c(1L, 2L, 7L, 8L), .package = "farr")
    fit <- rusboost(y ~ x, fixture$data, size = 3, learn_rate = 0.5,
                    rus = use_rus, control = boost_control())
    expect_identical(calls, 2L)
    expect_identical(fit$weakLearners, list(fixture$perfect))
    expect_equal(fit$alpha, 1)
    expect_length(fit$w, 1)
    expected_weights <- exp(0.5 * log(3) * as.integer(1:8 %in% 5:6))
    expect_equal(fit$w[[1]], expected_weights / sum(expected_weights))
    expect_equal(predict(fit, fixture$data), rep(c(0, 1), each = 4))
    expect_equal(unname(predict(fit, fixture$data, type = "class")),
                 rep(c(-1, 1), each = 4))
  })

  test_that(paste(label, "omits unusable learners and keeps bookkeeping aligned"), {
    fixture <- boost_training_fixture()
    sequence <- if (use_rus) {
      list(fixture$bad, fixture$imperfect, fixture$bad)
    } else list(fixture$imperfect, fixture$bad)
    calls <- 0L
    local_mocked_bindings(rpart = function(...) {
      calls <<- calls + 1L
      sequence[[calls]]
    }, .package = "rpart")
    set.seed(32)
    fit <- rusboost(y ~ x, fixture$data, size = 3, rus = use_rus,
                    control = boost_control())
    expect_identical(calls, length(sequence))
    expect_identical(fit$weakLearners, list(fixture$imperfect))
    expect_equal(fit$alpha, log(3))
    expect_length(fit$w, 1)
    expect_equal(fit$w[[1]], c(rep(1 / 12, 4), rep(1 / 4, 2), rep(1 / 12, 2)))
    expect_equal(predict(fit, fixture$data), c(rep(0, 6), rep(1, 2)))
  })

  test_that(paste(label, "reports when no usable learner can be fitted"), {
    data <- data.frame(x = rep(1, 8), y = factor(rep(c(0, 1), each = 4)))
    set.seed(32)
    expect_error(rusboost(y ~ x, data, size = 3, rus = use_rus,
                          control = boost_control()), "No usable weak learner")
  })

  test_that(paste(label, "requires two nonmissing response classes"), {
    for (response in list(numeric(), rep(0, 4), rep(1, 4), c(0, 1, 2),
                           c(0, 1, NA), c(0, 2))) {
      data <- data.frame(x = seq_along(response), y = factor(response))
      expect_error(rusboost(y ~ x, data, size = 3, rus = use_rus,
                            control = boost_control()), "two.*classes")
    }
  })
}

test_that("singleton minority draws stay within their class for either label", {
  for (minority in c(-1, 1)) {
    response <- c(rep(-minority, 4), minority)
    set.seed(42)
    rows <- replicate(20, farr:::rus(response))
    expect_identical(unname(rows[1, ]), rep(5L, 20))
    expect_true(all(rows[2, ] %in% 1:4))
  }
})

test_that("one observation per class is sampled without crossing classes", {
  for (response in list(c(-1, 1), c(1, -1))) {
    set.seed(42)
    rows <- replicate(20, farr:::rus(response))
    expected <- which(response == -1)
    expect_identical(unname(rows[1, ]), rep(expected, 20))
    expect_identical(unname(rows[2, ]), rep(which(response == 1), 20))
  }
  expect_setequal(farr:::rus(factor(c(-1, 1), levels = c(-1, 0, 1))), 1:2)
})

test_that("majority draws are unique and ordinary sampling retains its RNG path", {
  response <- c(rep(-1, 6), rep(1, 3))
  set.seed(32)
  expected <- c(sample(7:9, 3, replace = TRUE), sample(1:6, 6, replace = FALSE))
  set.seed(32)
  expect_identical(farr:::rus(response, ir = 2), expected)
  rows <- replicate(20, farr:::rus(response, ir = 2))
  expect_true(all(rows[1:3, ] %in% 7:9))
  expect_true(all(rows[4:9, ] %in% 1:6))
  expect_true(all(apply(rows[4:9, ], 2, function(x) !anyDuplicated(x))))
  expect_length(farr:::rus(c(-1, -1, -1, -1, 1, 1), ir = 1.5), 5)
})

test_that("undersampling validates classes and the requested majority sample", {
  for (response in list(numeric(), rep(-1, 4), rep(1, 4), c(-1, 0, 1),
                         c(-1, 1, NA))) {
    expect_error(farr:::rus(response), "two.*classes")
  }
  for (ir in list(0, -1, NA_real_, Inf, NaN, c(1, 2), "1", 1.25, 2.5)) {
    expect_error(farr:::rus(c(-1, -1, -1, -1, 1, 1), ir = ir),
                 "(ir|majority sample)")
  }
  data <- data.frame(x = 1:6, y = factor(c(0, 0, 0, 0, 1, 1)))
  expect_error(rusboost(y ~ x, data, size = 3, ir = 3, control = boost_control()),
               "majority sample")
})

test_that("a zero weighted error does not make an imperfect learner perfect", {
  fixture <- boost_training_fixture()
  original_update <- farr:::w.update
  calls <- 0L
  local_mocked_bindings(rpart = function(...) {
    calls <<- calls + 1L
    fixture$imperfect
  }, .package = "rpart")
  updates <- 0L
  local_mocked_bindings(w.update = function(prediction, response, w, learn_rate) {
    updates <<- updates + 1L
    if (updates == 1L) {
      # Simulate zero weights from numerical underflow on the misclassified rows.
      list(w = c(rep(1 / 6, 4), 0, 0, rep(1 / 6, 2)), alpha = log(3), err = 0.25)
    } else original_update(prediction, response, w, learn_rate)
  }, .package = "farr")
  set.seed(32)
  fit <- rusboost(y ~ x, fixture$data, size = 3, control = boost_control())
  expect_identical(calls, 3L)
  expect_identical(fit$weakLearners, list(fixture$imperfect))
  expect_equal(fit$alpha, log(3))
  expect_length(fit$w, 1)
})

test_that("training works with a singleton minority of either response label", {
  for (minority in c(0, 1)) {
    response <- c(rep(1 - minority, 4), minority)
    data <- data.frame(x = c(rep(0, 4), 1), y = factor(response))
    set.seed(42)
    fit <- rusboost(y ~ x, data, size = 3, control = boost_control())
    expect_equal(fit$alpha, 1)
    expect_equal(predict(fit, data), response)
  }
})

test_that("training requires a positive attempt count and learning rate", {
  data <- data.frame(x = 1:8, y = factor(rep(c(0, 1), each = 4)))
  for (size in list(0, -1, 1.5, NA_real_, Inf, numeric(), c(1, 2), "1", 1i)) {
    expect_error(rusboost(y ~ x, data, size = size, control = boost_control()),
                 "size.*positive integer")
  }
  for (learn_rate in list(0, -1, NA_real_, Inf, numeric(), c(1, 2), "1", 1i)) {
    expect_error(rusboost(y ~ x, data, size = 3, learn_rate = learn_rate,
                          control = boost_control()), "learn_rate.*positive finite")
  }
})

test_that("skipping a RUS learner preserves weight normalization", {
  fixture <- boost_training_fixture()
  original_update <- farr:::w.update
  weights <- c(rep(1 / 12, 4), rep(1 / 4, 2), rep(1 / 12, 2))
  weights[1] <- weights[1] + .Machine$double.eps
  calls <- 0L
  local_mocked_bindings(rpart = function(weights, ...) {
    calls <<- calls + 1L
    if (calls == 1L) return(fixture$imperfect)
    if (calls == 2L) return(fixture$bad)
    expect_identical(weights, expected_weights)
    fixture$perfect
  }, .package = "rpart")
  updates <- 0L
  local_mocked_bindings(w.update = function(prediction, response, w, learn_rate) {
    updates <<- updates + 1L
    if (updates == 1L) {
      # Simulate rounding after a successful update; the next (failed) attempt
      # must still perform the usual normalization before another tree is fit.
      list(w = weights, alpha = log(3), err = 0.25)
    } else original_update(prediction, response, w, learn_rate)
  }, .package = "farr")
  expected_weights <- weights / sum(weights)
  local_mocked_bindings(rus = function(...) seq_len(8L), .package = "farr")
  fit <- rusboost(y ~ x, fixture$data, size = 3, ir = 1,
                  rus = TRUE, control = boost_control())
  expect_identical(calls, 3L)
  expect_equal(fit$alpha, 1)
  expect_identical(fit$w[[1]], expected_weights)
})
