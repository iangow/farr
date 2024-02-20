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
#' }
"by_tag_year"

#' AAER dates from SEC
#'
#' A data set containing dates and descriptions for AAERs
#'
#' @format A tibble with 2,920 rows and 4 variables:
#' \describe{
#'   \item{aaer_num}{AAER number}
#'   \item{aaer_date}{Date}
#'   \item{aaer_desc}{Description}
#'   \item{year}{Year of AAER}
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
#' }
"comp"

#' Test scores
#'
#' A simulated data set of test scores.
#'
#' @format A tibble with 4,000 rows and 3 variables:
#' \describe{
#'   \item{id}{Student identifier}
#'   \item{grade}{School grade at time of test}
#'   \item{score}{Test score}
#' }
"test_scores"

#' Camp attendance
#'
#' A simulated data set related to camp attendance.
#'
#' @format A tibble with 1,000 rows and 2 variables:
#' \describe{
#'   \item{id}{Student identifier}
#'   \item{camp}{Indicator for student attendance at camp}
#' }
"camp_attendance"

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
#' @source \doi{10.1016/j.jfineco.2018.02.008}
"idd_dates"

#' Data on firm headquarters based on SEC EDGAR filings
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
#' @format A tibble with 53,133 rows and 4 variables:
#' \describe{
#'   \item{cik}{SEC's Central Index Key (CIK)}
#'   \item{ba_state}{Two-letter abbreviation of state}
#'   \item{min_date}{Date of first filing with CIK-state combination in a contiguous series of filings}
#'   \item{max_date}{Date of last filing with CIK-state combination in a contiguous series of filings}
#' }
#' @source \url{https://sraf.nd.edu/data/augmented-10-x-header-data/}
"state_hq"

#' GVKEYs used in Li, Lin and Zhang (2018)
#'
#' @format A tibble with 5,830 rows and 1 variable:
#' \describe{
#'   \item{gvkey}{GVKEY}
#' }
#' @source \doi{10.1111/1475-679X.12187}
"llz_2018"

#' Customer names that represent non-disclosures.
#'
#' Data to be combined with data in compsegd.seg_customer to create an
#' indicator for non-disclosure of customer names.
#'
#' @format A tibble with 460 rows and 2 variables:
#' \describe{
#'   \item{cnms}{Matches field in compsegd.seg_customer (WRDS)}
#'   \item{disclosure}{Indicator that name is not disclosed}
#' }
"undisclosed_names"

#' Data on firms suffering natural disasters
#'
#' Data on firms suffering natural disasters based on the sample
#' in Michels (2017).
#'
#' @format A tibble with 423 rows and 12 variables:
#' \describe{
#'   \item{cusip}{CUSIP supplied by Michels (2017)}
#'   \item{eventdate}{Date of relevant natural disaster supplied by Michels (2017)}
#'   \item{cik}{Matched CIK (SEC firm identifier)}
#'   \item{permno}{Matched PERMNO (CRSP security identifier)}
#'   \item{gvkey}{Matched GVKEY (Compustat firm identifier)}
#'   \item{date_filed}{Date of next filing of type 10-Q, 10-K, 10QSB, 10-K405 after event}
#'   \item{form_types}{List of relevant form types filed on date_filed}
#'   \item{next_period_end}{Next fiscal period-end after event date}
#'   \item{next_fqtr}{Fiscal quarter of next period-end after event date}
#'   \item{prev_period_end}{Last fiscal period-end before event date}
#'   \item{prev_fqtr}{Fiscal quarter of last period-end before event date}
#'   \item{recognize}{Indicator for event being recognized (next_period_end before date_filed)}
#' }
#' @source \doi{10.1111/1475-679X.12128}
"michels_2017"

#' Data on public float
#'
#' Data on public float of listed companies from Iliev (2010).
#'
#' @format A tibble with 7,214 and 9 variables:
#' \describe{
#'   \item{gvkey}{Compustat firm identifier (GVKEY)}
#'   \item{fyear}{Fiscal year}
#'   \item{fdate}{Date of end of fiscal year}
#'   \item{pfdate}{Date for public float value}
#'   \item{pfyear}{Year for public float value}
#'   \item{publicfloat}{Public float in $ million}
#'   \item{mr}{Indicator for filing of a management report}
#'   \item{af}{Indicator for accelerator filer}
#'   \item{cik}{SEC firm identifier (CIK)}
#' }
#' @source \doi{10.1111/j.1540-6261.2010.01564.x}
"iliev_2010"

