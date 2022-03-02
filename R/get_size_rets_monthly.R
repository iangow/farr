read_data <- function(start, end) {

    Sys.setenv(VROOM_CONNECTION_SIZE = 500000)

    fix_names <- function(names) {
        gsub("^$", "date", names)
    }

    readr::read_csv("Portfolios_Formed_on_ME_CSV.zip", skip = start, n_max = end - start,
                    na = c("-99.99"),
                    name_repair = fix_names,
                    show_col_types = FALSE) %>%
        dplyr::mutate(month = lubridate::ymd(paste0(.data$date, "01"))) %>%
        dplyr::select(-.data$date) %>%
        tidyr::pivot_longer(names_to = "quantile",
                            values_to = "ret",
                            cols = -.data$month) %>%
        dplyr::mutate(ret = .data$ret / 100,
                      decile = dplyr::case_when(.data$quantile == "Hi 10" ~ "10",
                                                .data$quantile == "Lo 10" ~ "1",
                                                grepl("^Dec ", .data$quantile) ~
                                                    sub("^Dec ", "", .data$quantile),
                                                TRUE ~ NA_character_),
                      decile = as.integer(.data$decile)) %>%
        dplyr::filter(!is.na(.data$decile)) %>%
        dplyr::select(-"quantile")
}

#' Create a table of monthly returns for size portfolios
#'
#' @return tbl_df
#' @export
#' @importFrom rlang .data
get_size_rets_monthly <- function() {

    # Download the data
    url <- paste0("http://mba.tuck.dartmouth.edu",
                  "/pages/faculty/ken.french/ftp/",
                  "Portfolios_Formed_on_ME_CSV.zip")
    utils::download.file(url, "Portfolios_Formed_on_ME_CSV.zip")

    # Determine breakpoints (lines) for different tables
    temp <- readr::read_lines("Portfolios_Formed_on_ME_CSV.zip")
    vw_start <- grep("^\\s+Value Weight Returns -- Monthly", temp)
    vw_end <- grep("^\\s+Equal Weight Returns -- Monthly", temp) - 4

    ew_start <- grep("^\\s+Equal Weight Returns -- Monthly", temp)
    ew_end <- grep("^\\s+Value Weight Returns -- Annual", temp) - 4

    vw_rets <-
        read_data(vw_start, vw_end) %>%
        dplyr::rename(vw_ret = .data$ret)

    ew_rets <-
        read_data(ew_start, ew_end) %>%
        dplyr::rename(ew_ret = .data$ret)

    size_rets <-
        ew_rets %>%
        dplyr::inner_join(vw_rets, by = c("month", "decile")) %>%
        dplyr::select(.data$month, .data$decile, dplyr::everything())

    unlink("Portfolios_Formed_on_ME_CSV.zip")

    size_rets
}
