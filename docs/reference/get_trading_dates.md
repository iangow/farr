# Produce a table mapping dates on CRSP to "trading days"

Produce a table mapping dates on CRSP to "trading days". Returned table
has two columns: date, a trading date on CRSP; td, a sequence of
integers ordered by date.

## Usage

``` r
get_trading_dates(conn)
```

## Arguments

- conn:

  connection to a PostgreSQL or DuckDB database

## Value

A tibble with columns `date` (CRSP trading dates) and `td` (consecutive
integer indices ordered by date).

## Examples

``` r
if (FALSE) { # \dontrun{
# Requires an authenticated PostgreSQL connection with access to CRSP data.
local({
  pg <- DBI::dbConnect(RPostgres::Postgres())
  on.exit(DBI::dbDisconnect(pg), add = TRUE)
  head(get_trading_dates(pg))
})
} # }
```
