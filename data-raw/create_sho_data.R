library(haven)
library(dplyr, warn.conflicts = FALSE)
library(stringr)

pilot <- read_sas("data-raw/pilot.sas7bdat")
pmda <- read_sas("data-raw/pmda.sas7bdat")

sho_pilot <-
    pilot %>%
    mutate(gvkey = str_pad(gvkey1, width = 6, side = "left", pad = "0"),
           pilot = as.logical(SHO),
           permno = as.integer(PERMNO)) %>%
    rename(ticker = rsticker) %>%
    select(ticker, gvkey, permno, pilot)

sho_firm_years <-
    pmda %>%
    mutate(gvkey = str_pad(gvkey1, width = 6, side = "left", pad = "0")) %>%
    select(gvkey, datadate)

usethis::use_data(sho_pilot, version = 3, compress="xz", overwrite=TRUE)
usethis::use_data(sho_firm_years, version = 3, compress="xz", overwrite=TRUE)