#' Firm-years in RDD analysis of Bloomfield (2021)
#'
#' Firm-years in RDD analysis of Bloomfield (2021).
#'
#' @format A tibble with 1,855 rows and 2 variables:
#' \describe{
#'   \item{fyear}{Fiscal year}
#'   \item{permco}{CRSP firm identifier (PERMCO)}
#' }
#' @source \doi{10.1111/1475-679X.12346}
"bloomfield_2021"

#' Treatment indicators for SHO pilot firms
#'
#' A data set containing the tickers, GVKEYs, and
#' treatment indicator for SHO pilot program.
#'i
#' @format A tibble with 3,030 rows × 4 variables.
#' \describe{
#'   \item{ticker}{Ticker}
#'   \item{gvkey}{GVKEY (firm identifier)}
#'   \item{permno}{PERMNO (CRSP security identifier)}
#'   \item{pilot}{SHO pilot program treatment indicator}
#' }
#' @source \doi{10.1111/jofi.12369}
"fhk_pilot"

#' Firm-years for replication of Fang, Huang and Karpoff (2016)
#'
#' A data set containing the GVKEYs and
#' datadates for firm-years used in Fang, Huang and Karpoff (2016).
#'
#' @format A tibble with 60,272 rows × 2 variables.
#' \describe{
#'   \item{gvkey}{GVKEY (firm identifier)}
#'   \item{datadate}{Fiscal year-end}
#' }
#' @source \doi{10.1111/jofi.12369}
"fhk_firm_years"

#' Tickers of pilot firms for Reg SHO.
#'
#' A data set containing the tickers and
#' company names for pilot firms from Reg SHO pilot.
#' Data are scraped from the SEC's own website.
#'
#' @format A tibble with 986 rows × 2 variables.
#' \describe{
#'   \item{ticker}{Ticker}
#'   \item{co_name}{Company name}
#' }
#' @source \url{https://www.sec.gov/rule-release/34-50104}
"sho_tickers"

#' Russell 3000 stocks at time of SEC Reg SHO sample formation.
#'
#' A data set containing the tickers and
#' company names for Russell 3000 at time SEC created the pilot sample.
#' Data are created from sample supplied by FHK.
#'
#' @format A tibble with 3000 rows × 2 variables.
#' \describe{
#'   \item{russell_ticker}{Ticker}
#'   \item{russell_name}{Company name}
#' }
#' @source \doi{10.1111/jofi.12369}
"sho_r3000"

#' Russell 3000 sample used by SEC
#'
#' A data set containing the tickers, PERMNOs, and
#' treatment assignments for Russell 3000 sample used by SEC.
#'
#' @format A tibble with 2,954 rows × 3 variables.
#' \describe{
#'   \item{ticker}{Ticker}
#'   \item{permno}{PERMNO (CRSP security identifier)}
#'   \item{pilot}{Indicator for stock being part of Reg SHO pilot program}
#' }
#' @source \url{https://iangow.github.io/far_book/natural-revisited.html#the-sho-pilot-sample}
"sho_r3000_sample"

#' Russell 3000 sample used by SEC with GVKEYs
#'
#' A data set containing the tickers, PERMNOs, GVKEYs, and
#' treatment assignments for Russell 3000 sample used by SEC.
#'
#' @format A tibble with 2,951 rows × 3 variables.
#' \describe{
#'   \item{ticker}{Ticker}
#'   \item{permno}{PERMNO (CRSP security identifier)}
#'   \item{gvkey}{GVKEY (Compustat firm identifier)}
#'   \item{pilot}{Indicator for stock being part of Reg SHO pilot program}
#' }
#' @source \url{https://iangow.github.io/far_book/natural-revisited.html#the-sho-pilot-sample}
"sho_r3000_gvkeys"

