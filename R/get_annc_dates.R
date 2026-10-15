#' Produce a table mapping announcements to trading dates
#'
#' Produce a table mapping announcements to trading dates.
#'
#' @param conn connection to a PostgreSQL or DuckDB database
#'
#' @return A tibble with `annc_date` (each calendar date) and `td` (the index
#'   of that date's trading day, or the next trading day for a non-trading date).
#' @export
#' @importFrom rlang .data
#' @examples
#' \dontrun{
#' # Requires an authenticated PostgreSQL connection with access to CRSP data.
#' local({
#'   pg <- DBI::dbConnect(RPostgres::Postgres())
#'   on.exit(DBI::dbDisconnect(pg), add = TRUE)
#'   head(get_annc_dates(pg))
#' })
#' }
get_annc_dates <- function(conn) {

    trading_dates <- farr::get_trading_dates(conn)

    annc_dates <-
        dplyr::tibble(annc_date = seq(min(trading_dates$date),
                               max(trading_dates$date), 1)) %>%
        dplyr::left_join(trading_dates, by = c("annc_date"="date")) %>%
        tidyr::fill(.data$td, .direction = "up")

    annc_dates
}
