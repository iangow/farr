library(haven)

url <- paste0("https://research.chicagobooth.edu/-/media/research/arc/",
              "docs/journal/online-supplements/llz-datasheet-and-code.zip")

t <- tempfile()
download.file(url, t)

llz_2018 <- haven::read_dta(unz(t, filename = "Firm ID.dta"))

usethis::use_data(llz_2018, version = 3, compress="xz", overwrite=TRUE)
