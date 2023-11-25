#' Function to load parquet file into database.
#'
#' Function to read data from a parquet file data_dir/schema/table_name.parquet
#' into a table in the DuckDB database at conn.
#'
#' @param conn DuckDB connection
#' @param schema Database schema for table
#' @param table_name Name of table to be loaded
#' @param data_dir Directory for data repository
#'
#' @return Remote data frame in conn
#' @export
load_parquet <- function(conn, schema, table_name,
                         data_dir = Sys.getenv("DATA_DIR")) {
    file_path <- file.path(data_dir, schema,
                           paste0(table_name, ".parquet"))
    df_sql <- paste0("SELECT * FROM read_parquet('", file_path, "')")
    dplyr::tbl(conn, dplyr::sql(df_sql))
}
