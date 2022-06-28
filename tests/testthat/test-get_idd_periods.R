idd_periods <- get_idd_periods(min_date = "1994-01-01",
                                max_date = "2010-12-31")


test_that("get_idd_periods works", {
  expect_equal(min(idd_periods$start_date), as.Date("1994-01-01"))
})

test_that("get_idd_periods works", {
  expect_equal(max(idd_periods$end_date), as.Date("2010-12-31"))
})
