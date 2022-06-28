set.seed(2021)
library(dplyr, warn.conflicts = FALSE)
temp <- get_test_scores()

test_that("get_test_scores works", {
  expect_equal(length(unique(temp$id)), 1000)
})
