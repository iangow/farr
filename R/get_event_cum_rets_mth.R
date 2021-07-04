#' Produce a table of cumulative event returns using monthly data
#'
#' Produce a table of event returns from CRSP
#'
#' @param data data frame containing data on events
#' @param permno string representing column containing PERMNOs for events
#' @param event_date string representing column containing dates for events
#' @param conn connection to a PostgreSQL database
#' @param win_start integer representing start of trading window (e.g., -1) in
#' months
#' @param win_end integer representing start of trading window (e.g., 1) in months
#' @param end_event_date string representing column containing ending dates for
#' events
#' @param suffix Text to be appended after "ret" in variable names.
#'
#' @return tbl_df
#' @export
#' @importFrom rlang .data
get_event_cum_rets_mth <- function(data, conn,
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

    rets_exists <- DBI::dbExistsTable(conn, DBI::Id(table = "mrets",
                                                  schema = "crsp"))

    crsp.msi <- dplyr::tbl(conn, dplyr::sql("SELECT * FROM crsp.msi"))

    if (rets_exists) {
        mrets <-  dplyr::tbl(conn, dplyr::sql("SELECT * FROM crsp.mrets"))
    } else {
        crsp.msedelist <- dplyr::tbl(conn,
                                     dplyr::sql("SELECT * FROM crsp.msedelist"))
        crsp.msf <- dplyr::tbl(conn,
                               dplyr::sql("SELECT * FROM crsp.msf"))
        crsp.ermport1 <- dplyr::tbl(conn,
                                    dplyr::sql("SELECT * FROM crsp.ermport1"))

        msedelist <-
            crsp.msedelist %>%
            dplyr::select(permno, date = .data$dlstdt, .data$dlret) %>%
            dplyr::filter(!is.na(.data$dlret))

        msf_plus <-
            crsp.msf %>%
            dplyr::full_join(msedelist, by = c("permno", "date")) %>%
            dplyr::filter(!is.na(.data$ret) | !is.na(.data$dlret)) %>%
            dplyr::mutate(ret = (1 + dplyr::coalesce(.data$ret, 0)) *
                              (1 + dplyr::coalesce(.data$dlret, 0)) - 1) %>%
            dplyr::select(.data$permno, .data$date, .data$ret)

        ermport <-
            crsp.ermport1 %>%
            dplyr::select(.data$permno, .data$date, .data$decret)

        msf_w_ermport <-
            msf_plus %>%
            dplyr::left_join(ermport, by = c("permno", "date"))

        msi <-
            crsp.msi %>%
            dplyr::select(.data$date, .data$vwretd)

        mrets <-
            msf_w_ermport %>%
            dplyr::left_join(msi, by = "date")
    }

    events <-
        data_local %>%
        farr::df_to_pg(conn)

    begin_date_sql <- paste0("date_trunc('MONTH', ", event_date, ") + (",
                             win_start, " * interval '1 month')")
    begin_date <- dplyr::sql(begin_date_sql)

    end_date_sql <- paste0("(date_trunc('MONTH', ", end_event_date, ") + ",
                           "interval '1 month' - interval '1 day') + (",
                           win_end, " * interval '1 month')")
    end_date <- dplyr::sql(end_date_sql)

    results <-
        events %>%
        dplyr::inner_join(mrets, by = "permno") %>%
        dplyr::filter(dplyr::between(.data$date, !!begin_date, !!end_date)) %>%
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
