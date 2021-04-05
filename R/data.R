#' Dates for Apple Events
#'
#' A data set containing the dates of Apple media events
#' since 2005.
#'
#' @format A tibble with 47 rows and 3 variables:
#' \describe{
#'   \item{event}{Description of event}
#'   \item{event_date}{First date of event}
#'   \item{end_event_date}{Last date of event}
#'   ...
#' }
#' @source \url{https://en.wikipedia.org/wiki/List_of_Apple_Inc._media_events}
"apple_events"

#' Tags on StackOverflow
#'
#' A data set containing data on tagged questions on StackOverflow
#'
#' @format A tibble with 40,518 rows and 4 variables:
#' \describe{
#'   \item{year}{Year}
#'   \item{tag}{Tag}
#'   \item{number}{Number of questions with tag during year}
#'   \item{year_total}{Total number of questions with tag during year}
#'   ...
#' }
"by_tag_year"
