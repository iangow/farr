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

Remote data frame in conn
