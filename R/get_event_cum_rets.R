#' Produce a table of cumulative event returns
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
get_event_cum_rets <- function(data, conn,
                            permno = "permno",
                            event_date = "event_date",
                            win_start = 0, win_end = 0,
                            end_event_date = NULL) {

    if (is.null(end_event_date)) {
        end_event_date <- event_date
        drop_end_event_date <- TRUE
    } else {
        drop_end_event_date <- FALSE
    }

    event_dates <- get_event_dates(data, conn, permno = permno,
                                   event_date = event_date,
                                   win_start = win_start, win_end = win_end,
                                   end_event_date = end_event_date)


    crsp.dsedelist <- dplyr::tbl(conn, dplyr::sql("SELECT * FROM crsp.dsedelist"))
    crsp.dsf <- dplyr::tbl(conn, dplyr::sql("SELECT * FROM crsp.dsf"))
    crsp.erdport1 <- dplyr::tbl(conn, dplyr::sql("SELECT * FROM crsp.erdport1"))
    crsp.dsi <- dplyr::tbl(conn, dplyr::sql("SELECT * FROM crsp.dsi"))

    dsedelist <-
        crsp.dsedelist %>%
        dplyr::select(permno, date = .data$dlstdt, .data$dlret) %>%
        dplyr::filter(!is.na(.data$dlret))

    dsf_plus <-
        crsp.dsf %>%
        dplyr::full_join(dsedelist, by = c("permno", "date")) %>%
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

    results <-
        event_dates %>%
        farr::df_to_pg(conn) %>%
        dplyr::inner_join(rets, by="permno") %>%
        dplyr::filter(dplyr::between(.data$date, .data$start_date, .data$end_date)) %>%
        dplyr::group_by(.data$permno, event_date, end_event_date) %>%
        dplyr::summarize(ret_raw =
                      exp(sum(dplyr::sql("ln((1 + ret))"), na.rm = TRUE)) - 1,
                  ret_mkt =
                      exp(sum(dplyr::sql("ln((1 + ret))"), na.rm = TRUE)) -
                      exp(sum(dplyr::sql("ln((1 + vwretd))"), na.rm = TRUE)) ,
                  ret_sz =
                      exp(sum(dplyr::sql("ln((1 + ret))"), na.rm = TRUE)) -
                      exp(sum(dplyr::sql("ln((1 + decret))"), na.rm = TRUE)),
                  .groups = "drop")

    if (drop_end_event_date) {
        results %>%
            dplyr::select(-end_event_date) %>%
            dplyr::collect()
    } else {
        results %>%
            dplyr::collect()
    }
}

