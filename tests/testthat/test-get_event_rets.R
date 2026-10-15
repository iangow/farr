# PostgreSQL coverage uses an explicitly configured, disposable test database.
# CREATE SCHEMA fails rather than overwriting an existing crsp schema.
with_event_rets_fixture <- function(backend, code) {
  # Existing input helpers use deprecated tidyselect syntax independently of
  # this mapping correction. Keep other warnings visible in these tests.
  old_options <- options(lifecycle_verbosity = "quiet")
  on.exit(options(old_options), add = TRUE)

  if (backend == "DuckDB") {
    skip_if_not_installed("duckdb")
    driver_args <- if ("shared_home" %in% names(formals(duckdb::duckdb))) {
      list(shared_home = FALSE)
    } else {
      list(config = list(home_directory = tempdir()))
    }
    conn <- DBI::dbConnect(do.call(duckdb::duckdb, driver_args))
    on.exit(DBI::dbDisconnect(conn, shutdown = TRUE), add = TRUE)
  } else {
    skip_if_not_installed("RPostgres")
    dbname <- Sys.getenv("FARR_TEST_POSTGRES_DBNAME")
    skip_if(dbname == "", "Set FARR_TEST_POSTGRES_DBNAME for PostgreSQL tests")
    conn <- DBI::dbConnect(
      RPostgres::Postgres(), dbname = dbname,
      host = Sys.getenv("FARR_TEST_POSTGRES_HOST", "localhost"),
      port = Sys.getenv("FARR_TEST_POSTGRES_PORT", "5432"),
      connect_timeout = 5
    )
    on.exit(DBI::dbDisconnect(conn), add = TRUE)
    DBI::dbExecute(conn, "SET client_min_messages TO WARNING")
    DBI::dbExecute(conn, "CREATE SCHEMA crsp")
    on.exit(DBI::dbExecute(conn, "DROP SCHEMA crsp CASCADE"),
            add = TRUE, after = FALSE)
  }

  dates <- as.Date(c("2026-10-08", "2026-10-09", "2026-10-12",
                     "2026-10-14", "2026-10-15", "2026-10-16"))
  dsf <- tibble::tibble(
    permno = rep(c(10001L, 10002L), each = length(dates)),
    date = rep(dates, 2), ret = rep(c(0.02, -0.01), each = length(dates))
  )
  tables <- list(
    dsi = tibble::tibble(date = dates, vwretd = 0.005),
    dsf = dsf,
    erdport1 = dplyr::mutate(dplyr::select(dsf, -"ret"), decret = 0.004),
    dsedelist = tibble::tibble(permno = integer(), dlstdt = as.Date(character()),
                              dlret = double())
  )
  for (table in names(tables)) {
    name <- if (backend == "DuckDB") table else DBI::Id(schema = "crsp", table = table)
    DBI::dbWriteTable(conn, name, tables[[table]])
  }
  if (backend == "DuckDB") {
    local_mocked_bindings(
      load_parquet = function(conn, table, schema = "", ...) dplyr::tbl(conn, table),
      .package = "farr"
    )
  }
  code(conn)
}

for (backend in c("DuckDB", "PostgreSQL")) {
  test_that(paste(backend, "retains trading-day, weekend, and holiday announcements"), {
    with_event_rets_fixture(backend, function(conn) {
      # October 13 is deliberately absent from the synthetic trading calendar.
      events <- tibble::tibble(
        permno = c(rep(10001L, 5), 10002L),
        event_date = as.Date(c("2026-10-09", "2026-10-10", "2026-10-11",
                               "2026-10-12", "2026-10-13", "2026-10-10"))
      )
      actual <- get_event_rets(events, conn) |>
        dplyr::arrange(.data$permno, .data$event_date)
      mapped <- as.Date(c("2026-10-09", "2026-10-12", "2026-10-12",
                           "2026-10-12", "2026-10-14", "2026-10-12"))
      expected <- dplyr::mutate(events, date = mapped,
                                ret = c(rep(0.02, 5), -0.01), vwretd = 0.005,
                                decret = 0.004, relative_td = 0L)
      expect_equal(dplyr::select(actual, dplyr::all_of(names(expected))), expected)
      expect_equal(actual$start_date, mapped)
      expect_equal(actual$end_date, mapped)
    })
  })

  test_that(paste(backend, "measures relative days from the mapped announcement"), {
    with_event_rets_fixture(backend, function(conn) {
      events <- tibble::tibble(
        permno = 10001L,
        event_date = as.Date(c("2026-10-09", "2026-10-10", "2026-10-13"))
      )
      actual <- get_event_rets(events, conn, win_start = -1, win_end = 1) |>
        dplyr::arrange(.data$event_date, .data$date)
      expected <- tibble::tibble(
        event_date = rep(events$event_date, each = 3),
        date = as.Date(c("2026-10-08", "2026-10-09", "2026-10-12",
                         "2026-10-09", "2026-10-12", "2026-10-14",
                         "2026-10-12", "2026-10-14", "2026-10-15")),
        relative_td = rep(-1L:1L, 3)
      )
      expect_equal(dplyr::select(actual, dplyr::all_of(names(expected))), expected)
    })
  })

  test_that(paste(backend, "preserves separate ending dates without multiplying rows"), {
    with_event_rets_fixture(backend, function(conn) {
      events <- tibble::tibble(
        permno = 10001L,
        announcement = as.Date(c("2026-10-10", "2026-10-10", "2026-10-11")),
        window_end = as.Date(c("2026-10-13", "2026-10-15", "2026-10-13"))
      )
      actual <- get_event_rets(events, conn, event_date = "announcement",
                               end_event_date = "window_end",
                               win_start = -1, win_end = 1) |>
        dplyr::arrange(.data$announcement, .data$window_end, .data$date)
      expected <- tibble::tibble(
        announcement = rep(events$announcement, c(4, 5, 4)),
        window_end = rep(events$window_end, c(4, 5, 4)),
        date = as.Date(c("2026-10-09", "2026-10-12", "2026-10-14", "2026-10-15",
                         "2026-10-09", "2026-10-12", "2026-10-14", "2026-10-15",
                         "2026-10-16", "2026-10-09", "2026-10-12", "2026-10-14",
                         "2026-10-15")),
        relative_td = c(-1L:2L, -1L:3L, -1L:2L)
      )
      expect_equal(dplyr::select(actual, dplyr::all_of(names(expected))), expected)
    })
  })
}