#' Event windows from Zhang (2007)
#'
#' A data set containing the event windows used in Zhang (2007).
#' Data obtained from Panel of Table of Zhang (2007).
#'
#' @format A tibble with 17 rows × 3 variables.
#' \describe{
#'   \item{event}{Identifier for the event}
#'   \item{beg_date}{First date of event window}
#'   \item{end_date}{Last date of event window}
#' }
#' @source \doi{10.1016/j.jacceco.2007.02.002}
"zhang_2007_windows"

#' Event dates from Zhang (2007)
#'
#' A data set containing the event dates used in Zhang (2007).
#' Data obtained from Panel of Table of Zhang (2007).
#' If an event spans multiple dates, then a row is
#' included for each date.
#'
#' @format A tibble with 30 rows × 3 variables.
#' \describe{
#'   \item{event}{Identifier for the event}
#'   \item{date}{Date of event}
#'   \item{event_desc}{Description of the event}
#' }
#' @source \doi{10.1016/j.jacceco.2007.02.002}
"zhang_2007_events"


#' AAERs from Bao et al. (2020)
#'
#' A data set containing AAER firms-years used in Bao et al. (2020).
#'
#' @format A tibble with 415 rows and 4 variables:
#' \describe{
#'   \item{p_aaer}{AAER identifier}
#'   \item{gkvey}{GVKEY (firm identifier)}
#'   \item{min_year}{First affected year}
#'   \item{max_year}{Last affected year}
#'}
#' @source \doi{10.1111/1475-679X.12292}
"aaer_firm_year"

#' Australian banks
#'
#' A data set containing identifying information for 10 Australian banks.
#'
#' @format A tibble with 10 rows and 3 variables:
#' \describe{
#'   \item{gvkey}{GVKEY (firm identifier)}
#'   \item{ticker}{Stock exchange ticker}
#'   \item{co_name}{Bank name}
#'}
"aus_banks"

#' Australian bank fundamental data
#'
#' A data set containing fundamental financial information for Australian banks.
#'
#' @format A tibble with 283 rows and 7 variables:
#' \describe{
#'   \item{gvkey}{GVKEY (firm identifier)}
#'   \item{datadate}{Fiscal year-end}
#'   \item{at}{Total assets}
#'   \item{ib}{Income before extraordinary items}
#'   \item{xi}{Extraordinary items}
#'   \item{do}{Income from discontinued operations}
#'}
"aus_bank_funds"

#' Australian bank stock market data
#'
#' A data set containing fundamental financial information for Australian banks.
#'
#' @format A tibble with 3,047 rows and 4 variables:
#' \describe{
#'   \item{gvkey}{GVKEY (firm identifier)}
#'   \item{datadate}{Last trading date of month}
#'   \item{ret}{Stock return for month}
#'   \item{mkt_cap}{Market capitalization on datadate}
#'}
"aus_bank_rets"

