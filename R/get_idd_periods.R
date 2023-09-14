#' Period for Inevitable Disclosure Doctrine (IDD)
#'
#' Periods defined by precedent-setting legal cases adopting or rejecting the
#' Inevitable Disclosure Doctrine (IDD) by state.
#'
#' Three kinds of period by state:
#'   - Pre-adoption
#'   - Post-adoption
#'   - Post-rejection
#'
#' @param min_date First date of sample period
#' @param max_date Last date of sample period
#'
#' @return tibble with four columns: state, period_type, start_date, end_date
#' @export
#' @examples
#' idd_periods <- get_idd_periods(min_date = "1994-01-01",
#'                                max_date = "2010-12-31")
#' idd_periods
get_idd_periods <- function(min_date, max_date) {

    min_date <- as.Date(min_date)
    max_date <- as.Date(max_date)

    df_pre <-
        farr::idd_dates %>%
        dplyr::filter(.data$idd_type == "Adopt", .data$idd_date > min_date) %>%
        dplyr::mutate(start_date = min_date,
               end_date = .data$idd_date) %>%
        dplyr::mutate(period_type = "Pre-adoption") %>%
        dplyr::select("state", "period_type", "start_date", "end_date")

    df_never <-
        dplyr::tibble(state = c("DC", datasets::state.abb)) %>%
        dplyr::anti_join(farr::idd_dates, by = "state") %>%
        dplyr::mutate(period_type = "Pre-adoption",
                      start_date = min_date,
                      end_date = max_date)

    df_post_adopt <-
        farr::idd_dates %>%
        dplyr::group_by(.data$state) %>%
        dplyr::arrange(.data$state, .data$idd_date) %>%
        dplyr::mutate(start_date = pmax(.data$idd_date, min_date),
                      end_date = dplyr::coalesce(dplyr::lead(.data$idd_date), max_date)) %>%
        dplyr::filter(.data$idd_type == "Adopt") %>%
        dplyr::mutate(period_type = "Post-adoption") %>%
        dplyr::select("state", "period_type", "start_date",
                      "end_date")

    df_post_reject <-
        farr::idd_dates %>%
        dplyr::mutate(start_date = pmax(min_date, .data$idd_date),
                      end_date = max_date) %>%
        dplyr::filter(.data$idd_type == "Reject") %>%
        dplyr::mutate(period_type = "Post-rejection") %>%
        dplyr::select("state", "period_type", "start_date",
                      "end_date")

    idd_periods <-
        dplyr::bind_rows(df_never, df_pre, df_post_adopt, df_post_reject) %>%
        dplyr::arrange(.data$state, .data$start_date)

    idd_periods
}
