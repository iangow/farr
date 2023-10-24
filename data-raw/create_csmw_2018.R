library(haven)
library(dplyr, warn.conflicts = FALSE)

csmw_url <- paste0("https://research.chicagobooth.edu/-/media/",
                         "research/arc/docs/journal/online-supplements/",
                         "csmw-datasheet-and-code.zip")

t <- tempfile()
download.file(csmw_url, t)

vars <- c("recid", "firmpenalty1", "otherpenalty1", "emp_penalty1",
          "selfdealflag", "blckownpct", "initabret", "wbflag", "touse_sox",
              "lnvioperiod", "bribeflag", "mobflag", "deter", "lnempclevel_n",
              "lnuscodecnt", "viofraudflag", "misledflag", "audit8flag",
              "exectermflag", "coopflag", "impedeflag", "pct_ind_dir",
              "recidivist", "lnmktcap", "mkt2bk", "lev", "lndistance",
              "ff12")


csmw_files <- unzip(t, list  = TRUE)$Name
csmw_file <- csmw_files[4]
csmw_data <- unzip(t, csmw_file)

to_logical <- function(x) as.logical(as.integer(x))

csmw_2018 <-
    read_stata(csmw_data) |>
    select(any_of(vars)) |>
    mutate(across(c(ends_with("flag"),
                    "touse_sox", "deter", "recidivist"), to_logical),
           ff12 = as.integer(ff12)) |>
    rename_with(\(x) gsub("1$", "", x),
                ends_with("1")) |>
    rename_with(\(x) gsub("_", "", x))

unlink(csmw_data)
usethis::use_data(csmw_2018, version = 3, compress = "xz", overwrite = TRUE)
