gross_product <- function(x) {
  if (all(is.na(x))) NA_real_ else prod(1 + x, na.rm = TRUE)
}

for (config in cumulative_returns_configs) {
  label <- paste(config$backend, config$frequency,
                  if (config$precomputed) "precomputed" else "reconstructed")
  get_returns <- if (config$frequency == "daily") get_event_cum_rets else get_event_cum_rets_mth

  test_that(paste(label, "compounds ordinary returns and preserves missingness"), {
    cases <- list(
      ordinary = list(stock = c(0.1, 0.2)),
      mixed = list(stock = c(0.1, -0.2)),
      zero = list(stock = c(0, 0)),
      missing_stock = list(stock = c(0.1, NA_real_), market = c(0, 0), size = c(0, 0)),
      partial_benchmarks = list(stock = c(0.1, 0.2), market = c(0.03, NA_real_),
                                size = c(NA_real_, 0.01)),
      missing_benchmarks = list(stock = c(0.1, 0.2), market = rep(NA_real_, 2),
                                size = rep(NA_real_, 2))
    )
    for (case in names(cases)) {
      input <- utils::modifyList(list(market = c(0.03, 0.04), size = c(0.02, 0.01)),
                                 cases[[case]])
      do.call(with_cumulative_returns_fixture, c(list(config = config), input, list(
        code = function(conn, events, dates) {
          actual <- get_returns(events, conn, end_event_date = "last_event")
          gross <- gross_product(input$stock)
          expected <- tibble::tibble(
            ret_raw = gross - 1, ret_mkt = gross - gross_product(input$market),
            ret_sz = gross - gross_product(input$size)
          )
          expect_equal(dplyr::select(actual, dplyr::all_of(names(expected))), expected,
                       info = case)
        }
      )))
    }
  })

  test_that(paste(label, "retains complete losses in stocks and benchmarks"), {
    cases <- list(
      stock_loss = list(stock = c(-1, 0.2)),
      repeated_loss = list(stock = c(-1, -1)),
      loss_and_missing = list(stock = c(-1, NA_real_), market = c(0, 0), size = c(0, 0)),
      market_loss = list(stock = c(0.1, 0.2), market = c(-1, 0.04)),
      size_loss = list(stock = c(0.1, 0.2), size = c(0.02, -1)),
      benchmark_losses_and_missing = list(stock = c(0.1, 0.2), market = c(-1, NA_real_),
                                          size = c(NA_real_, -1)),
      delisting_loss = list(stock = c(0.1, 0.2), dlret = c(NA_real_, -1))
    )
    for (case in names(cases)) {
      input <- utils::modifyList(list(market = c(0.03, 0.04), size = c(0.02, 0.01)),
                                 cases[[case]])
      do.call(with_cumulative_returns_fixture, c(list(config = config), input, list(
        code = function(conn, events, dates) {
          actual <- get_returns(events, conn, end_event_date = "last_event")
          # Every stock-loss case, including delisting, compounds to zero gross.
          gross <- if (case %in% c("market_loss", "size_loss", "benchmark_losses_and_missing")) {
            gross_product(input$stock)
          } else 0
          expected <- tibble::tibble(
            ret_raw = gross - 1, ret_mkt = gross - gross_product(input$market),
            ret_sz = gross - gross_product(input$size)
          )
          expect_equal(dplyr::select(actual, dplyr::all_of(names(expected))), expected,
                       info = case)
        }
      )))
    }
  })

  test_that(paste(label, "rejects returns below minus one even with a complete loss"), {
    modes <- if (config$backend == "DuckDB") list("true", "false") else list(NULL)
    for (mode in modes) {
      for (field in c("stock", "market", "size")) {
        for (bad in list(c(-1.1, 0.2), c(-1, -1.1), c(-1.1, NA_real_))) {
          input <- list(stock = c(0.1, 0.2), market = c(0.03, 0.04), size = c(0.02, 0.01))
          input[[field]] <- bad
          do.call(with_cumulative_returns_fixture, c(list(config = config), input, list(
            ieee_floating_point_ops = mode,
            code = function(conn, events, dates) {
              message <- if (config$backend == "DuckDB") {
                "Returns below -1 imply a negative gross return"
              } else "negative"
              expect_error(get_returns(events, conn, end_event_date = "last_event"),
                           message, info = paste(field, mode))
              if (!is.null(mode)) {
                setting <- DBI::dbGetQuery(conn,
                  "SELECT value FROM duckdb_settings() WHERE name = 'ieee_floating_point_ops'")
                expect_identical(setting$value, mode)
              }
            }
          )))
        }
      }
    }
  })

  test_that(paste(label, "preserves empty or all-missing stock windows"), {
    with_cumulative_returns_fixture(config, stock = rep(NA_real_, 2),
      code = function(conn, events, dates) {
        actual <- get_returns(events, conn, end_event_date = "last_event")
        expect_equal(nrow(actual), if (config$precomputed) 1L else 0L)
        if (config$precomputed) {
          expect_true(all(is.na(dplyr::select(actual, "ret_raw", "ret_mkt", "ret_sz"))))
        }
      }
    )
  })

  test_that(paste(label, "preserves offsets, custom event columns, and suffixes"), {
    with_cumulative_returns_fixture(config, stock = c(0.1, -1, 0.2),
      market = c(0.03, 0.04, 0.05), size = c(0.02, 0.01, 0.06),
      code = function(conn, events, dates) {
        events <- tibble::tibble(permno = 10001L, announcement = dates[2], close = dates[2])
        actual <- get_returns(events, conn, event_date = "announcement", end_event_date = "close",
                               win_start = -1, win_end = 1, suffix = "_window")
        expected <- tibble::tibble(
          ret_window_raw = -1, ret_window_mkt = -prod(1 + c(0.03, 0.04, 0.05)),
          ret_window_sz = -prod(1 + c(0.02, 0.01, 0.06))
        )
        expect_equal(dplyr::select(actual, dplyr::all_of(names(expected))), expected)
        expect_equal(dplyr::select(actual, "permno", "announcement", "close"), events)
      }
    )
  })
}
