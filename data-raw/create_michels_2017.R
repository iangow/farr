library(readr)
library(lubridate)
library(dplyr, warn.conflicts = FALSE)
library(DBI)
library(googlesheets4)

# Link to database tables ----
pg <- dbConnect(RPostgres::Postgres(), bigint = "integer")
stocknames <- tbl(pg, sql("SELECT * FROM crsp.stocknames"))
ccmxpf_lnkhist <- tbl(pg, sql("SELECT * FROM crsp.ccmxpf_lnkhist"))
cusip_cik <- tbl(pg, sql("SELECT * FROM edgar.cusip_cik"))
wciklink_cusip <- tbl(pg, sql("SELECT * FROM wrdssec.wciklink_cusip"))
filings <- tbl(pg, sql("SELECT * FROM edgar.filings"))
fundq <- tbl(pg, sql("SELECT * FROM comp.fundq"))

# Download data from JAR website ----
t <- tempfile(fileext = ".zip")

url <- paste0("https://research.chicagobooth.edu/-/media/research/arc/",
              "docs/journal/online-supplements/michels-cusips.zip")
download.file(url, t)

files <- unzip(t, list = TRUE)
cusips <-
  read_table(unz(t, files$Name[2])) %>%
  mutate(eventdate = dmy(eventdate))

ccm_link <-
  ccmxpf_lnkhist %>%
  filter(linktype %in% c("LC", "LU", "LS"),
         linkprim %in% c("C", "P")) %>%
  rename(permno = lpermno)

# Merge data ----
ccm_link <-
  ccmxpf_lnkhist %>%
  filter(linktype %in% c("LC", "LU", "LS"),
         linkprim %in% c("C", "P")) %>%
  rename(permno = lpermno)

ciks_manual <- read_sheet("1OgGrzraShN__hEsuMFMZcSrZAdQyqXwOWxV-UeKKMqs",
                          col_types = "cDi-")

ciks_auto <-
  cusips %>%
  inner_join(wciklink_cusip, copy = TRUE, by = "cusip") %>%
  filter(eventdate >= cikdate1, eventdate <= cikdate2) %>%
  select(cusip, eventdate, cik) %>%
  mutate(cik = as.integer(cik)) %>%
  distinct()

ciks_all <-
  ciks_manual %>%
  union_all(ciks_auto %>% anti_join(ciks_manual, by = c("cusip", "eventdate")))

permnos <-
  cusips %>%
  mutate(ncusip = cusip) %>%
  inner_join(stocknames %>% select(-cusip), by="ncusip", copy = TRUE) %>%
  select(cusip, permno) %>%
  distinct()

merged <-
  ciks_all %>%
  inner_join(permnos, by = "cusip") %>%
  left_join(ccm_link, copy = TRUE, by = "permno") %>%
  filter(eventdate >= linkdt, eventdate <= linkenddt | is.na(linkenddt)) %>%
  select(cusip, eventdate, cik, permno, gvkey)


merged <- copy_to(pg, merged, overwrite = TRUE)

merged_filings_raw <-
  merged %>%
  inner_join(filings, by = "cik") %>%
  filter(form_type %in% c('10-K', '10-Q', '10-K405', '10QSB', '10KSB'))

next_filings <-
  merged_filings_raw %>%
  filter(date_filed > eventdate) %>%
  group_by(cusip, eventdate) %>%
  filter(date_filed == min(date_filed, na.rm = TRUE)) %>%
  summarize(date_filed = min(date_filed, na.rm = TRUE),
            form_types = sql("array_agg(DISTINCT form_type)"),
            .groups = "drop") %>%
  compute()

next_filings %>% count()
next_filings %>% count(form_types)

period_ends <-
  fundq %>%
  filter(indfmt == "INDL", consol == "C", popsrc == "D", datafmt == "STD") %>%
  select(gvkey, datadate, fqtr)

prev_period_end <-
  merged %>%
  inner_join(period_ends, by = "gvkey") %>%
  filter(datadate <= eventdate) %>%
  group_by(cusip, eventdate) %>%
  filter(datadate == max(datadate, na.rm = TRUE)) %>%
  ungroup() %>%
  select(cusip, eventdate, datadate, fqtr) %>%
  rename(prev_period_end = datadate,
         prev_fqtr = fqtr) %>%
  compute()


next_period_end <-
  merged %>%
  inner_join(period_ends, by = "gvkey") %>%
  filter(datadate > eventdate) %>%
  group_by(cusip, eventdate) %>%
  filter(datadate == min(datadate, na.rm = TRUE)) %>%
  ungroup() %>%
  select(cusip, eventdate, datadate, fqtr) %>%
  rename(next_period_end = datadate,
         next_fqtr = fqtr) %>%
  mutate(next_period_end = case_when(cusip == "12959810" & eventdate == "1996-07-12" ~ "1996-09-30",
                                     TRUE ~ next_period_end),
         next_fqtr = if_else(cusip == "12959810" & eventdate == "1996-07-12", 1, next_fqtr)) %>%
  compute()


final <-
  merged %>%
  inner_join(next_filings, by = c("cusip", "eventdate")) %>%
  inner_join(next_period_end, by = c("cusip", "eventdate")) %>%
  inner_join(prev_period_end, by = c("cusip", "eventdate")) %>%
  mutate(recognize = next_period_end < date_filed,
         days_to_filing = date_filed - eventdate,
         days_to_period_end = next_period_end - eventdate,
         period_length = next_period_end - prev_period_end) %>%
  compute()

final %>%
  select(-permno, -gvkey, -cik) %>%
  arrange(desc(period_length))

final %>%
  arrange(days_to_filing)

final %>%
  select(-permno, -gvkey, -cik) %>%
  filter(recognize) %>%
  arrange(desc(days_to_period_end))

final %>%
  select(-permno, -gvkey, -cik) %>%
  arrange(days_to_period_end)

final %>%
  count(recognize)

michels_2017 <-
  final %>%
  select(-days_to_filing, -days_to_period_end, -period_length) %>%
  collect() %>%
  mutate(prev_fqtr = as.integer(prev_fqtr),
         next_fqtr = as.integer(next_fqtr),
         form_types = as.character(form_types))

usethis::use_data(michels_2017, version = 3, compress="xz", overwrite=TRUE)
