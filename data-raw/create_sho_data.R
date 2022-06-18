library(haven)
library(dplyr, warn.conflicts = FALSE)
library(stringr)
library(rvest)
library(DBI)

pg <- dbConnect(RPostgres::Postgres(), bigint = "integer")
rs <- dbExecute(pg, "SET search_path TO crsp")

mse <- tbl(pg, "mse")
msf <- tbl(pg, "msf")
stocknames <- tbl(pg, "stocknames")
dseexchdates <- tbl(pg, "dseexchdates")
ccmxpf_lnkhist <- tbl(pg, "ccmxpf_lnkhist")
dsf <- tbl(pg, "dsf")

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


regex <- "^(.*)\\.([AB])$"

clean_ticker <- function(x) {
    case_when(
        nchar(x) == 5 & substr(x, 5, 5) == "E" ~ substr(x, 1, 4),
        str_detect(x, regex) ~ str_replace(x, regex, "\\1"),
        TRUE ~ x
    )
}

get_shrcls <- function(x) {
    str_match(x, regex)[, 3]
}

sho_r3000_tickers <-
    sho_r3000 %>%
    select(russell_ticker, russell_name) %>%
    mutate(ticker = clean_ticker(russell_ticker),
           shrcls = get_shrcls(russell_ticker))

crsp_sample <-
    stocknames %>%
    mutate(test_date = as.Date("2004-06-25")) %>%
    filter(test_date >= namedt, test_date <= nameenddt) %>%
    select(permno, permco, ticker, shrcls) %>%
    distinct() %>%
    collect()

sho_r3000_merged <-
    sho_r3000_tickers %>%
    inner_join(crsp_sample, by = "ticker", suffix = c("", "_crsp")) %>%
    filter(shrcls == shrcls_crsp | is.na(shrcls)) %>%
    select(russell_ticker, permco, permno)

trading_vol <-
    msf %>%
    filter(date == "2004-06-30") %>%
    mutate(dollar_vol = coalesce(abs(prc) * vol, 0)) %>%
    select(permno, dollar_vol) %>%
    collect()

sho_r3000_merged <-
    sho_r3000_tickers %>%
    inner_join(crsp_sample, by = "ticker", suffix = c("", "_crsp")) %>%
    filter(is.na(shrcls) | shrcls == shrcls_crsp) %>%
    inner_join(trading_vol, by = "permno") %>%
    group_by(russell_ticker) %>%
    filter(dollar_vol == max(dollar_vol, na.rm = TRUE)) %>%
    ungroup() %>%
    select(russell_ticker, permno)

nmsind_data <-
    mse %>%
    filter(date <= "2004-06-28", event == "NASDIN") %>%
    group_by(permno) %>%
    filter(date == max(date, na.rm = TRUE)) %>%
    ungroup() %>%
    select(permno, date, nmsind) %>%
    collect()

exchcd_data <-
    stocknames %>%
    filter(exchcd > 0) %>%
    mutate(test_date = as.Date("2004-06-28")) %>%
    filter(test_date >= namedt, test_date <= nameenddt) %>%
    select(permno, exchcd) %>%
    distinct() %>%
    collect()

ipo_dates <-
    dseexchdates %>%
    select(permno, begexchdate) %>%
    distinct() %>%
    collect()

recent_delistings <-
    mse %>%
    filter(event == "DELIST",
           date >= "2004-06-25", date <= "2004-06-28") %>%
    rename(delist_date = date) %>%
    select(permno, delist_date) %>%
    collect()

sho_r3000_permno <-
    sho_r3000_merged %>%
    left_join(nmsind_data, by = "permno") %>%
    left_join(exchcd_data, by = "permno") %>%
    left_join(ipo_dates, by = "permno") %>%
    left_join(recent_delistings, by = "permno") %>%
    mutate(
        nasdaq_small = coalesce(nmsind == 3 & exchcd == 3, FALSE),
        recent_listing = begexchdate > "2004-04-30",
        delisted = !is.na(delist_date),
        keep = !nasdaq_small & !recent_listing & !delisted
    )

sho_r3000_sample <-
    sho_r3000_permno %>%
    filter(keep) %>%
    rename(ticker = russell_ticker) %>%
    left_join(sho_tickers %>%
                  select(ticker) %>%
                  mutate(pilot = TRUE),
              by = "ticker") %>%
    mutate(pilot = coalesce(pilot, FALSE)) %>%
    select(ticker, permno, pilot)

ccm_link <-
    ccmxpf_lnkhist %>%
    filter(linktype %in% c("LC", "LU", "LS"),
           linkprim %in% c("C", "P")) %>%
    rename(permno = lpermno) %>%
    select(gvkey, permno, linkdt, linkenddt)

gvkeys <-
    ccm_link %>%
    mutate(test_date = as.Date("2004-06-28")) %>%
    filter(test_date >= linkdt,
           test_date <= linkenddt | is.na(linkenddt)) %>%
    select(gvkey, permno) %>%
    collect()

sho_r3000_gvkeys <-
    sho_r3000_sample %>%
    inner_join(gvkeys, by = "permno") %>%
    select(ticker, permno, gvkey, pilot)

usethis::use_data(sho_r3000, version = 3, compress="xz", overwrite=TRUE)
usethis::use_data(sho_r3000_sample, version = 3, compress="xz", overwrite=TRUE)
usethis::use_data(sho_r3000_gvkeys, version = 3, compress="xz", overwrite=TRUE)
