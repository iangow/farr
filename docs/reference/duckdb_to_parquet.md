# Export a DuckDB-backed lazy table to Parquet via COPY

Writes the result of a DuckDB query (or table) to a Parquet file using
DuckDB's `COPY (SELECT ...) TO ... (FORMAT PARQUET)` and returns a
dbplyr table that reads the written Parquet file.

## Usage

``` r
duckdb_to_parquet(data, name, schema, data_dir = NULL, overwrite = TRUE)
```

## Arguments

- data:

  A DuckDB-backed dbplyr table / lazy query (e.g., a
  `tbl_duckdb_connection`).

- name:

  File stem (used to create `{name}.parquet`).

- schema:

  Subdirectory within `data_dir` to write to (can be `""`).

- data_dir:

  Base directory of your data repository. If `NULL`, uses
  `Sys.getenv("DATA_DIR")`.

- overwrite:

  Logical; overwrite existing Parquet file?

## Value

A dbplyr table (lazy) reading the written Parquet file.

## Examples

``` r
if (requireNamespace("duckdb", quietly = TRUE)) {
  local({
    conn <- DBI::dbConnect(duckdb::duckdb(),
                           config = list(threads = 2, home_directory = tempdir()))
    on.exit(DBI::dbDisconnect(conn, shutdown = TRUE), add = TRUE)
    data_dir <- tempfile("farr-example-")
    on.exit(unlink(data_dir, recursive = TRUE), add = TRUE)
    data <- dplyr::copy_to(conn, data.frame(id = 1:3, value = c(10, 20, 30)),
                           "example_data")
    saved <- duckdb_to_parquet(data, "example_data", schema = "",
                               data_dir = data_dir)
    dplyr::collect(saved)
    loaded <- load_parquet(conn, "example_data", data_dir = data_dir)
    dplyr::collect(loaded)
  })
}
#> duckdb is storing downloaded extensions and secrets under ~/.duckdb:
#> ℹ /Users/igow/.duckdb
#> This persists across sessions and is shared with the DuckDB CLI and other clients.
#> ℹ Run duckdb(shared_home = FALSE) to use a temporary directory instead.
#> ℹ See ?duckdb_storage for details and alternatives.
#> # A tibble: 3 × 2
#>      id value
#>   <int> <dbl>
#> 1     1    10
#> 2     2    20
#> 3     3    30
```
