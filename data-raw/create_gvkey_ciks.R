library(dplyr, warn.conflicts = FALSE)
library(DBI)
library(tidyverse)

db <- dbConnect(duckdb::duckdb())
# db <- dbConnect(RPostgres::Postgres())

rs <- dbExecute(db, "LOAD postgres_scanner")
# dbExecute(db, "SET threads TO 2")
#Sys.setenv(PGHOST = "wrds-pgdata.wharton.upenn.edu",
##           PGPORT = 9737L,
#           PGDATABASE = "wrds",
#           PGUSER = "iangow")

get_pg_data <- function(table_name, schema) {
  sql_str <- paste0("SELECT * FROM postgres_scan_pushdown('',",
                    "'", schema, "', '", table_name,"')")
  # sql_str <- paste0('SELECT * FROM "', schema, '"."', table_name, '"')
  tbl(db, sql(sql_str))
}

ciq_capstrct <- "ciq" # "ciq_capstrct"
ciq_common <- "ciq" # "ciq_common"
ciqfininstance <- get_pg_data("ciqfininstance", ciq_capstrct)
ciqfinperiod <- get_pg_data("ciqfinperiod", ciq_capstrct)
ciqgvkeyiid <- get_pg_data("ciqgvkeyiid", ciq_common)

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
sec_index <- get_pg_data("filings", "edgar")
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
