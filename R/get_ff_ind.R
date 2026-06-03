#' Fetch Fama-French industry grouping.
#'
#' Fetch Fama-French industry grouping from Ken French's website.
#'
#' @param ind Fama-French industry grouping (e.g., 11, 48)
#' @param refresh_cache If `TRUE`, re-download the underlying zip file even if
#'   a cached copy is available.
#'
#' @return tbl_df
#' @export
#' @importFrom rlang .data
#' @examples
#' ## Not run:
#' get_ff_ind(5)
#' ## End(Not run)
get_ff_ind <- function(ind, refresh_cache = FALSE) {
    if (!is.logical(refresh_cache) || length(refresh_cache) != 1 || is.na(refresh_cache)) {
        stop("`refresh_cache` must be `TRUE` or `FALSE`.", call. = FALSE)
    }

    zip_file <- ff_ind_cache_file(ind)
    url <- stringr::str_c("http://mba.tuck.dartmouth.edu/pages/",
                          "faculty/ken.french/ftp/Siccodes", ind, ".zip")

    if (refresh_cache || !file.exists(zip_file)) {
        dir.create(dirname(zip_file), recursive = TRUE, showWarnings = FALSE)
        temp_zip_file <- tempfile(tmpdir = dirname(zip_file), fileext = ".zip")
        on.exit(unlink(temp_zip_file), add = TRUE)
        download_ff_ind_zip(url, temp_zip_file)
        if (!file.copy(temp_zip_file, zip_file, overwrite = TRUE)) {
            stop("Could not write Fama-French industry zip file to cache.",
                 call. = FALSE)
        }
    }

    read_ff_ind_zip(zip_file)
}

ff_ind_cache_file <- function(ind) {
    file.path(ff_ind_cache_dir(), stringr::str_c("Siccodes", ind, ".zip"))
}

ff_ind_cache_dir <- function() {
    getOption("farr.cache_dir", default = farr_user_cache_dir())
}

farr_user_cache_dir <- function() {
    if (exists("R_user_dir", envir = asNamespace("tools"), inherits = FALSE)) {
        tools::R_user_dir("farr", "cache")
    } else {
        file.path(path.expand("~"), ".cache", "R", "farr")
    }
}

download_ff_ind_zip <- function(url, destfile) {
    utils::download.file(url, destfile, quiet = TRUE)
}

read_ff_ind_zip <- function(zip_file) {
    zip_file %>%
        readr::read_fwf(col_positions = readr::fwf_widths(c(3, 7, NA),
                                                          c("ff_ind",
                                                            "ff_ind_short_desc",
                                                            "temp")),
                        col_types = "icc") %>%
        dplyr::mutate(ff_ind_desc = dplyr::if_else(!is.na(.data$ff_ind), .data$temp, NA_character_),
                      sic_range = dplyr::if_else(is.na(.data$ff_ind), .data$temp, NA_character_)) %>%
        dplyr::select(-"temp") %>%
        tidyr::fill("ff_ind", "ff_ind_short_desc", "ff_ind_desc") %>%
        dplyr::filter(!is.na(.data$sic_range)) %>%
        tidyr::extract(.data$sic_range,
                       into = c("sic_min", "sic_max", "sic_desc"),
                       regex = "([0-9]+)-([0-9]+)\\s*(.*)",
                       convert = TRUE)
}
