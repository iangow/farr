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

    conn <- DBI::dbConnect(duckdb::duckdb())
    pg <- DBI::dbConnect(RPostgres::Postgres())
    temp <- dplyr::tbl(pg, dbplyr::in_schema(schema, table_name))
    dplyr::copy_to(conn, df = temp, name = "temp_table", overwrite = TRUE)

    schema_dir <- file.path(data_dir, schema)
    if (!dir.exists(schema_dir)) dir.create(schema_dir)
    to_file <- file.path(schema_dir, paste0(table_name, ".parquet"))
    to <- paste0("TO '", to_file, "' (format 'parquet')")
    DBI::dbDisconnect(pg)
    res <- DBI::dbExecute(conn, paste("COPY temp_table", to))
    res
}
