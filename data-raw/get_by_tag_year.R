library(dplyr, warn.conflicts = FALSE)
library(readr)
library(ggplot2)

url <- paste("https://gist.githubusercontent.com/iangow",
             "b79203e61937386f2bf26c4bbeabce72",
             "raw/2a7605a5054fe4e0be0a73018ae0414cd9ed8515",
             "by_tag_year.csv", sep="/")

by_tag_year <- read_csv(url, col_types = "icii")

save(by_tag_year, file="data/by_tag_year.RData")
