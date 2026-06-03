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
