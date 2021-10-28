library(readr)

bloomfield_url <- paste0("https://research.chicagobooth.edu/-/media/",
                         "research/arc/docs/journal/online-supplements/",
                         "bloomfield-datasheet-code-and-identifiers.zip")

t <- tempfile()
download.file(bloomfield_url, t)

bloomfield_files <- unzip(t, list  = TRUE)$Name
bloomfield_file <- bloomfield_files[3]
bloomfield_data <- unzip(t, bloomfield_file)

bloomfield_2021 <- read_csv(bloomfield_data, col_types = "ii")
unlink(bloomfield_data)
usethis::use_data(bloomfield_2021, version = 3, compress="xz", overwrite=TRUE)
