# AAER refresh and comparison, 15 October 2026

This is a separate, uncorrected snapshot of the current SEC AAER index and an
investigation of [farr issue 27](https://github.com/iangow/farr/issues/27).
This report describes the original comparison, before the package data were
rebuilt. The uncorrected snapshot remains unchanged. The subsequent reconciled
build is documented in [the maintained data steps](../aaer_dates.md).

The scrape removes the particular AAER-1670 duplication, but a wholesale
replacement would introduce other problems. A reconciled update should retain
source-verified historical releases, add verified missing releases, and resolve
date conflicts against the releases themselves.

## Coverage and comparison

All 47 index pages for 1999-2026 were downloaded. Their stated row ranges and
totals account for 3,339 index entries. Some entries reference multiple AAER
numbers, giving 3,361 number-to-entry associations. Repeated mentions of a number
within one entry are expanded only once. Distinct index entries are retained.
Every displayed date was parsed explicitly and checked against the HTML timestamp
in America/New_York. This avoids automatic date guessing problems with `Sept.`.
The resulting dates run from 1999-10-18 through 2026-10-08; 2026 is a partial year.

| Measure | Bundled | Fresh index |
| --- | ---: | ---: |
| Rows, 1999-2021 | 2,920 | 3,053 |
| Rows, 2022-2026 | 0 | 308 |
| Total rows | 2,920 | 3,361 |
| Excess exact duplicate rows | 1 | 1 |

The 308 later rows comprise 88 in 2022, 111 in 2023, 64 in 2024, 22 in 2025,
and 23 in 2026. The old snapshot ended on 2021-02-23; the fresh index has 72
additional rows later in 2021. Through the old last date, the fresh index has
2,981 rows. These are index counts, not a claim of exhaustive SEC coverage.

Of the old distinct `(aaer_num, aaer_date)` pairs, 2,846 remain and 71 are absent.
There are 492 new pairs overall and 47 shared identifiers have changed date sets.
Twenty-seven old identifiers are absent altogether. These include three
`Intentionally omitted` placeholders with missing dates, the malformed
`AAER-x2218`, and `IA-2344`, as well as valid releases. Absence from the new index
is not evidence that the historical observation was wrong.

Descriptions are retained verbatim in both snapshots. Differences in titles,
formatting and release-number labels are substantial. The normalized-description
comparison is a diagnostic only; it is not used to merge or discard observations.

## Bao et al. (2020)

The authors' materials were checked at two immutable repository snapshots:

- [Pre-erratum snapshot, 16 March 2021](https://github.com/JarFraud/FraudDetection/tree/40ac85f8393ab4cb3bd8d5070ecc87d868541624), including `uscecchini28.csv` and `run_RUSBoost28.m`.
- [Current snapshot, 10 August 2022](https://github.com/JarFraud/FraudDetection/tree/2d10bc6c7ce18f5dea051a90d823546907abaa84), including `data_FraudDetection_JAR2020.csv` and `run_RUSBoost.m`.

The source `AAER_firm_year.csv` has 1,746 rows and is byte-identical across these
snapshots (Git blob `cf7c55e10ec309ef7c08affbd68127731570000c`). Both final datasets
have 146,045 rows and identical sets of `(gvkey, fyear, p_aaer, misstate)` values.
The current final data reproduce all 415 bundled `aaer_firm_year` mappings,
covering 412 distinct `p_aaer` values, without additions or removals.

None of 1670, 2127, 2215, 2165, 3570 or 3569 appears as `p_aaer` in the authors'
source data, either final dataset, or the bundled mappings. Thus these particular
repeated numbers do not directly join to the book's Bao-derived sample. This does
not mean the corresponding companies or cases are absent under other identifiers.

The [original MATLAB code](https://github.com/JarFraud/FraudDetection/blob/40ac85f8393ab4cb3bd8d5070ecc87d868541624/run_RUSBoost28.m)
uses `new_p_aaer` for serial-fraud recoding; the
[2022 code](https://github.com/JarFraud/FraudDetection/blob/2d10bc6c7ce18f5dea051a90d823546907abaa84/run_RUSBoost.m)
uses `p_aaer`. Both use a two-year training/test gap and neither uses AAER release
dates. The [SAS preparation code](https://github.com/JarFraud/FraudDetection/blob/2d10bc6c7ce18f5dea051a90d823546907abaa84/SAS%20coding.pdf)
joins the source fraud observations to Compustat using CIK and fiscal year, then
deduplicates firm/date and firm/year keys. It does not supply a rule for resolving
duplicate SEC index entries or conflicting release dates.

The book's separate date-based observability calculation therefore requires its
own source checks. Applying the uncorrected candidate would change the earliest
matched date for 27 firm-years: 13 gain a date, five lose a known date, and nine
change an existing date. This calculation uses the bundled mappings before the
join to Compustat features; it is not a rerun of the book's models or results.
All changes arise before 2022; the extension adds no matches to these mappings.

## Assessment of the original repeated numbers

| Number | Current index and underlying evidence |
| --- | --- |
| 1670 | One entry, 2002-11-21. The exact old duplicate is gone. The duplicate was already present in the corrected data commit `abe42f4` in April 2021; its source-page versus scraper origin remains unestablished. |
| 2127 | One entry, 2004-10-21. [LR-18936](https://www.sec.gov/enforcement-litigation/litigation-releases/lr-18936) explicitly confirms October 21; the old October 20 entry has disappeared. |
| 2215 | Still appears with both the Time Warner litigation announcement and the officers' administrative action. [LR-19147](https://www.sec.gov/enforcement-litigation/litigation-releases/lr-19147) explicitly identifies Time Warner as AAER-2216 and the officers' action as AAER-2215, both 2005-03-21. Extracting both referenced identifiers recovers 2216, which Bao uses for GVKEY 025056, fiscal 2000-2002. |
| 2165 | The new index associates this number with LR-19029 and LR-19030. The [LR-19030 text](https://www.sec.gov/enforcement-litigation/litigation-releases/lr-19030) concerns Lines Overseas and displays no AAER number. This remains an index-tagging concern, not an established second AAER-2165 release. |
| 3569 and 3570 | Both remain associated with 2014-07-24 administrative orders and the 2014-07-25 litigation announcement. [LR-23051](https://www.sec.gov/enforcement-litigation/litigation-releases/lr-23051) explicitly distinguishes the litigation date of July 25 from the AAER dates of July 24. These are separate source documents, not exact row duplicates. |

The fresh index instead contains two identical entries for **AAER-3448**,
2013-03-05, Peak Wealth Opportunities and David W. Dube. Both link to
[the same order](https://www.sec.gov/files/litigation/admin/2013/34-69036.pdf).
They occur at positions 74 and 75 in the 2013 index. They remain in the raw candidate
so that the comparison exposes this source duplication.

## Bao-relevant date and coverage checks

| AAER | Bundled date | Fresh index date | Underlying release assessment |
| --- | --- | --- | --- |
| 1209 | 1999-11-16 | 1999-11-17 | Keep November 16: [the release](https://www.sec.gov/enforcement-litigation/litigation-releases/lr-16354) explicitly dates both the LR and AAER November 16. |
| 1440 | 2001-06-20 | 2001-09-06 | Correct to September 6: [the release](https://www.sec.gov/enforcement-litigation/litigation-releases/lr-17118) confirms that date. |
| 1813 | 2003-07-07 | 2003-07-14 | Correct to July 14: [the release](https://www.sec.gov/enforcement-litigation/litigation-releases/lr-18229) confirms that date. |
| 1839 | 2003-08-12 | 2003-08-13 | Correct to August 13: [the order](https://www.sec.gov/enforcement-litigation/administrative-proceedings/34-48328) confirms that date. |
| 1470 | 2001-10-23 | Absent | Retain: [the report](https://www.sec.gov/litigation/investreport/34-44969.htm) explicitly confirms AAER-1470 and October 23. Dropping it loses dates for GVKEY 009538, fiscal 1995-1999. |
| 2493 | Missing; intentionally omitted | Absent | No date gained or lost. The source placeholder should not be assigned a guessed date. |

Seven Bao identifiers gain matches: 2062, 2064, 2097, 2105, 2216, 2218 and 3840.
Dates for six are supported by their release headers: [2062](https://www.sec.gov/enforcement-litigation/administrative-proceedings/34-50096)
and [2064](https://www.sec.gov/enforcement-litigation/administrative-proceedings/34-50098)
on 2004-07-27; [2097](https://www.sec.gov/files/litigation/admin/33-8482.pdf)
on 2004-09-14; [2216](https://www.sec.gov/enforcement-litigation/litigation-releases/lr-19147)
on 2005-03-21; [2218](https://www.sec.gov/enforcement-litigation/litigation-releases/lr-19156)
on 2005-03-24; and [3840](https://www.sec.gov/files/litigation/admin/2016/34-79702.pdf)
on 2016-12-29. The old data contain 2218 under the malformed identifier `AAER-x2218`.
For 2105, the index gives 2004-09-16, but the migrated
[LR-18888 text](https://www.sec.gov/enforcement-litigation/litigation-releases/lr-18888)
no longer displays its numbered/date header. Its release-date verification remains
open; the September 13 court-judgment date in the body is not the release date.

## Files and reproduction

From the repository root:

```sh
Rscript data-raw/refresh_aaer_dates.R data-raw/aaer_dates_refresh_2026-10-15
Rscript data-raw/compare_aaer_dates.R data-raw/aaer_dates_refresh_2026-10-15 /tmp/farr-bao
```

Use a new output directory for a fresh network snapshot. Existing HTML is reused.
The scraper uses an identifying user agent and sequential requests. Set
`SEC_USER_AGENT` to change the contact identification. Required R packages are
`dplyr`, `rvest`, `stringr`, `readr`, `tidyr`, and `xml2`; downloads use `curl`.

The optional final argument to the comparison script contains the authors'
downloaded CSVs. Their immutable URLs and file hashes are in `bao_sources.csv`.
Without that argument, the SEC-versus-bundled comparison still runs.

- `pages.csv`: requested URLs, page ranges/totals, download times and HTML hashes.
- `html/`: cached raw pages, excluded from Git.
- `index_rows.csv`: all source entries, including original displayed dates and links.
- `numbered_rows.csv`: source entries expanded to unique AAER identifiers per entry.
- `aaer_dates_candidate.csv` / `.rds`: four-column, uncorrected candidate data.
- `summary.csv` / `comparison_by_year.csv`: aggregate comparisons.
- `old_numbers_missing.csv` / `old_number_date_pairs_missing.csv` / `new_numbers.csv`
  / `new_number_date_pairs.csv` / `changed_date_sets.csv`: identifier and date changes.
- `old_exact_duplicates.csv` / `new_exact_duplicates.csv` and the repeated-number
  files: duplicate diagnostics, without deduplication by identifier.
- `bao_repeated_number_presence.csv`: membership checks in original/current author data.
- `bao_date_pair_changes.csv` / `bao_firm_year_first_date_changes.csv`: replication impact.

No corrections described here have been applied to the raw candidate. The package
now uses the separate reconciled build described in [the maintained data steps](../aaer_dates.md).
No book models were rerun, no publication was changed, and issue 27 remains open.
