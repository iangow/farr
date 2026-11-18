test_that("bundled Apple events retain their public schema and reviewed dates", {
    events <- farr::apple_events
    expect_s3_class(events, "tbl_df")
    expect_identical(names(events), c("event", "event_date", "end_event_date"))
    expect_s3_class(events$event_date, "Date")
    expect_s3_class(events$end_event_date, "Date")
    expect_false(anyNA(events))
    expect_true(all(events$event_date <= events$end_event_date))
    expect_false(anyDuplicated(events$event_date) > 0L)
    expect_false(is.unsorted(events$event_date))
    expect_equal(nrow(events), 76L)
    expect_equal(min(events$event_date), as.Date("2005-01-11"))
    expect_equal(max(events$end_event_date), as.Date("2026-09-09"))
    expect_true(as.Date("2019-12-02") %in% events$event_date)
    macworld <- events[events$event == "Macworld Conference & Expo San Francisco 2008", ]
    expect_equal(macworld$event_date, as.Date("2008-01-15"))
    expect_equal(macworld$end_event_date, macworld$event_date)
    wwdc <- events[events$event == "WWDC 2026", ]
    expect_equal(wwdc$event_date, as.Date("2026-06-08"))
    expect_equal(wwdc$end_event_date, as.Date("2026-06-12"))
})
