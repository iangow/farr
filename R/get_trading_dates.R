#' Produce a table mapping dates on CRSP to "trading days"
#'
#' Produce a table mapping dates on CRSP to "trading days".
#' Returned table has two columns: date, a trading date on CRSP;
#' td, a sequence of integers ordered by date.
#'
#' @param conn connection to a PostgreSQL or DuckDB database
#'
#' @return A tibble with columns `date` (CRSP trading dates) and `td`
#'   (consecutive integer indices ordered by date).
#' @export
#' @importFrom rlang .data
#' @examples
#' \dontrun{
#' # Requires an authenticated PostgreSQL connection with access to CRSP data.
#' local({
#'   pg <- DBI::dbConnect(RPostgres::Postgres())
#'   on.exit(DBI::dbDisconnect(pg), add = TRUE)
#'   head(get_trading_dates(pg))
#' })
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
