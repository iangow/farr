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

A tibble with `annc_date` (each calendar date) and `td` (the index of
that date's trading day, or the next trading day for a non-trading
date).

## Examples

``` r
if (FALSE) { # \dontrun{
# Requires an authenticated PostgreSQL connection with access to CRSP data.
local({
  pg <- DBI::dbConnect(RPostgres::Postgres())
  on.exit(DBI::dbDisconnect(pg), add = TRUE)
  head(get_annc_dates(pg))
})
} # }
```
