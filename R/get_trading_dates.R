#' Produce a table mapping dates on CRSP to "trading days"
#'
#' Produce a table mapping dates on CRSP to "trading days".
#' Returned table has two columns: date, a trading date on CRSP;
#' td, a sequence of integers ordered by date.
#'
#' @param conn connection to a PostgreSQL database
#'
#' @return tbl_df
#' @export
#' @importFrom rlang .data
#' @examples
#' \dontrun{
#' library(DBI)
#' library(dplyr, warn.conflicts = FALSE)
#' pg <- dbConnect(RPostgres::Postgres())
#' get_trading_dates(pg) %>%
#'   filter(between(date, as.Date("2022-03-18"), as.Date("2022-03-31")))
#' }
get_trading_dates <- function(conn) {

    if (inherits(conn, "duckdb_connection")) {
        dsi <- farr::load_parquet(conn, "dsi", "crsp")
    } else {
        dsi <- dplyr::tbl(conn, dplyr::sql("SELECT * FROM crsp.dsi"))
    }
    trading_dates <-
        dsi %>%
        dplyr::select(date) %>%
        dplyr::collect() %>%
        dplyr::arrange(date) %>%
        dplyr::mutate(td = dplyr::row_number())

    trading_dates
}
