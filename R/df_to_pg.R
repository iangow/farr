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

    collapse <- function(x) paste0("(", paste(x, collapse = ", "), ")")

    names <- paste(DBI::dbQuoteIdentifier(conn, names(df)), collapse = ", ")

    values <-
        df %>%
        lapply(DBI::dbQuoteLiteral, conn = conn) %>%
        purrr::transpose() %>%
        lapply(collapse) %>%
        paste(collapse = ",\n")

    inline_sql <- paste("SELECT * FROM (VALUES", values, ") AS t (", names, ")")

    dplyr::tbl(conn, dplyr::sql(inline_sql))
}

