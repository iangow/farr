# AAER dates from SEC

A data set containing dates and descriptions for AAERs.

## Usage

``` r
aaer_dates
```

## Format

A tibble with 3,386 rows and 4 variables:

- aaer_num:

  AAER number

- aaer_date:

  Date

- aaer_desc:

  Description

- year:

  Year of AAER

## Details

The SEC index was refreshed through October 8, 2026. Exact duplicate
rows are removed; distinct entries sharing an AAER number are retained.
Source-backed corrections retain November 16, 1999 for AAER-1209 and
restore AAER-1470 dated October 23, 2001. Historical entries missing
from the current index are preserved, including three intentionally
omitted numbers with missing dates. The malformed historical identifier
AAER-x2218 is replaced by AAER-2218. Raw snapshots, historical
supplements, and the correction table with release links are maintained
in `data-raw`; see also [the refresh
investigation](https://github.com/iangow/farr/issues/27). Index dates
have not all been checked against the underlying releases.
