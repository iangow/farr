#' Convert a data frame to a remote data frame
#'
#' Convert a data frame to a remote PostgreSQL data frame
#' even with a read-only connection.
#'
#' @param df data frame
#' @param conn connection to a PostgreSQL database
#' @param read_only Indicate that connection is read-only, so no compute() is possible
#'
#' @return tbl_sql
#' @export
df_to_pg <- function(df, conn, read_only = TRUE) {

    collapse <- function(x) paste0("(", paste(x, collapse = ", "), ")")

    names <- paste(DBI::dbQuoteIdentifier(conn, names(df)), collapse = ", ")

    values <-
        df %>%
        lapply(DBI::dbQuoteLiteral, conn = conn) %>%
        purrr::transpose() %>%
        lapply(collapse) %>%
        paste(collapse = ",\n")

    the_sql <- paste("SELECT * FROM (VALUES", values, ") AS t (", names, ")")

    temp_df_sql <- dplyr::tbl(conn, dplyr::sql(the_sql))
    if (read_only) {
        return(temp_df_sql)
    } else {
        return(dplyr::compute(temp_df_sql))
    }
}

