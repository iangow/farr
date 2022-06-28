trunced <- truncate(1:100, prob = 0.05)

test_that("truncate works", {
  expect_equal(min(trunced, na.rm = TRUE), 6)
})

test_that("truncate works", {
  expect_equal(max(trunced, na.rm = TRUE), 95)
})
