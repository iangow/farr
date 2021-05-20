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

#' AAER dates from SEC
#'
#' A data set containing dates and descriptions for AAERs
#'
#' @format A tibble with 40,518 rows and 4 variables:
#' \describe{
#'   \item{aaer_num}{AAER number}
#'   \item{aaer_date}{Date}
#'   \item{aaer_desc}{Description}
#'   \item{year}{Year of AAER}
#'   ...
#' }
"aaer_dates"

#' Data on accruals and auditor choice
#'
#' A data set containing data about accruals for 2,000 firms.
#'
#' @format A tibble with 16,237 rows and 14 variables:
#' \describe{
#'   \item{gvkey}{GVKEY (firm identifier)}
#'   \item{datadate}{Fiscal year-end}
#'   \item{fyear}{Fiscal year}
#'   \item{big_n}{Indicator for Big Four auditor}
#'   \item{ta}{Total accruals (scaled by assets)}
#'   \item{roa}{Return on assets}
#'   \item{cfo}{Cash flow from operating activities (scaled by assets)}
#'   \item{size}{Size}
#'   \item{lev}{Leverage}
#'   \item{mtb}{Market-to-book ratio}
#'   \item{inv_at}{1/Total assets}
#'   \item{d_sale}{Change in revenue}
#'   \item{d_ar}{Change in accounts receivable}
#'   \item{ppe}{Property, plant & equipment (scaled by assets)}
#'   ...
#' }
"comp"

#' Test scores
#'
#' A simulated data set of test scores.
#'
#' @format A tibble with 4000 rows and 5 variables:
#' \describe{
#'   \item{id}{Student identifier}
#'   \item{grade}{School grade at time of test}
#'   \item{post}{Indicator for being in grade 10 or 11}
#'   \item{treat}{Indicator for student attending camp after grade 9}
#'   \item{score}{Test score}
#' }
"test_scores"
