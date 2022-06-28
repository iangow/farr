winsorized <- winsorize(1:100, prob = 0.05)

test_that("winsorize works", {
  expect_equal(min(winsorized, na.rm = TRUE), 5.5)
})

test_that("winsorize works", {
  expect_equal(max(winsorized, na.rm = TRUE), 95.5)
})
