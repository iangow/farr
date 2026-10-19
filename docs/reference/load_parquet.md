# Function to load parquet file into database.

Function to read data from a parquet file
data_dir/schema/table_name.parquet into a table in the DuckDB database
at conn.

## Usage

``` r
load_parquet(conn, table, schema = "", data_dir = Sys.getenv("DATA_DIR"))
```

## Arguments

- conn:

  DuckDB connection

- table:

  Name of table to be loaded

- schema:

  Database schema for table

- data_dir:

  Directory for data repository

## Value

A lazy dbplyr table backed by `conn`, with the columns and rows stored
in the requested Parquet file. Use
[`dplyr::collect()`](https://dplyr.tidyverse.org/reference/compute.html)
to retrieve it.

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
