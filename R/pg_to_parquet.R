#' Save WRDS table as parquet file.
#'
#' Function to get data from a table on the WRDS PostgreSQL server and
#' save to local parquet file using DuckDB.
#'
#' @param table_name Name of table on WRDS
#' @param schema Database schema for table
#' @param data_dir Directory for data repository
#'
#' @return Number of rows created
#' @export
pg_to_parquet <- function(table_name, schema,
                          data_dir = Sys.getenv("DATA_DIR")) {
    orig_warn <- getOption("warn")
    options(warn = -1)
    pg_to_parquet_temp(table_name, schema, data_dir)
    options(warn = orig_warn)
}

pg_to_parquet_temp <- function(table_name, schema, data_dir)
{
    temp_file <- tempfile()
    conn <- DBI::dbConnect(duckdb::duckdb(), dbdir = temp_file)
    DBI::dbExecute(conn, 'DROP TABLE IF EXISTS temp_table')
    duckdb::dbDisconnect(conn)

    pg <- DBI::dbConnect(RPostgres::Postgres())
    res <- DBI::dbSendQuery(pg, paste0('SELECT * FROM "', schema, '"."', table_name, '"'))

    write_table <- function(df) {
        conn <- DBI::dbConnect(duckdb::duckdb(), dbdir = temp_file)
        duckdb::dbWriteTable(conn, "temp_table", df, append = TRUE, temporary = FALSE)
        DBI::dbDisconnect(conn)
    }

    repeat {
        temp_table <- DBI::dbFetch(res, n = 10000)
        write_table(temp_table)
        if (DBI::dbHasCompleted(res)) {
            DBI::dbClearResult(res)
            DBI::dbDisconnect(pg)
            break
        }
    }

    schema_dir <- file.path(data_dir, schema)
    if (!dir.exists(schema_dir)) dir.create(schema_dir)
    to_file <- file.path(schema_dir, paste0(table_name, ".parquet"))
    to <- paste0("TO '", to_file, "' (format 'parquet')")
    conn <- DBI::dbConnect(duckdb::duckdb(), dbdir = temp_file)
    res <- DBI::dbExecute(conn, paste("COPY temp_table", to))
    DBI::dbDisconnect(conn) #, shutdown = TRUE)
    unlink(temp_file)
    res
}


