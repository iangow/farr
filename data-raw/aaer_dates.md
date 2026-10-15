# AAER data preparation

`get_aaer_dates.R` rebuilds the maintained dataset from a raw SEC scrape and
explicit reconciliation inputs. The raw scrape is never edited to hide source
errors. The current build uses the 15 October 2026 snapshot, covering index dates
from 18 October 1999 through 8 October 2026.

## Rebuild and validate

Run from the `farr` repository root:

```sh
# Optional: download a new snapshot into a NEW directory.
Rscript data-raw/refresh_aaer_dates.R data-raw/aaer_dates_refresh_YYYY-MM-DD

# Reproduce the maintained build offline from the existing snapshot.
Rscript data-raw/get_aaer_dates.R data-raw/aaer_dates_refresh_2026-10-15
Rscript data-raw/check_aaer_dates.R
Rscript -e 'load("data/aaer_dates.RData"); testthat::test_file("tests/testthat/test-aaer_dates.R", stop_on_failure=TRUE)'
```

The build contains 3,386 rows: 3,361 scraped associations, minus one exact
duplicate, plus AAER-1470 and 25 historical supplements. Different source entries
can share an AAER number. Only full-row duplicates are removed.

## Corrections and historical supplements

`aaer_dates_corrections.csv` records the action, expected index date, verified date,
release URL and rationale for each maintained exception:

- **AAER-1209:** retain 1999-11-16, the date stated in both numbered headers of
  [LR-16354](https://www.sec.gov/enforcement-litigation/litigation-releases/lr-16354).
  The index lists 1999-11-17. The build accepts either the known index date or an
  upstream fix to November 16, and fails on an unexpected new date.
- **AAER-1470:** restore the observation dated 2001-10-23 from
  [the SEC report](https://www.sec.gov/litigation/investreport/34-44969.htm).
  The current index omits it. If it reappears with the verified date, the build
  keeps the scraped entry without appending another copy.
- **AAER-2218:** use the verified canonical identifier and 2005-03-24 date from
  [LR-19156](https://www.sec.gov/enforcement-litigation/litigation-releases/lr-19156).
  The old `AAER-x2218` entry is not appended alongside the now-present AAER-2218.
  A restoration record also covers a future omission of the canonical entry.

`aaer_dates_historical.csv` preserves the other 25 absent identifiers from the
pre-refresh data without changing their values. It is the prior investigation's
`old_numbers_missing.csv`, excluding AAER-1470 and AAER-x2218. A historical entry
is appended only while its identifier is absent from the scrape. These are
preservation records, not 25 newly verified release records. In particular,
IA-2344 is retained as historically recorded, and AAER-2493, AAER-2571 and
AAER-2579 retain their missing dates and `Intentionally omitted` descriptions.

The unmodified pre-refresh table is saved as `aaer_dates_2021.rds`; its original
RData source SHA-256 is
`e6ff02c67c474d8ebdab6bdf933e317b3d893491c2c478ed010c3fed1c60e67b`.
`compare_aaer_dates.R` uses this frozen baseline so rebuilding the package does
not change the meaning of the original comparison. The earlier
[investigation](aaer_dates_refresh_2026-10-15/README.md) remains a record of the
uncorrected scrape and its limitations.

The historical CSV descriptions retain their original whitespace, including
line breaks inside quoted fields. `.gitattributes` preserves these bytes and
exempts these source fields from trailing-whitespace checks.

Index dates and descriptions outside the documented checks are not all verified
against underlying releases. Distinct repeated identifiers, including the
questionable LR-19030 association with AAER-2165, remain visible. The July 24/25
entries for AAER-3569 and AAER-3570 remain separate source entries. These cases do
not match the bundled Bao `p_aaer` identifiers. The source-backed corrections and
historical supplements ensure no previously known Bao release date is lost.

Relative to the frozen baseline, 13 Bao-derived firm-years gain an observable
date and eight have a corrected date; none loses a known date. The detailed
comparison is in `aaer_dates_refresh_2026-10-15/reconciled_bao_date_changes.csv`.
This checks the date mapping before the Compustat features join; it does not
rerun the book's prediction models.

## Keep era_pl and era_py synchronized

The canonical values and correction rules live in `farr`. Both Python namespaces
load the same `era_py/src/era_data/_data/aaer_dates.parquet`. From the `era_py` root:

```sh
Rscript data-raw/convert_farr_data_to_parquet.R ../farr/data src/era_data/_data aaer_dates
uv run --no-sync python scripts/sync_dataset_metadata.py ../farr --dataset aaer_dates
Rscript data-raw/convert_farr_data_to_parquet.R --check ../farr/data src/era_data/_data aaer_dates
uv run --no-sync pytest tests/test_aaer_data.py
```

The read-only check verifies every data value, row order, column type, original
R-type metadata, and the canonical R source-file hash. It fails on stale data or
metadata. The Python regression tests also compare the Polars and pandas loaders
and check the source-backed dates, duplicate behavior and missing-date records.
Rebuild and synchronize both copies before releasing either package; the steps
above do not publish a release or update installed packages in other environments.
