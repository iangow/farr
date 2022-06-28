library(dplyr, warn.conflicts = FALSE)

temp <-
    get_me_breakpoints() %>%
    filter(month == '2022-04-01')

test_that("get_me_breakpoints works", {
  expect_equal(length(temp$decile), 10)
})
