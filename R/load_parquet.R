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
#' @return A lazy dbplyr table backed by `conn`, with the columns and rows
#'   stored in the requested Parquet file. Use `dplyr::collect()` to retrieve it.
#' @export
#' @examples
#' if (requireNamespace("duckdb", quietly = TRUE)) {
#'   local({
#'     conn <- DBI::dbConnect(duckdb::duckdb(),
#'                            config = list(threads = 2, home_directory = tempdir()))
#'     on.exit(DBI::dbDisconnect(conn, shutdown = TRUE), add = TRUE)
#'     data_dir <- tempfile("farr-example-")
#'     on.exit(unlink(data_dir, recursive = TRUE), add = TRUE)
#'     data <- dplyr::copy_to(conn, data.frame(id = 1:3, value = c(10, 20, 30)),
#'                            "example_data")
#'     saved <- duckdb_to_parquet(data, "example_data", schema = "",
#'                                data_dir = data_dir)
#'     dplyr::collect(saved)
#'     loaded <- load_parquet(conn, "example_data", data_dir = data_dir)
#'     dplyr::collect(loaded)
#'   })
#' }
load_parquet <- function(conn, table, schema = "",
                         data_dir = Sys.getenv("DATA_DIR")) {
    file_path <- file.path(data_dir, schema,
                           paste0(table, ".parquet"))
    df_sql <- paste0("SELECT * FROM read_parquet('", file_path, "')")
    dplyr::tbl(conn, dplyr::sql(df_sql))
}
