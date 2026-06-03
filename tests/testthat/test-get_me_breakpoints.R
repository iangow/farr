library(dplyr, warn.conflicts = FALSE)

test_that("get_me_breakpoints works", {
  skip_if_offline("mba.tuck.dartmouth.edu")

  temp <-
      get_me_breakpoints() %>%
      filter(month == '2022-04-01')

  expect_equal(length(temp$decile), 10)
})
