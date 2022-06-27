#' Produce a table mapping announcements to trading dates
#'
#' Produce a table mapping announcements to trading dates
#'
#' @param conn connection to a PostgreSQL database
#'
#' @return tbl_df
#' @export
#' @importFrom rlang .data
#' @examples
#' ## Not run:
#' library(DBI)
#' library(dplyr, warn.conflicts = FALSE)
#' library(RPostgres)
#' pg <- dbConnect(Postgres())
#' get_annc_dates(pg)
#' ## End(Not run)
get_annc_dates <- function(conn) {

    dsi <- dplyr::tbl(conn, dplyr::sql("SELECT * FROM crsp.dsi"))

    trading_dates <- farr::get_trading_dates(conn)

    annc_dates <-
        dplyr::tibble(annc_date = seq(min(trading_dates$date),
                               max(trading_dates$date), 1)) %>%
        dplyr::left_join(trading_dates, by = c("annc_date"="date")) %>%
        tidyr::fill(.data$td, .direction = "up")

    annc_dates
}
