#' Create a table of with cut-offs for size portfolios
#'
#' @param ind Fama-French industry grouping (e.g., 11, 48)
#'
#' @param keep_max Set to `TRUE` to keep upper-bound of highest decile.
#'   Default is `FALSE`, which will replace upper bound with `Inf`.
#' @export
#' @importFrom rlang .data
#' @examples
#' library(dplyr, warn.conflicts = FALSE)
#' get_me_breakpoints() %>% filter(month == '2022-04-01')
get_me_breakpoints <- function(keep_max = FALSE) {
    t <- tempfile(fileext = ".zip")
    url <- paste0("http://mba.tuck.dartmouth.edu",
                  "/pages/faculty/ken.french/ftp/",
                  "ME_Breakpoints_CSV.zip")
    utils::download.file(url, t, quiet = TRUE)

    temp <- readr::read_lines(t)

    me_breakpoints_raw <-
        readr::read_csv(t, skip = 2,
                 col_names = c("month", "n",
                               paste0("p", seq(from = 5, to = 100, by = 5))),
                 col_types = "c",
                 n_max = grep("^Copyright", temp) - 4) %>%
        dplyr::mutate(month = lubridate::ymd(paste0(.data$month, "01"))) %>%
        dplyr::select(-dplyr::ends_with("5"), -"n") %>%
        tidyr::pivot_longer(cols = - "month",
                     names_to = "decile",
                     values_to = "cutoff") %>%
        dplyr::mutate(decile = gsub("^p(.*)0$", "\\1", .data$decile)) %>%
        dplyr::mutate(decile = as.integer(.data$decile))

    me_breakpoints <-
        me_breakpoints_raw %>%
        dplyr::group_by(.data$month) %>%
        dplyr::arrange(.data$decile) %>%
        dplyr::mutate(me_min = dplyr::coalesce(dplyr::lag(.data$cutoff), 0),
                      me_max = .data$cutoff) %>%
        dplyr::select(-"cutoff") %>%
        dplyr::arrange(.data$month, .data$decile) %>%
        dplyr::ungroup()

    if (!keep_max) {
        me_breakpoints <-
            me_breakpoints %>%
            dplyr::mutate(me_max = dplyr::if_else(.data$decile == 10,
                                                  Inf, .data$me_max))
    }
    me_breakpoints
}
