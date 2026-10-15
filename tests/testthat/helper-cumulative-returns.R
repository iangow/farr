with_cumulative_returns_fixture <- function(config, stock, market = c(0.03, 0.04),
                                             size = c(0.02, 0.01),
                                             dlret = rep(NA_real_, length(stock)),
                                             code, dates = NULL) {
  stopifnot(length(stock) == length(market), length(stock) == length(size),
            length(stock) == length(dlret), length(stock) %in% 2:3)
  old_options <- options(lifecycle_verbosity = "quiet")
  on.exit(options(old_options), add = TRUE)
  if (config$backend == "DuckDB") {
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
      port = Sys.getenv("FARR_TEST_POSTGRES_PORT", "5432"), connect_timeout = 5
    )
    on.exit(DBI::dbDisconnect(conn), add = TRUE)
    DBI::dbExecute(conn, "SET client_min_messages TO WARNING")
    # An existing schema is never replaced; use a disposable test database.
    DBI::dbExecute(conn, "CREATE SCHEMA crsp")
    on.exit(DBI::dbExecute(conn, "DROP SCHEMA crsp CASCADE"),
            add = TRUE, after = FALSE)
  }

  if (is.null(dates)) {
    dates <- if (config$frequency == "daily") {
      as.Date(c("2026-01-28", "2026-01-29", "2026-01-30"))
    } else {
      as.Date(c("2025-12-31", "2026-01-30", "2026-02-27"))
    }
    dates <- dates[seq_along(stock)]
  }
  stopifnot(inherits(dates, "Date"), length(dates) == length(stock), !anyNA(dates))
  series <- tibble::tibble(permno = 10001L, date = dates, ret = stock)
  benchmarks <- tibble::tibble(date = dates, vwretd = market)
  size_returns <- tibble::tibble(permno = 10001L, date = dates, decret = size)
  delistings <- tibble::tibble(permno = 10001L, dlstdt = dates, dlret = dlret)
  delistings <- delistings[!is.na(delistings$dlret), , drop = FALSE]
  tables <- list(benchmarks, series, size_returns, delistings)
  names(tables) <- if (config$frequency == "daily") {
    c("dsi", "dsf", "erdport1", "dsedelist")
  } else {
    c("msi", "msf", "ermport1", "msedelist")
  }
  if (config$precomputed) {
    rets <- dplyr::mutate(series, vwretd = market, decret = size)
    has_delisting <- !is.na(dlret)
    rets$ret[has_delisting] <-
      (1 + dplyr::coalesce(stock[has_delisting], 0)) * (1 + dlret[has_delisting]) - 1
    tables[[if (config$frequency == "daily") "rets" else "mrets"]] <- rets
  }
  for (table in names(tables)) {
    name <- if (config$backend == "DuckDB") table else DBI::Id(schema = "crsp", table = table)
    DBI::dbWriteTable(conn, name, tables[[table]])
  }
  if (config$backend == "DuckDB") {
    local_mocked_bindings(
      load_parquet = function(conn, table, schema = "", ...) dplyr::tbl(conn, table),
      .package = "farr"
    )
  }
  events <- tibble::tibble(permno = 10001L, event_date = dates[1],
                           last_event = dates[length(dates)])
  code(conn, events, dates)
}

cumulative_returns_configs <- list(
  list(backend = "DuckDB", frequency = "daily", precomputed = FALSE),
  list(backend = "DuckDB", frequency = "monthly", precomputed = FALSE),
  list(backend = "PostgreSQL", frequency = "daily", precomputed = FALSE),
  list(backend = "PostgreSQL", frequency = "monthly", precomputed = FALSE),
  list(backend = "PostgreSQL", frequency = "daily", precomputed = TRUE),
  list(backend = "PostgreSQL", frequency = "monthly", precomputed = TRUE)
)
