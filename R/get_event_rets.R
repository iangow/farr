#' Produce a table of event returns
#'
#' Produce a table of event returns from CRSP
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
get_event_rets <- function(data, conn,
                           permno = "permno",
                           event_date = "event_date",
                           win_start = 0, win_end = 0,
                           end_event_date = NULL) {

    if (is.null(end_event_date)) {
        data_local <-
            data %>%
            dplyr::select(.data[[permno]], .data[[event_date]])
        end_event_date <- event_date
        drop_end_event_date <- TRUE
    } else {
        data_local <-
            data %>%
            dplyr::select(.data[[permno]], .data[[event_date]],
                          .data[[end_event_date]])
        drop_end_event_date <- FALSE
    }

    event_dates <-
        get_event_dates(data_local, conn, permno = permno,
                        event_date = event_date,
                        win_start = win_start, win_end = win_end,
                        end_event_date = end_event_date) %>%
        dplyr::select(.data$permno, dplyr::one_of(event_date, end_event_date),
                      .data$start_date, .data$end_date)

    crsp.dsedelist <- dplyr::tbl(conn, dplyr::sql("SELECT * FROM crsp.dsedelist"))
    crsp.dsf <- dplyr::tbl(conn, dplyr::sql("SELECT * FROM crsp.dsf"))
    crsp.erdport1 <- dplyr::tbl(conn, dplyr::sql("SELECT * FROM crsp.erdport1"))
    crsp.dsi <- dplyr::tbl(conn, dplyr::sql("SELECT * FROM crsp.dsi"))

    dsedelist <-
        crsp.dsedelist %>%
        dplyr::select(.data$permno, date = .data$dlstdt, .data$dlret) %>%
        dplyr::filter(!is.na(.data$dlret))

    dsf_plus <-
        crsp.dsf %>%
        dplyr::full_join(dsedelist, by = c("permno", "date")) %>%
        dplyr::mutate(ret = (1 + dplyr::coalesce(.data$ret, 0)) * (1 + dplyr::coalesce(.data$dlret, 0)) - 1) %>%
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

    results_raw <-
        event_dates %>%
        dbplyr::copy_inline(con = conn, df = .data) %>%
        dplyr::inner_join(rets, by = "permno") %>%
        dplyr::filter(dplyr::between(.data$date, .data$start_date,
                                     .data$end_date)) %>%
        dplyr::collect()

    trading_dates <- farr::get_trading_dates(conn)

    event_tds <-
        event_dates %>%
        dplyr::inner_join(trading_dates,
                          by = structure(names = event_date, .Data = "date")) %>%
        dplyr::rename(event_td = .data$td) %>%
        dplyr::select(.data$permno, .data[[event_date]], .data$event_td)

    results <-
        results_raw %>%
        dplyr::inner_join(trading_dates, by="date") %>%
        dplyr::inner_join(event_tds, c("permno"="permno",
                                       structure(names = event_date,
                                                 .Data = event_date))) %>%
        dplyr::mutate(relative_td = .data$td - .data$event_td) %>%
        dplyr::select(-.data$td, -.data$event_td)

    results
}
