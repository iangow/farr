#' Produce a table of cumulative event returns
#'
#' Produce a table of event returns from CRSP.
#'
#' @param data data frame containing data on events
#' @param permno string representing column containing PERMNOs for events
#' @param event_date string representing column containing dates for events
#' @param conn connection to a PostgreSQL database
#' @param win_start integer representing start of trading window (e.g., -1)
#' @param win_end integer representing start of trading window (e.g., 1)
#' @param end_event_date string representing column containing ending dates for
#' events
#' @param suffix Text to be appended after "ret" in variable names
#'
#' @return tbl_df
#' @export
#' @importFrom rlang .data
#' @examples
#' ## Not run:
#' \dontrun{
#' library(DBI)
#' library(dplyr, warn.conflicts = FALSE)
#' library(RPostgres)
#' pg <- dbConnect(Postgres())
#' events <- tibble(permno = c(14593L, 10107L),
#'                  event_date = as.Date(c("2019-01-31", "2019-01-31")))
#' get_event_cum_rets(events, pg)
#' }
#' ## End(Not run)
get_event_cum_rets <- function(data, conn,
                               permno = "permno",
                               event_date = "event_date",
                               win_start = 0, win_end = 0,
                               end_event_date = NULL,
                               suffix = "") {

    if (is.null(end_event_date)) {
        data_local <-
            data %>%
            dplyr::select(.data[[permno]], .data[[event_date]]) %>%
            dplyr::distinct()
        end_event_date <- event_date
        drop_end_event_date <- TRUE
    } else {
        data_local <-
            data %>%
            dplyr::select(.data[[permno]], .data[[event_date]],
                          .data[[end_event_date]]) %>%
            dplyr::distinct()
        drop_end_event_date <- FALSE
    }

    event_dates <- get_event_dates(data_local, conn, permno = permno,
                                   event_date = event_date,
                                   win_start = win_start, win_end = win_end,
                                   end_event_date = end_event_date)

    if (inherits(conn, "duckdb_connection")) {
        rets_exists <- FALSE
    } else {
        rets_exists <- DBI::dbExistsTable(conn, DBI::Id(table = "rets",
                                                        schema = "crsp"))
    }

    if (inherits(conn, "duckdb_connection")) {
        crsp.dsi <- farr::load_parquet(conn, "dsi", "crsp")
    } else {
        crsp.dsi <- dplyr::tbl(conn, dplyr::sql("SELECT * FROM crsp.dsi"))
    }

    if (rets_exists) {
        rets <-  dplyr::tbl(conn, dplyr::sql("SELECT * FROM crsp.rets"))
    } else {

        if (inherits(conn, "duckdb_connection")) {
            crsp.dsi <- farr::load_parquet(conn, "dsi", "crsp")
            crsp.dsedelist <- farr::load_parquet(conn, "dsedelist", "crsp")
            crsp.dsf <- farr::load_parquet(conn, "dsf", "crsp")
            crsp.erdport1 <- farr::load_parquet(conn, "erdport1", "crsp")
        } else {
            crsp.dsedelist <- dplyr::tbl(conn,
                                         dplyr::sql("SELECT * FROM crsp.dsedelist"))
            crsp.dsf <- dplyr::tbl(conn,
                                   dplyr::sql("SELECT * FROM crsp.dsf"))
            crsp.erdport1 <- dplyr::tbl(conn,
                                        dplyr::sql("SELECT * FROM crsp.erdport1"))
        }

        dsedelist <-
            crsp.dsedelist %>%
            dplyr::select(permno, date = .data$dlstdt, .data$dlret) %>%
            dplyr::filter(!is.na(.data$dlret))

        dsf_plus <-
            crsp.dsf %>%
            dplyr::full_join(dsedelist, by = c("permno", "date")) %>%
            dplyr::filter(!is.na(.data$ret) | !is.na(.data$dlret)) %>%
            dplyr::mutate(ret = (1 + dplyr::coalesce(.data$ret, 0)) *
                              (1 + dplyr::coalesce(.data$dlret, 0)) - 1) %>%
            dplyr::select(.data$permno, .data$date, .data$ret)

        erdport <-
            crsp.erdport1 %>%
            dplyr::select(.data$permno, .data$date, .data$decret)

        dsf_w_erdport <-
            dsf_plus %>%
            dplyr::left_join(erdport, by = c("permno", "date"))

        dsi <-
            crsp.dsi %>%
            dplyr::select(.data$date, .data$vwretd)

        rets <-
            dsf_w_erdport %>%
            dplyr::left_join(dsi, by = "date")
    }

    if (inherits(conn, "duckdb_connection")) {
        events <- dplyr::copy_to(dest = conn, df = event_dates)
    } else if (rets_exists) {
        events <- dplyr::copy_to(dest = conn, df = event_dates)
    } else {
        events <- dbplyr::copy_inline(con = conn, df = event_dates)
    }

    results <-
        events %>%
        dplyr::inner_join(rets, by = "permno") %>%
        dplyr::filter(dplyr::between(.data$date,
                                     .data$start_date, .data$end_date)) %>%
        dplyr::group_by(dplyr::across(dplyr::all_of(c("permno",
                                                      !!event_date,
                                                      !!end_event_date)))) %>%
        dplyr::summarize(ret_raw =
                      exp(sum(dplyr::sql("ln((1 + ret))"), na.rm = TRUE)) - 1,
                  ret_mkt =
                      exp(sum(dplyr::sql("ln((1 + ret))"), na.rm = TRUE)) -
                      exp(sum(dplyr::sql("ln((1 + vwretd))"), na.rm = TRUE)) ,
                  ret_sz =
                      exp(sum(dplyr::sql("ln((1 + ret))"), na.rm = TRUE)) -
                      exp(sum(dplyr::sql("ln((1 + decret))"), na.rm = TRUE)),
                  .groups = "drop") %>%
        dplyr::collect() %>%
        dplyr::rename_with(function(x) gsub("^ret", paste0("ret", suffix), x),
                           dplyr::one_of(c("ret_raw", "ret_mkt", "ret_sz")))
    results
}

