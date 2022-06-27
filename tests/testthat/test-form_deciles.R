test_that("form_deciles works", {
  expect_equal(form_deciles(1:20), sort(rep(1:10, 2)))
})
