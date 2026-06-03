# Produce a table of cumulative event returns

Produce a table of event returns from CRSP.

## Usage

``` r
get_event_cum_rets(
  data,
  conn,
  permno = "permno",
  event_date = "event_date",
  win_start = 0,
  win_end = 0,
  end_event_date = NULL,
  suffix = ""
)
```

## Arguments

- data:

  data frame containing data on events

- conn:

  connection to a PostgreSQL or DuckDB database

- permno:

  string representing column containing PERMNOs for events

- event_date:

  string representing column containing dates for events

- win_start:

  integer representing start of trading window (e.g., -1)

- win_end:

  integer representing start of trading window (e.g., 1)

- end_event_date:

  string representing column containing ending dates for events

- suffix:

  Text to be appended after "ret" in variable names

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
events <- tibble(permno = c(14593L, 10107L),
                 event_date = as.Date(c("2019-01-31", "2019-01-31")))
get_event_cum_rets(events, pg)
} # }
## End(Not run)
```
