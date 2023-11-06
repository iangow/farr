library(haven)
library(dplyr, warn.conflicts = FALSE)

cmsw_url <- paste0("https://www.chicagobooth.edu/-/",
                   "media/research/arc/docs/journal/online-supplements/",
                   "csmw-datasheet-and-code.zip")

t <- tempfile()
download.file(cmsw_url, t)

vars <- c("recid", "firmpenalty1", "otherpenalty1", "emp_penalty1",
          "empprison_mos",
          "selfdealflag", "blckownpct", "initabret", "wbflag", "touse_sox",
              "lnvioperiod", "bribeflag", "mobflag", "deter", "lnempclevel_n",
              "lnuscodecnt", "viofraudflag", "misledflag", "audit8flag",
              "exectermflag", "coopflag", "impedeflag", "pct_ind_dir",
              "recidivist", "lnmktcap", "mkt2bk", "lev", "lndistance",
              "ff12", "nontipsterflag", "tipsterflag", "wbtype")

cmsw_files <- unzip(t, list  = TRUE)$Name
cmsw_file <- cmsw_files[4]
cmsw_data <- unzip(t, cmsw_file)

to_logical <- function(x) as.logical(as.integer(x))

cmsw_2018 <-
    read_stata(cmsw_data) |>
    select(any_of(vars)) |>
    mutate(across(c(ends_with("flag"),
                    "touse_sox", "deter", "recidivist"), to_logical),
           ff12 = as.integer(ff12)) |>
    rename_with(\(x) gsub("1$", "", x),
                ends_with("1")) |>
    rename_with(\(x) gsub("_", "", x)) |>
    mutate(wbsource = labelled::to_factor(wbtype)) |>
    mutate(wbtype = case_when(tipsterflag == 1 ~ "tipster",
                              nontipsterflag == 1 ~ "nontipster",
                              .default = "none")) |>
    select(-matches("tipster")) |>
    mutate(wbtype = factor(wbtype,
                           levels = c("none", "tipster", "nontipster")))
unlink(cmsw_data)
usethis::use_data(cmsw_2018, version = 3, compress = "xz", overwrite = TRUE)

