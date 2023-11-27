#' Function to load parquet file into database.
#'
#' Function to read data from a parquet file data_dir/schema/table_name.parquet
#' into a table in the DuckDB database at conn.
#'
#' @param conn DuckDB connection
#' @param table Name of table to be loaded
#' @param schema Database schema for table
#' @param data_dir Directory for data repository
#'
#' @return Remote data frame in conn
#' @export
load_parquet <- function(conn, table, schema = "",
                         data_dir = Sys.getenv("DATA_DIR")) {
    file_path <- file.path(data_dir, schema,
                           paste0(table, ".parquet"))
    df_sql <- paste0("SELECT * FROM read_parquet('", file_path, "')")
    dplyr::tbl(conn, dplyr::sql(df_sql))
}
