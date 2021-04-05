library(lubridate, warn.conflicts = FALSE)
library(dplyr, warn.conflicts = FALSE)
library(rvest)
library(stringr)
library(ggplot2)

res <- "https://en.wikipedia.org/wiki/List_of_Apple_Inc._media_events"
raw <-
    res %>%
    read_html() %>%
    html_node(xpath = '//*[@id="toc"]') %>%
    html_text() %>%
    strsplit(split = "\n")

date_range_regex <- "([\\d]+)–([\\d]+)"

apple_events <-
    tibble(event = unlist(raw)) %>%
    filter(str_detect(event, "[0-9]{4}\\)$")) %>%
    mutate(matches = str_match(event, "^\\d+\\.\\d+ (.*?)\\s*\\((.*)\\)$")) %>%
    mutate(event = matches[,2], date_range = matches[,3]) %>%
    mutate(event_date = str_replace(date_range, date_range_regex, "\\1"),
           end_event_date = str_replace(date_range, date_range_regex, "\\2")) %>%
    mutate(event_date = mdy(event_date),
           end_event_date = mdy(end_event_date)) %>%
    select(event, event_date, end_event_date)

apple_events

save(apple_events, file="data/apple_events.RData")
