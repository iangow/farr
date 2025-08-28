#' Produce a table mapping announcements to trading dates
#'
#' Produce a table of event dates for linking with CRSP.
#' See \code{vignette("wrds-conn", package = "farr")} for more on using this function.
#'
#' @param data data frame containing data on events
#' @param permno string representing column containing PERMNOs for events
#' @param event_date string representing column containing dates for events
#' @param conn connection to a PostgreSQL database
#' @param win_start integer representing start of trading window (e.g., -1)
#' @param win_end integer representing start of trading window (e.g., 1)
#' @param end_event_date string representing column containing ending dates for events
#'
#' @return tbl_df
#' @export
#' @importFrom rlang .data
#' @examples
#' ## Not run:
#' \dontrun{
#' library(DBI)
#' library(dplyr, warn.conflicts = FALSE)
#' pg <- dbConnect(RPostgres::Postgres())
#' events <- tibble(permno = c(14593L, 10107L),
#'                  event_date = as.Date(c("2019-01-31", "2019-01-31")))
#' get_event_dates(events, pg, win_start = -3, win_end = + 3)
#' }
#' ## End(Not run)
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
