library(googledrive)
library(readr)
library(dplyr, warn.conflicts = FALSE)
library(lubridate)

url <- "https://drive.google.com/file/d/18G-HS7sK8Jy_oCcj_bLQYe_koW1-nIh4"
local_path <- "data-raw/lm_edgar.csv"
try(drive_download(url, path = local_path, overwrite = FALSE))

headers <- read_csv(local_path)

state_data <-
    headers %>%
    filter(!is.na(ba_state)) %>%
    select(cik, file_date, ba_state) %>%
    mutate(file_date = ymd(file_date))

state_data_windows <-
    state_data %>%
    group_by(cik) %>%
    arrange(file_date) %>%
    mutate(window_inc = is.na(lag(ba_state)) | lag(ba_state) != ba_state) %>%
    mutate(window = cumsum(window_inc)) %>%
    ungroup() %>%
    group_by(cik, ba_state, window) %>%
    summarize(min_date = min(file_date),
              max_date = max(file_date),
              .groups = "drop") %>%
    select(-window) %>%
    arrange(cik, min_date)

state_hq <-
    state_data_windows %>%
    group_by(cik) %>%
    arrange(min_date) %>%
    mutate(min_date = if_else(min_date > lag(max_date) &
                                  !is.na(lag(max_date)), lag(max_date) + 1,
                              min_date)) %>%
    ungroup()

usethis::use_data(state_hq, version = 3, compress="xz", overwrite=TRUE)
