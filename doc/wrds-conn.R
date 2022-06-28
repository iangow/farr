## ---- include = FALSE---------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

if (!identical(Sys.getenv("NOT_CRAN"), "true")) {
  knitr::opts_chunk$set(eval = FALSE)
}

## ----setup, message=FALSE-----------------------------------------------------
#  library(farr)
#  library(dplyr, warn.conflicts = FALSE)
#  library(DBI)

## ----db_connect, eval=FALSE---------------------------------------------------
#  Sys.setenv(PGHOST = "wrds-pgdata.wharton.upenn.edu",
#             PGPORT = 9737L,
#             PGDATABASE = "wrds",
#             PGUSER = "your_WRDS_ID",
#             PGPASSWORD = "your_WRDS_password")

## ---- eval=FALSE--------------------------------------------------------------
#  PGHOST = "wrds-pgdata.wharton.upenn.edu"
#  PGPORT = 9737L
#  PGDATABASE = "wrds"
#  PGUSER = "your_WRDS_ID"
#  PGPASSWORD="your_WRDS_password"

## -----------------------------------------------------------------------------
#  tail(apple_events)

## -----------------------------------------------------------------------------
#  pg <- dbConnect(RPostgres::Postgres(), bigint = "integer")
#  
#  stocknames <- tbl(pg, sql("SELECT * FROM crsp.stocknames"))
#  
#  apple_permno <-
#    stocknames %>%
#    filter(ticker == "AAPL") %>%
#    select(permno) %>%
#    distinct() %>%
#    pull()

## -----------------------------------------------------------------------------
#  dsf <- tbl(pg, sql("SELECT * FROM crsp.dsf"))
#  dsi <- tbl(pg, sql("SELECT * FROM crsp.dsi"))
#  
#  apple_rets <-
#    dsf %>%
#    inner_join(dsi, by = "date") %>%
#    mutate(mkt_ret = ret - vwretd) %>%
#    select(permno, date, ret, mkt_ret, vol) %>%
#    filter(permno == apple_permno,
#           date >= "2005-01-01") %>%
#    collect()

## -----------------------------------------------------------------------------
#  apple_event_dates <-
#    apple_events %>%
#    mutate(permno = apple_permno) %>%
#    get_event_dates(pg,
#                    end_event_date = "end_event_date",
#                    win_start = -1, win_end = +1)
#  
#  tail(apple_event_dates)

## -----------------------------------------------------------------------------
#  rets <-
#      apple_events %>%
#      mutate(permno = apple_permno) %>%
#      get_event_cum_rets(pg,
#                         win_start = -1, win_end = +1,
#                         end_event_date = "end_event_date")
#  
#  rets

