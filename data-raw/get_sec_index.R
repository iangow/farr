library(tidyverse)
library(DBI)
library(farr)
library(arrow)         # write_parquet(), read_parquet()
library(httr2)         # request(), req_*(), resp_body_html()
library(rvest)         # html_elements(), html_table()

get_last_update <- function(year, quarter) {

    url <- str_c("https://www.sec.gov/Archives/edgar/full-index/",
                 year, "/QTR", quarter, "/")

    resp <-
        request(url) |>
        req_user_agent(getOption("HTTPUserAgent")) |>
        req_perform() |>
        resp_body_html() |>
        html_elements("body")

    resp[[1]] |>
        html_table() |>
        filter(Name == "company.gz") |>
        select(`Last Modified`) |>
        mdy_hms(tz = "America/New_York")
}

now <- now(tz = 'America/New_York') - days(1)
current_year <- as.integer(year(now))
current_qtr <- quarter(now)
year <- 1993L:current_year
quarter <- 1:4L

index_files_to_get <-
    crossing(year, quarter) |>
    filter(year < current_year |
               (year == current_year & quarter <= current_qtr))

options(HTTPUserAgent = "iandgow@gmail.com")

last_modified_scraped <-
    index_files_to_get |>
    rowwise() |>
    mutate(last_modified = get_last_update(year, quarter)) |>
    ungroup() |>
    system_time()

data_dir <- Sys.getenv("DATA_DIR")
if (!dir.exists(data_dir)) dir.create(data_dir)

edgar_dir <- file.path(data_dir, "edgar")
if (!dir.exists(edgar_dir)) dir.create(edgar_dir)

pq_path <- file.path(edgar_dir, "last_modified.parquet")

if (file.exists(pq_path)) {
    last_modified <- read_parquet(pq_path)
} else {
    last_modified <- tibble(year = NA, quarter = NA,
                            last_modified = NA)
}

to_update <-
    last_modified_scraped |>
    left_join(last_modified,
              by = c("year", "quarter"),
              suffix = c("_new", "_old")) |>
    filter(is.na(last_modified_old) |
               last_modified_new > last_modified_old)


get_sec_index <- function(year, quarter, overwrite = FALSE) {

    pq_path <- str_c(edgar_dir, "/sec_index_",
                     year, "q", quarter, ".parquet")
    if (file.exists(pq_path) & !overwrite) return(TRUE)

    # Download the zipped index file from the SEC website
    url <- str_c("https://www.sec.gov/Archives/edgar/full-index/",
                 year,"/QTR", quarter, "/company.gz")

    t <- tempfile(fileext = ".gz")
    result <- try(download.file(url, t))

    # If we didn't encounter an error downloading the file, parse it
    # and save as a parquet file
    if (!inherits(result, "try-error")) {
        temp <-
            read_fwf(t, fwf_cols(company_name = c(1, 62),
                                 form_type = c(63, 77),
                                 cik = c(78, 89),
                                 date_filed = c(90, 101),
                                 file_name = c(102, NA)),
                     col_types = "ccicc", skip = 10,
                     locale = locale(encoding = "macintosh")) |>
            mutate(date_filed = as.Date(date_filed))

        write_parquet(temp, sink = pq_path)
        return(TRUE)
    } else {
        return(FALSE)
    }
}

index_files_downloaded <-
    to_update |>
    mutate(available = map2(year, quarter, get_sec_index, overwrite = TRUE))
