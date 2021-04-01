df_to_pg <- function(df, conn) {

    convert_vec <- function(vec) {
        if (class(vec)=="character") {
            convert_char(vec)
        } else if (class(vec)=="Date") {
            convert_date(vec)
        } else if (class(vec)=="integer") {
            convert_int(vec)
        } else if (class(vec)=="numeric") {
            convert_num(vec)
        }
    }

    make_string <- function(vec) {
        paste0("'{", paste(paste0('"', vec, '"'), collapse=","), "}'")
    }

    convert_char <- function(vec) {
        paste0(make_string(vec), "::text[]")
    }

    convert_int <- function(vec) {
        paste0(make_string(vec), "::integer[]")
    }

    convert_date <- function(vec) {
        paste0(make_string(vec), "::date[]")
    }

    convert_num <- function(vec) {
        paste0(make_string(vec), "::float8[]")
    }

    temp_starter_sql <- list()
    for (i in 1:length(df)) {
        temp_starter_sql[[i]] = paste0("UNNEST (",
                                       convert_vec(df[[i]]), ") AS ",
                                       names(df)[[i]])
    }

    temp_sql <- paste0("SELECT ", paste0(temp_starter_sql, collapse = ",\n"))

    temp_df_sql <- tbl(conn, sql(temp_sql))
    return(temp_df_sql)
}
