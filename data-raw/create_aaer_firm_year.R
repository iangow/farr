library(readr)
library(dplyr, warn.conflicts = FALSE)
library(stringr)
library(tidyr)

jar_data <-
    read_csv("data-raw/data_FraudDetection_JAR2020.csv.gz") %>%
    mutate(gvkey = str_pad(gvkey, 6, side = "left", pad = "0"),
           fyear = as.integer(fyear))

jar_fraud_features <-
    jar_data %>%
    select(fyear, gvkey, act:prcc_f)

jar_frauds <-
    jar_data %>%
    filter(!is.na(p_aaer)) %>%
    select(gvkey, fyear, p_aaer, new_p_aaer, understatement) %>%
    mutate(understatement = as.logical(understatement))

aaer_firm_year <-
    jar_frauds %>%
    group_by(gvkey, p_aaer) %>%
    summarize(min_year = min(fyear), max_year = max(fyear), .groups = 'drop')

aaer_firm_year %>%
    rowwise() %>%
    mutate(years = list(seq(min_year, max_year, by = 1))) %>%
    select(gvkey, p_aaer, years) %>%
    unnest(years) %>%
    rename(fyear = years)

usethis::use_data(jar_fraud_features, version = 3, compress="xz", overwrite=TRUE)
usethis::use_data(aaer_firm_year, version = 3, compress="xz", overwrite=TRUE)
