library(tidyverse)
library(haven)
library(lubridate)

iliev_2010 <-
    read_csv("data-raw/public-float-data-complete.csv",
             col_types = "-ddi--dddi-i--",
             col_names = c("fmonth", "fday", "fyear",
                           "pfmonth", "pfday", "pfyear",
                           "publicfloat", "gvkey"),
             skip = 1) %>%
    mutate(fdate = mdy(paste(fmonth, fday, fyear, sep = '-')),
           pfdate = mdy(paste(pfmonth, pfday, pfyear, sep = '-')),
           publicfloat = publicfloat/1e6,
           gvkey = str_pad(gvkey, 6, pad = "0")) %>%
    filter(!is.na(publicfloat), !is.na(pfyear)) %>%
    select(gvkey, fyear, fdate, pfdate, pfyear, publicfloat)

usethis::use_data(iliev_2010, version = 3, compress="xz", overwrite=TRUE)
