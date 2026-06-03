# Produce a table mapping announcements to trading dates

Produce a table mapping announcements to trading dates.

## Usage

``` r
get_annc_dates(conn)
```

## Arguments

- conn:

  connection to a PostgreSQL or DuckDB database

## Value

tbl_df

## Examples

``` r
## Not run:
if (FALSE) { # \dontrun{
library(DBI)
library(dplyr, warn.conflicts = FALSE)
library(RPostgres)
pg <- dbConnect(Postgres())
get_annc_dates(pg)
} # }
## End(Not run)
```
