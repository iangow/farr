#' Produce a table mapping announcements to trading dates
#'
#' Produce a table of event dates for linking with CRSP.
#'
#' @param data data frame containing data on events
#' @param permno string representing column containing PERMNOs for events
#' @param event_date string representing column containing dates for events
#' @param conn connection to a PostgreSQL or DuckDB database
#' @param win_start integer representing start of trading window (e.g., -1)
#' @param win_end integer representing start of trading window (e.g., 1)
#' @param end_event_date string representing column containing ending dates for events
#'
#' @return A tibble retaining the security and event-date columns from `data`,
#'   with `start_date` and `end_date` giving the mapped trading-window boundaries.
#' @export
#' @importFrom rlang .data
#' @examples
#' \dontrun{
#' # Requires an authenticated PostgreSQL connection with access to CRSP data.
#' local({
#'   pg <- DBI::dbConnect(RPostgres::Postgres())
#'   on.exit(DBI::dbDisconnect(pg), add = TRUE)
#'   events <- data.frame(permno = c(14593L, 10107L),
#'                         event_date = as.Date(c("2019-01-31", "2019-01-31")))
#'   get_event_dates(events, pg, win_start = -1, win_end = 1)
#' })
#' }
get_event_dates <- function(data, conn,
                            permno = "permno",
                            event_date = "event_date",
                            win_start = 0, win_end = 0,
                            end_event_date = NULL) {

    trading_dates <- farr::get_trading_dates(conn)
    annc_dates <- farr::get_annc_dates(conn)

    if (is.null(end_event_date)) {
        data_local <-
            data %>%
            dplyr::select(.data[[permno]], .data[[event_date]])
        end_event_date <- event_date
    } else {
        data_local <-
            data %>%
            dplyr::select(.data[[permno]], .data[[event_date]],
                          .data[[end_event_date]])
    }

    event_tds <-
        data_local %>%
        dplyr::inner_join(annc_dates, by = structure(names = event_date, .Data = "annc_date")) %>%
        dplyr::mutate(td_start = .data$td + win_start) %>%
        dplyr::select(-"td") %>%
        dplyr::inner_join(annc_dates, by = structure(names = end_event_date, .Data = "annc_date")) %>%
        dplyr::mutate(td_end = .data$td + win_end) %>%
        dplyr::select(-"td")

    event_dates <-
        event_tds %>%
        dplyr::inner_join(trading_dates, by=c("td_start"="td")) %>%
        dplyr::rename(start_date = date) %>%
        dplyr::inner_join(trading_dates, by=c("td_end"="td")) %>%
        dplyr::rename(end_date = date) %>%
        dplyr::select(-"td_start", -"td_end")

    event_dates
}
