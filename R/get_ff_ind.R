#' Fetch Fama-French industry grouping.
#'
#' Fetch Fama-French industry grouping from Ken French's website.
#'
#' @param ind Fama-French industry grouping (e.g., 11, 48)
#'
#' @return tbl_df
#' @export
#' @importFrom rlang .data
get_ff_ind <- function(ind) {
    t <- tempfile(fileext = ".zip")
    url <- stringr::str_c("http://mba.tuck.dartmouth.edu/pages/",
                          "faculty/ken.french/ftp/Siccodes", ind, ".zip")
    utils::download.file(url, t)

    t %>%
        readr::read_fwf(col_positions = readr::fwf_widths(c(3, 7, NA),
                                                          c("ff_ind",
                                                            "ff_ind_short_desc",
                                                            "temp")),
                        col_types = "icc") %>%
        dplyr::mutate(ff_ind_desc = dplyr::if_else(!is.na(.data$ff_ind), .data$temp, NA_character_),
                      sic_range = dplyr::if_else(is.na(.data$ff_ind), .data$temp, NA_character_)) %>%
        dplyr::select(-.data$temp) %>%
        tidyr::fill(.data$ff_ind, .data$ff_ind_short_desc, .data$ff_ind_desc) %>%
        dplyr::filter(!is.na(.data$sic_range)) %>%
        tidyr::extract(.data$sic_range,
                       into = c("sic_min", "sic_max", "sic_desc"),
                       regex = "([0-9]+)-([0-9]+)\\s*(.*)",
                       convert = TRUE)
}
