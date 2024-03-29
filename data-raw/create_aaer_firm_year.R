library(readr)
library(dplyr, warn.conflicts = FALSE)
library(stringr)
library(tidyr)

jar_data <-
    read_csv(paste0("https://raw.githubusercontent.com/JarFraud/",
                    "FraudDetection/master/",
                    "data_FraudDetection_JAR2020.csv"),
             col_types = "d") %>%
    mutate(gvkey = str_pad(gvkey, 6, side = "left", pad = "0"),
           fyear = as.integer(fyear),
           p_aaer = as.character(p_aaer))

aaer_firm_year <-
    jar_data %>%
    filter(!is.na(p_aaer)) %>%
    select(gvkey, fyear, p_aaer) %>%
    group_by(p_aaer, gvkey) %>%
    summarize(min_year = min(fyear), max_year = max(fyear), .groups = 'drop')

usethis::use_data(aaer_firm_year, version = 3, compress="xz", overwrite=TRUE)
