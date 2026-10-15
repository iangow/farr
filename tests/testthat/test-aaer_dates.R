test_that("AAER dates retain source-backed corrections and historical coverage", {
  expected <- tibble::tibble(
    aaer_num = c("AAER-1209", "AAER-1440", "AAER-1470", "AAER-1813",
                 "AAER-1839", "AAER-2216", "AAER-2218"),
    aaer_date = as.Date(c("1999-11-16", "2001-09-06", "2001-10-23", "2003-07-14",
                          "2003-08-13", "2005-03-21", "2005-03-24"))
  )
  actual <- dplyr::semi_join(aaer_dates, expected, by = "aaer_num") |>
    dplyr::select(aaer_num, aaer_date) |>
    dplyr::arrange(aaer_num)
  expect_equal(actual, expected)
  expect_true("AAER-1271" %in% aaer_dates$aaer_num)
  expect_false("AAER-x2218" %in% aaer_dates$aaer_num)
})

test_that("AAER refresh removes exact duplicates while retaining distinct entries", {
  expect_equal(nrow(aaer_dates), 3386L)
  expect_identical(anyDuplicated(aaer_dates), 0L)
  expect_equal(sum(aaer_dates$aaer_num == "AAER-1670"), 1L)
  expect_equal(sum(aaer_dates$aaer_num == "AAER-3448"), 1L)
  expect_equal(sum(aaer_dates$aaer_num == "AAER-2215"), 2L)
  expect_s3_class(aaer_dates$aaer_date, "Date")
  expect_type(aaer_dates$year, "integer")
  expect_equal(sort(unique(aaer_dates$year)), 1999:2026)
  expect_setequal(aaer_dates$aaer_num[is.na(aaer_dates$aaer_date)],
                  c("AAER-2493", "AAER-2571", "AAER-2579"))
})
