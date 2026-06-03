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

tbl_df

## Examples

``` r
if (FALSE) { # \dontrun{
library(DBI)
library(dplyr, warn.conflicts = FALSE)
pg <- dbConnect(RPostgres::Postgres())
get_trading_dates(pg) %>%
  filter(between(date, as.Date("2022-03-18"), as.Date("2022-03-31")))
} # }
```
