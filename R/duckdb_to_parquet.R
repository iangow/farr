#' Export a DuckDB-backed lazy table to Parquet via COPY
#'
#' Writes the result of a DuckDB query (or table) to a Parquet file using
#' DuckDB's `COPY (SELECT ...) TO ... (FORMAT PARQUET)` and returns a dbplyr
#' table that reads the written Parquet file.
#'
#' @param data A DuckDB-backed dbplyr table / lazy query (e.g., a `tbl_duckdb_connection`).
#' @param name File stem (used to create `{name}.parquet`).
#' @param schema Subdirectory within `data_dir` to write to (can be `""`).
#' @param data_dir Base directory of your data repository. If `NULL`, uses `Sys.getenv("DATA_DIR")`.
#' @param overwrite Logical; overwrite existing Parquet file?
#'
#' @return A dbplyr table (lazy) reading the written Parquet file.
#' @export
duckdb_to_parquet <- function(data,
                              name,
                              schema,
                              data_dir = NULL,
                              overwrite = TRUE) {

    # --- Validate / normalize inputs ---
    stopifnot(length(name) == 1L, is.character(name), nzchar(name))
    stopifnot(length(schema) == 1L, is.character(schema))

    db <- dbplyr::remote_con(data)

    if (is.null(data_dir)) {
        data_dir <- Sys.getenv("DATA_DIR", unset = "")
        if (!nzchar(data_dir)) {
            stop("`data_dir` is NULL and environment variable DATA_DIR is not set.")
        }
    }

    out_dir <- file.path(data_dir, schema)
    if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)

    pq_path <- normalizePath(file.path(out_dir, paste0(name, ".parquet")),
                             winslash = "/", mustWork = FALSE)

    if (!overwrite && file.exists(pq_path)) {
        stop("File already exists: ", pq_path, "\nSet `overwrite = TRUE` to replace it.")
    }

    # Escape single quotes for SQL string literal
    pq_path_sql <- gsub("'", "''", pq_path, fixed = TRUE)

    # --- Render query and COPY to parquet ---
    table_sql <- dbplyr::sql_render(data)

    sql <- paste0(
        "COPY (", table_sql, ") TO '", pq_path_sql, "' (FORMAT PARQUET);"
    )

    DBI::dbExecute(db, sql)

    # --- Return a lazy table reading the parquet ---
    dplyr::tbl(db, paste0("read_parquet('", pq_path_sql, "')"))
}
