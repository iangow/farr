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

    convert_vec <- function(vec) {
        paste0('ARRAY[', paste0(DBI::dbQuoteLiteral(conn, vec),
                                collapse = ", "), ']')
    }

    temp_starter_sql <- list()
    for (i in 1:length(df)) {
        temp_starter_sql[[i]] =
            paste0("UNNEST (",
                   convert_vec(df[[i]]), ") AS ",
                   DBI::dbQuoteIdentifier(conn, names(df)[[i]]))
    }

    temp_sql <- paste0("SELECT ", paste0(temp_starter_sql, collapse = ",\n"))

    temp_df_sql <- dplyr::tbl(conn, dbplyr::sql(temp_sql))
    if (read_only) {
        return(temp_df_sql)
    } else {
        return(dplyr::compute(temp_df_sql))
    }
}
