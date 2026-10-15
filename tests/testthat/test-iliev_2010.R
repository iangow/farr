test_that("public-float dates match the verified 10-K disclosures", {
  # See data-raw/iliev_2010_date_corrections.csv for the source filings.
  expected <- data.frame(
    cik = c(92769L, rep(868984L, 4)),
    fyear = c(2004, 2003, 2004, 2005, 2006),
    pfdate = as.Date(c("2005-01-31", "2002-07-31", "2003-07-31",
                       "2004-07-30", "2005-07-29")),
    publicfloat = c(41.244671, 161.611326, 169.315283, 96.774556, 89.827857)
  )
  actual <- dplyr::semi_join(iliev_2010, expected, by = c("cik", "fyear"))
  actual <- dplyr::arrange(actual, cik, fyear)

  expect_equal(nrow(actual), nrow(expected))
  expect_equal(actual$pfdate, expected$pfdate)
  expect_equal(actual$publicfloat, expected$publicfloat)
  expect_equal(actual$pfyear, as.numeric(format(expected$pfdate, "%Y")))
})

test_that("public-float years are integral and agree with nonmissing dates", {
  expect_equal(nrow(iliev_2010), 7214L)
  expect_type(iliev_2010$fyear, "integer")
  expect_true(all(iliev_2010$pfyear == trunc(iliev_2010$pfyear)))
  dated <- iliev_2010[!is.na(iliev_2010$pfdate), ]
  expect_equal(dated$pfyear, as.numeric(format(dated$pfdate, "%Y")))
})