#' Data for CMSW
#'
#' Data on whistleblowers and enforcement actions from Call et al. (2018)
#'
#' @format A tibble with 1,133 rows and 31 variables:
#' \describe{
#'   \item{recid}{CMSW record identifier}
#'   \item{firmpenalty}{The total firm civil and criminal monetary penalties assessed against the firm, its parent and subsidiaries consisting of disgorgement, prejudgment interest, civil fines, criminal restitution, and criminal fines in millions of dollars}
#'   \item{otherpenalty}{The total firm civil and criminal monetary penalties assessed against the agent firms and/or respondents (e.g., the audit firm, bankers, suppliers) in connection with the financial misrepresentation of the target firm, in millions of dollars}
#'   \item{emppenalty}{The total civil and criminal penalties assessed against all employees consisting of disgorgement, prejudgment interest, civil fines, criminal restitution, and criminal fines in millions of dollars}
#'   \item{empprisonmos}{Total incarceration consisting of jail, prison, home detention, and halfway house in months imposed upon employee respondents named in the enforcement action}
#'   \item{selfdealflag}{An indicator variable equal to one if the violation includes self-dealing such as embezzlement and theft by respondents and equal to zero otherwise}
#'   \item{blckownpct}{The percentage of blockholder ownership, defined as owners with at least five percent of common shares outstanding from the last 10-K or DEF 14A prior to the first public announcement the firm may be (is) subject to a regulatory enforcement action}
#'   \item{initabret}{The value-weighted market-adjusted return measured at the close of trading on the initial public announcement date that the firm may be (is) subject to a regulatory enforcement action}
#'   \item{wbflag}{An indicator variable equal to one if a whistleblower is associated with the enforcement action and equal to zero otherwise}
#'   \item{tousesox}{Post-SOX action flag}
#'   \item{lnvioperiod}{The natural logarithm of the total time the violation occurred in months as indicated in the regulatory enforcement proceedings}
#'   \item{bribeflag}{An indicator variable equal to one if the enforcement actions includes charges under the Foreign Corrupt Practices Act for bribery of a foreign official and zero otherwise}
#'   \item{mobflag}{An indicator variable equal to one if violation or any of the respondents were associated with a known organized crime family and zero otherwise}
#'   \item{deter}{An indicator variable equal to one if the violation includes an offense for either option backdating, insider trading, or an offense related to an offering, IPO, merger, or reverse merger and equal to zero otherwise}
#'   \item{lnempcleveln}{The natural logarithm of the total number of C-level respondents (e.g. CEO, COO, CFO, CAO, CMO, and CIO) named in the enforcement action}
#'   \item{lnuscodecnt}{The natural logarithm of the total number of unique code sections and rules violated (charges) associated with the enforcement action}
#'   \item{viofraudflag}{n indicator variable equal to one if fraud under 15 USC §§ 77q, 78j(b), or rules promulgated thereunder are included among the charges in the enforcement action}
#'   \item{misledflag}{An indicator variable equal to one if the violation included violations of 17 CFR 240.13b2-2 that prohibits materially false or misleading statement to an accountant in connection with the preparation of financial statements and zero otherwise}
#'   \item{audit8flag}{An indicator variable equal to one if the misreporting firm used a Big N auditor, and equal to zero otherwise}
#'   \item{exectermflag}{An indicator variable equal to one if the firm terminated an executive respondent as a result of the violations and equal to zero otherwise}
#'   \item{coopflag}{An indicator variable equal to one if the firm received credit in the assessment of penalties for cooperation as stated in regulatory enforcement documents during the course of the investigation and equal to zero otherwise}
#'   \item{impedeflag}{An indicator variable equal to one if regulators acknowledged they were deliberately misled and/or charges were included for lying to investigators and equal to zero otherwise}
#'   \item{pctinddir}{The percentage of the firm's directors that are independent from the last 10-K or DEF 14A prior to the first public announcement the firm may be (is) subject to a regulatory enforcement action}
#'   \item{recidivist}{An indicator variable equal to one if the firm was previously the subject of a securities regulatory enforcement action and equal to zero otherwise}
#'   \item{lnmktcap}{The natural logarithm of the market value of equity measured in millions of dollars prior to the first public announcement that the firm may be (is) subject to a regulatory enforcement action}
#'   \item{mkt2bk}{The sum of market value of equity plus total assets minus total debt divided by total assets with market value determined below and total assets and total debt measured at the last fiscal year end prior to the first public announcement the firm may be (is) subject to a regulatory enforcement action}
#'   \item{lev}{Total debt divided by total assets measured at the last fiscal year end prior to the first public announcement the firm may be (is) subject to a regulatory enforcement action}
#'   \item{lndistance}{The natural logarithm of the distance in miles from the location of the firm's headquarters to the offices of the regulator assigned to the geographic area of the firm's headquarter location (closer of the SEC Regional Office or DOJ U.S. District Attorney).}
#'   \item{ff12}{Fama-French industry code (12-industry)}
#'   \item{wbsource}{Whistleblower data source}
#'   \item{wbtype}{Whistleblower type: tipster or nontipster}
#' }
#' @source \doi{10.1111/1475-679X.12177}
"cmsw_2018"

#' GVKEY-CIK links
#'
#' Link table from GVKEYs to CIKs
#'
#' @format A tibble with 76,346 rows and 5 variables:
#' \describe{
#'   \item{gvkey}{GVKEY (Compustat firm identifier)}
#'   \item{iid}{Issue ID}
#'   \item{cik}{CIK (SEC firm identifier)}
#'   \item{first_date}{First link date}
#'   \item{last_date}{Last link date}
#' }
"gvkey_ciks"
