library(dplyr, warn.conflicts = FALSE)
library(DBI)
library(tidyverse)
library(farr)

db <- dbConnect(duckdb::duckdb())

ciq_capstrct <- "ciq" # "ciq_capstrct"
ciq_common <- "ciq" # "ciq_common"
ciqfininstance <- load_parquet(db, "ciqfininstance", ciq_capstrct)
ciqfinperiod <- load_parquet(db, "ciqfinperiod", ciq_capstrct)
ciqgvkeyiid <- load_parquet(db, "ciqgvkeyiid", ciq_common)

ciq_data <-
  ciqfininstance %>%
  inner_join(ciqfinperiod, by = "financialperiodid") %>%
  inner_join(ciqgvkeyiid, by=c("companyid"="relatedcompanyid"))

ciq_acc_nos <-
  ciq_data %>%
  filter(!is.na(accessionnumber)) %>%
  distinct(gvkey, iid, accessionnumber) %>%
  compute()

# sec_index <- tbl(db, sql("SELECT * FROM 'data/index*.parquet'"))
sec_index <- load_parquet(db, "sec_index*", "edgar")
acc_no_regex <- "edgar/data/\\d+/(.*)\\.txt$"

accession_numbers <-
  sec_index |>
  mutate(accessionnumber = regexp_replace(file_name, !!acc_no_regex, "\\1"))

gvkey_ciks <-
  ciq_acc_nos %>%
  inner_join(accession_numbers, by = "accessionnumber") |>
  group_by(gvkey, iid, cik) |>
  summarize(first_date = min(date_filed, na.rm = TRUE),
            last_date = max(date_filed, na.rm = TRUE),
            .groups = "drop") |>
  collect()

usethis::use_data(gvkey_ciks, version = 3, compress = "xz", overwrite = TRUE)

# dbExecute(db, "COPY gvkey_ciks TO 'data/gvkey_ciks.parquet' (FORMAT PARQUET)")
