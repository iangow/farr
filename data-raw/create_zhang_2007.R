library(googlesheets4)
library(dplyr, warn.conflicts = FALSE)
library(farr)
library(DBI)

zhang_2007_key <- "1KRtcaWqU0x50V2lI2uujvG1xZDz6oGQyIQ5re2WHAls"

zhang_2007_windows <-
  read_sheet(zhang_2007_key, sheet = "windows") %>%
  mutate(across(ends_with("date"), as.Date)) %>%
  select(-est, -t_stat)

zhang_2007_events <-
  read_sheet(zhang_2007_key, sheet = "events") %>%
  mutate(across(ends_with("date"), as.Date))

pg <- dbConnect(RPostgres::Postgres())

tds <- get_trading_dates(pg)

zhang_2007_windows %>%
  inner_join(tds, by = c("beg_date"="date")) %>%
  rename(beg_td = td) %>%
  inner_join(tds, by = c("end_date"="date")) %>%
  rename(end_td = td) %>%
  mutate(td = end_td - beg_td + 1)

