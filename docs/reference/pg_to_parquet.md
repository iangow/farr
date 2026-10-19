# Save WRDS table as parquet file.

Function to get data from a table on the WRDS PostgreSQL server and save
to local parquet file using DuckDB.

## Usage

``` r
pg_to_parquet(table_name, schema, data_dir = Sys.getenv("DATA_DIR"))
```

## Arguments

- table_name:

  Name of table on WRDS

- schema:

  Database schema for table

- data_dir:

  Directory for data repository

## Value

Number of rows created

## Examples

``` r
if (FALSE) { # \dontrun{
# Requires PostgreSQL credentials for a WRDS database and the duckdb package.
local({
  data_dir <- tempfile("farr-example-")
  dir.create(data_dir)
  on.exit(unlink(data_dir, recursive = TRUE), add = TRUE)
  pg_to_parquet("dsi", "crsp", data_dir = data_dir)
})
} # }
```
