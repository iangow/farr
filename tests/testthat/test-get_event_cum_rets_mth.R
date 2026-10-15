monthly_configs <- Filter(function(config) config$frequency == "monthly",
                           cumulative_returns_configs)

for (config in monthly_configs) {
  label <- paste(config$backend,
                  if (config$precomputed) "precomputed" else "reconstructed")

  test_that(paste(label, "monthly offsets include the whole target month"), {
    cases <- list(
      non_leap_february = list(event = "2026-02-27", start = -1, end = 1,
        dates = c("2026-01-30", "2026-02-27", "2026-03-31"), included = 1:3),
      leap_february = list(event = "2020-02-29", start = 1, end = 1,
        dates = c("2020-02-28", "2020-03-31", "2020-04-30"), included = 2L),
      negative_from_february = list(event = "2026-02-15", start = -1, end = -1,
        dates = c("2025-12-31", "2026-01-30", "2026-02-27"), included = 2L),
      negative_from_leap_february = list(event = "2020-02-15", start = -1, end = -1,
        dates = c("2019-12-31", "2020-01-31", "2020-02-28"), included = 2L),
      thirty_to_thirty_one = list(event = "2024-04-15", start = 1, end = 1,
        dates = c("2024-04-30", "2024-05-31", "2024-06-28"), included = 2L),
      negative_thirty_to_thirty_one = list(event = "2023-04-15", start = -1, end = -1,
        dates = c("2023-02-28", "2023-03-31", "2023-04-28"), included = 2L),
      multiple_positive_months = list(event = "2026-02-15", start = 2, end = 2,
        dates = c("2026-03-31", "2026-04-30", "2026-05-29"), included = 2L),
      multiple_negative_months = list(event = "2026-02-15", start = -4, end = -4,
        dates = c("2025-09-30", "2025-10-31", "2025-11-28"), included = 2L),
      year_boundary = list(event = "2024-11-15", start = 2, end = 2,
        dates = c("2024-12-31", "2025-01-31", "2025-02-28"), included = 2L),
      ending_in_february = list(event = "2026-01-15", start = 1, end = 1,
        dates = c("2026-01-30", "2026-02-27", "2026-03-31"), included = 2L),
      ending_in_leap_february = list(event = "2020-01-15", start = 1, end = 1,
        dates = c("2020-01-31", "2020-02-28", "2020-03-31"), included = 2L),
      zero_offset = list(event = "2026-02-15", start = 0, end = 0,
        dates = c("2026-01-30", "2026-02-27", "2026-03-31"), included = 2L)
    )
    stock <- c(0.1, 0.2, 0.3)
    market <- c(0.03, 0.04, 0.05)
    size <- c(0.02, 0.01, 0.06)
    for (case in names(cases)) {
      input <- cases[[case]]
      with_cumulative_returns_fixture(config, stock = stock, market = market, size = size,
        dates = as.Date(input$dates), code = function(conn, events, dates) {
          events <- tibble::tibble(permno = 10001L, event_date = as.Date(input$event))
          actual <- get_event_cum_rets_mth(events, conn,
                                           win_start = input$start, win_end = input$end)
          included <- input$included
          gross <- prod(1 + stock[included])
          expected <- tibble::tibble(
            ret_raw = gross - 1, ret_mkt = gross - prod(1 + market[included]),
            ret_sz = gross - prod(1 + size[included])
          )
          expect_equal(dplyr::select(actual, dplyr::all_of(names(expected))), expected,
                       info = case)
          expect_equal(dplyr::select(actual, "permno", "event_date"), events, info = case)
        }
      )
    }
  })

  test_that(paste(label, "monthly offsets use the separate ending event month"), {
    with_cumulative_returns_fixture(config, stock = c(0.1, 0.2, 0.3),
      market = c(0.03, 0.04, 0.05), size = c(0.02, 0.01, 0.06),
      dates = as.Date(c("2026-01-30", "2026-02-27", "2026-03-31")),
      code = function(conn, events, dates) {
        events <- tibble::tibble(permno = 10001L, announcement = as.Date("2026-01-15"),
                                 close = as.Date("2026-02-15"))
        actual <- get_event_cum_rets_mth(events, conn, event_date = "announcement",
                                         end_event_date = "close", win_end = 1,
                                         suffix = "_window")
        gross <- prod(1 + c(0.1, 0.2, 0.3))
        expected <- tibble::tibble(
          ret_window_raw = gross - 1,
          ret_window_mkt = gross - prod(1 + c(0.03, 0.04, 0.05)),
          ret_window_sz = gross - prod(1 + c(0.02, 0.01, 0.06))
        )
        expect_equal(dplyr::select(actual, dplyr::all_of(names(expected))), expected)
        expect_equal(dplyr::select(actual, "permno", "announcement", "close"), events)
      }
    )
  })
}
