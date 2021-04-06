library(dplyr, warn.conflicts = FALSE)
library(rvest)
library(lubridate)

get_aaers <- function(year) {

    if (year == 2021) {
        res <- "https://www.sec.gov/divisions/enforce/friactions.htm"
    } else if (year == 2020) {
        res <- "https://www.sec.gov/divisions/enforce/friactions/friactions2020.htm"
    } else {
        res <- paste0("https://www.sec.gov/divisions/enforce/friactions/friactions",
                      year, ".shtml")
    }

    tables <-
        res %>%
        read_html() %>%
        html_table()

    add_names <- function(df) {
        names(df) <- c("aaer_num", "aaer_date", "aaer_desc")
        df
    }

    table_index <- if(year < 2016) 5 else 1

    aaers <-
        tables[[table_index]] %>%
        .[-1:-2, ] %>%
        add_names() %>%
        filter(grepl("[0-9]", aaer_num)) %>%
        mutate(aaer_date = mdy(aaer_date),
               year = year)

    aaers
}
aaer_dates <- bind_rows(lapply(1999:2021, get_aaers))

save(by_tag_year, file="data/aaer_dates.RData",
     compress = "xz")
