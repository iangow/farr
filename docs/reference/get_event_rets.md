# Produce a table of event returns

Produce a table of event returns from CRSP.

## Usage

``` r
get_event_rets(
  data,
  conn,
  permno = "permno",
  event_date = "event_date",
  win_start = 0,
  win_end = 0,
  end_event_date = NULL
)
```

## Arguments

- data:

  data frame containing data on events

- conn:

  connection to a PostgreSQL database

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

## Value

tbl_df

## Examples

``` r
## Not run:
if (FALSE) { # \dontrun{
library(DBI)
library(dplyr, warn.conflicts = FALSE)
pg <- dbConnect(RPostgres::Postgres())
events <- tibble(permno = c(14593L, 10107L),
                 event_date = as.Date(c("2019-01-31", "2019-01-31")))
get_event_rets(events, pg, win_start = -3, win_end = +3) %>%
  select(permno, event_date, date, ret)
} # }
## End(Not run)
```
