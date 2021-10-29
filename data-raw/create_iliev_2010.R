library(tidyverse)
library(haven)
library(lubridate)

iliev_2010 <-
    read_csv("data-raw/public-float-data-complete.csv",
             col_types = "dddic-ddddci--",
             col_names = c("cik", "fmonth", "fday", "fyear", "af",
                           "pfmonth", "pfday", "pfyear",
                           "publicfloat", "mr", "gvkey"),
             skip = 1) %>%
    mutate(fdate = mdy(paste(fmonth, fday, fyear, sep = '-')),
           pfdate = mdy(paste(pfmonth, pfday, pfyear, sep = '-')),
           publicfloat = publicfloat/1e6,
           gvkey = str_pad(gvkey, 6, pad = "0"),
           mr = coalesce(mr == 1, FALSE),
           af = coalesce(af == 1, FALSE)) %>%
    filter(!is.na(publicfloat), !is.na(pfyear)) %>%
    select(gvkey, fyear, fdate, pfdate, pfyear, publicfloat, mr, af, cik)

usethis::use_data(iliev_2010, version = 3, compress="xz", overwrite=TRUE)
