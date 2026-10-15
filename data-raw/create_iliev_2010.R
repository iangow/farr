library(tidyverse)
library(lubridate)

iliev_source <-
    read_csv("data-raw/public-float-data-complete.csv",
             col_types = "dddic-ddddci--",
             col_names = c("cik", "fmonth", "fday", "fyear", "af",
                           "pfmonth", "pfday", "pfyear",
                           "publicfloat", "mr", "gvkey"),
             skip = 1)

# Preserve the original CSV; see iliev_2010_date_corrections.md for provenance.
date_corrections <- read_csv("data-raw/iliev_2010_date_corrections.csv",
                             col_types = "diddddDc")
correction_keys <- c("cik", "fyear")
original_values <- c(correction_keys, "pfmonth", "pfday", "pfyear",
                     "publicfloat")

# Fail before writing package data if a correction is ambiguous or its source
# values have changed. Public float here is in dollars, as in the filings.
stopifnot(!anyDuplicated(date_corrections[correction_keys]),
          !anyNA(date_corrections))
matched_corrections <- inner_join(iliev_source, date_corrections,
                                  by = original_values,
                                  relationship = "one-to-one")
stopifnot(nrow(matched_corrections) == nrow(date_corrections),
          nrow(semi_join(iliev_source, date_corrections,
                         by = correction_keys)) == nrow(date_corrections))

iliev_2010 <-
    iliev_source %>%
    left_join(select(date_corrections, all_of(correction_keys), corrected_pfdate),
              by = correction_keys, relationship = "many-to-one") %>%
    mutate(pfmonth = coalesce(month(corrected_pfdate), pfmonth),
           pfday = coalesce(day(corrected_pfdate), pfday),
           pfyear = coalesce(year(corrected_pfdate), pfyear)) %>%
    mutate(fdate = mdy(paste(fmonth, fday, fyear, sep = '-')),
           pfdate = mdy(paste(pfmonth, pfday, pfyear, sep = '-')),
           publicfloat = publicfloat/1e6,
           gvkey = str_pad(gvkey, 6, pad = "0"),
           mr = coalesce(mr == 1, FALSE),
           af = coalesce(af == 1, FALSE)) %>%
    filter(!is.na(publicfloat), !is.na(pfyear)) %>%
    select(gvkey, fyear, fdate, pfdate, pfyear, publicfloat, mr, af, cik)

stopifnot(all(iliev_2010$pfyear == trunc(iliev_2010$pfyear)),
          all(year(iliev_2010$pfdate) == iliev_2010$pfyear, na.rm = TRUE))

usethis::use_data(iliev_2010, version = 3, compress="xz", overwrite=TRUE)
