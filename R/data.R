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

#' Dates for Inevitable Disclosure Doctrine (IDD)
#'
#' Dates of precedent-setting legal cases adopting or reject the
#' Inevitable Disclosure Doctrine (IDD) by state.
#'
#' @format A tibble with 24 rows and 3 variables:
#' \describe{
#'   \item{state}{Two-letter state abbreviation}
#'   \item{idd_date}{Date of precedent-setting legal case}
#'   \item{idd_type}{Either "Adopt" or "Reject"}
#' }
#' @source \url{https://doi.org/10.1016/j.jfineco.2018.02.008}
"idd_dates"

#' Data on firm headquarters based on SEC EDGAR filings.
#'
#' Data on firm headquarters based on SEC EDGAR filings.
#' Dates related to SEC filing dates. Rather than provide dates for
#' all filings, data are aggregated into groups of filings by state and
#' CIK and dates are collapsed into windows over which
#' all filings for a given CIK were associated with a given state.
#' For example, CIK 0000037755 has filings with a CA headquarters from
#' 1994-06-02 until 1996-03-25, then filings with an OH headquarters from
#' 1996-05-30 until 1999-04-05, then filings with a CA headquarters from
#' 1999-06-11 onwards.
#' To ensure continuous coverage over the sample period, it is assumed that
#' any change in state occurs the day after the last observed filing for
#' the previous state.
#'
#' @format A tibble with 24 rows and 3 variables:
#' \describe{
#'   \item{cik}{SEC's Central Index Key (CIK)}
#'   \item{ba_state}{Two-letter abbreviation of state}
#'   \item{min_date}{Date of first filing with CIK-state combination in a contiguous series of filings}
#'   \item{max_date}{Date of last filing with CIK-state combination in a contiguous series of filings}
#' }
#' @source \url{https://sraf.nd.edu/data/augmented-10-x-header-data}
"state_hq"

#' GVKEYs used in Li, Lin and Zhang (2018)
#'
#' @format A tibble with 5,830 rows and 1 variable:
#' \describe{
#'   \item{gvkey}{GVKEY}
#' }
#' @source \url{https://research.chicagobooth.edu/-/media/research/arc/docs/journal/online-supplements/llz-datasheet-and-code.zip}
"llz_2018"

#' Customer names that represent non-disclosures.
#'
#' Data to be combined with data in compsegd.seg_customer to create an
#' indicator for non-disclosure of customer names.
#'
#' @format A tibble with 432 rows and 2 variables:
#' \describe{
#'   \item{cnms}{Matches field in compsegd.seg_customer (WRDS)}
#'   \item{disclosure}{Indicator that name is not disclosed}
#' }
"undisclosed_names"
