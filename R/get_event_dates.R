#' Produce a table mapping announcements to trading dates
#'
#' Produce a table of event dates for linking with CRSP
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
get_event_dates <- function(data, conn,
                            permno = "permno",
                            event_date = "event_date",
                            win_start = 0, win_end = 0,
                            end_event_date = NULL) {

    trading_dates <- farr::get_trading_dates(conn)
    annc_dates <- farr::get_annc_dates(conn)

    if (is.null(end_event_date)) { end_event_date <- event_date }

    event_tds <-
        data %>%
        dplyr::inner_join(annc_dates, by = structure(names = event_date, .Data = "annc_date")) %>%
        dplyr::mutate(td_start = .data$td + win_start) %>%
        dplyr::select(-.data$td) %>%
        dplyr::inner_join(annc_dates, by = structure(names = end_event_date, .Data = "annc_date")) %>%
        dplyr::mutate(td_end = .data$td + win_end) %>%
        dplyr::select(-.data$td)

    event_dates <-
        event_tds %>%
        dplyr::inner_join(trading_dates, by=c("td_start"="td")) %>%
        dplyr::rename(start_date = date) %>%
        dplyr::inner_join(trading_dates, by=c("td_end"="td")) %>%
        dplyr::rename(end_date = date) %>%
        dplyr::select(-.data$td_start, -.data$td_end)

    event_dates
}
