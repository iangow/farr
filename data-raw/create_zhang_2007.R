library(googlesheets4)
library(dplyr, warn.conflicts = FALSE)

zhang_2007_key <- "1KRtcaWqU0x50V2lI2uujvG1xZDz6oGQyIQ5re2WHAls"

zhang_2007_windows <-
  read_sheet(zhang_2007_key, sheet = "windows") %>%
  mutate(across(ends_with("date"), as.Date),
         event = as.integer(event)) %>%
  select(-est, -t_stat)

zhang_2007_events <-
  read_sheet(zhang_2007_key, sheet = "events") %>%
  mutate(across(ends_with("date"), as.Date),
         event = as.integer(event))

usethis::use_data(zhang_2007_windows,
                  version = 3, compress="xz", overwrite=TRUE)
usethis::use_data(zhang_2007_events,
                  version = 3, compress="xz", overwrite=TRUE)

