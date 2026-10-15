read_data <- function(path, start, end) {

    previous_connection_size <- Sys.getenv("VROOM_CONNECTION_SIZE", unset = NA_character_)
    on.exit({
        if (is.na(previous_connection_size)) {
            Sys.unsetenv("VROOM_CONNECTION_SIZE")
        } else {
            Sys.setenv(VROOM_CONNECTION_SIZE = previous_connection_size)
        }
    }, add = TRUE)
    Sys.setenv(VROOM_CONNECTION_SIZE = 500000)

    fix_names <- function(names) {
        gsub("^$", "date", names)
    }

    readr::read_csv(path, skip = start, n_max = end - start,
                    na = c("-99.99"),
                    name_repair = fix_names,
                    show_col_types = FALSE) %>%
        dplyr::mutate(month = lubridate::ymd(paste0(.data$date, "01"))) %>%
        dplyr::select(-"date") %>%
        tidyr::pivot_longer(names_to = "quantile",
                            values_to = "ret",
                            cols = -"month") %>%
        dplyr::mutate(ret = .data$ret / 100,
                      decile = dplyr::case_when(.data$quantile == "Hi 10" ~ "10",
                                                .data$quantile == "Lo 10" ~ "1",
                                                grepl("-Dec", .data$quantile) ~
                                                    sub("-Dec", "", .data$quantile),
                                                TRUE ~ NA_character_),
                      decile = as.integer(.data$decile)) %>%
        dplyr::filter(!is.na(.data$decile)) %>%
        dplyr::select(-"quantile")
}

#' Create a table of monthly returns for size portfolios
#'
#' @return A tibble with columns `month` (a Date), `decile` (integers 1--10),
#'   `ew_ret` (equal-weighted returns), and `vw_ret` (value-weighted returns).
#'   Returns are expressed as decimal fractions.
#' @export
#' @importFrom rlang .data
#' @examples
#' \donttest{
#' # Downloads portfolio returns from Ken French's website.
#' head(get_size_rets_monthly())
#' }
get_size_rets_monthly <- function() {

    # Download the data
    url <- paste0("https://mba.tuck.dartmouth.edu",
                  "/pages/faculty/ken.french/ftp/",
                  "Portfolios_Formed_on_ME_CSV.zip")
    zip_file <- tempfile(fileext = ".zip")
    on.exit(unlink(zip_file), add = TRUE)
    utils::download.file(url, zip_file, quiet = TRUE, mode = "wb")

    # Determine breakpoints (lines) for different tables
    temp <- readr::read_lines(zip_file)
    vw_start <- grep("^\\s+.*Value Weight.*Monthly", temp)
    vw_end <-  grep("^\\s+.*Equal Weight.*Monthly", temp) - 4

    ew_start <- grep("^\\s+.*Equal Weight.*Monthly", temp)
    ew_end <- grep("^\\s+Value Weight.*Annual", temp) - 4

    vw_rets <-
        read_data(zip_file, vw_start, vw_end) %>%
        dplyr::rename(vw_ret = "ret")

    ew_rets <-
        read_data(zip_file, ew_start, ew_end) %>%
        dplyr::rename(ew_ret = "ret")

    size_rets <-
        ew_rets %>%
        dplyr::inner_join(vw_rets, by = c("month", "decile")) %>%
        dplyr::select("month", "decile", dplyr::everything())

    size_rets
}
