library(haven)
library(dplyr, warn.conflicts = FALSE)
library(stringr)
library(rvest)

# sho_pilot
pilot <- read_sas("data-raw/pilot.sas7bdat")

fhk_pilot <-
    pilot %>%
    mutate(gvkey = str_pad(gvkey1, width = 6, side = "left", pad = "0"),
           pilot = as.logical(SHO),
           permno = as.integer(PERMNO)) %>%
    rename(ticker = rsticker) %>%
    select(ticker, gvkey, permno, pilot)

usethis::use_data(fhk_pilot, version = 3, compress="xz", overwrite=TRUE)

# sho_firm_years
pmda <- read_sas("data-raw/pmda.sas7bdat")

fhk_firm_years <-
    pmda %>%
    mutate(gvkey = str_pad(gvkey1, width = 6, side = "left", pad = "0")) %>%
    select(gvkey, datadate)

usethis::use_data(fhk_firm_years, version = 3, compress="xz", overwrite=TRUE)

# sho_tickers
res <- "https://www.sec.gov/rules/other/34-50104.htm"
tickers_vector <-
    res %>%
    read_html() %>%
    html_elements("table") %>%
    .[4] %>%
    html_text() %>%
    str_split("\n") %>%
    .[[1]] %>%
    str_replace("TickerSymbolCompany Name", "")

tickers <- tickers_vector[c(TRUE, FALSE)]

sho_tickers <-
    tibble(ticker = tickers[tickers != ""],
                  co_name = tickers_vector[ c(FALSE, TRUE)])

usethis::use_data(sho_tickers, version = 3, compress="xz", overwrite=TRUE)

# sho_r3000
sho_r3000 <-
    pilot %>%
    rename(russell_ticker = rsticker,
           russell_name = RSNAME) %>%
    select(russell_ticker, russell_name) %>%
    distinct() %>%
    bind_rows(tibble(russell_ticker = "AMI",
                     russell_name = "ALARIS MEDICAL SYSTEMS"))


usethis::use_data(sho_r3000, version = 3, compress="xz", overwrite=TRUE)
