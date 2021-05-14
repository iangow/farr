#' Convert a data frame to a remote data frame
#'
#' Convert a data frame to a remote PostgreSQL data frame
#' even with a read-only connection.
#'
#' @param df data frame
#' @param conn connection to a PostgreSQL database
#'
#' @return tbl_sql
#' @export
df_to_pg <- function(df, conn) {

    temp_starter_sql <- list()
    for (i in 1:nrow(df)) {
        temp_starter_sql[[i]] = db_row(df[i, ], .src = conn)
    }

    Reduce(dplyr::union_all, temp_starter_sql)
}

db_row <- function(..., .src) {
    data <- dplyr::tibble(...)
    stopifnot(nrow(data) == 1)
    values <- unlist(purrr::map(data, DBI::dbQuoteLiteral, conn = .src))

    from <- dbplyr::sql(paste0("SELECT ", paste0(
        values, " AS ", DBI::dbQuoteIdentifier(.src, names(values)),
        collapse = ", "
    )))
    dplyr::tbl(.src, from, vars = names(values))
}
