# Public-float date corrections for `iliev_2010`

`public-float-data-complete.csv` is preserved as supplied by Peter Iliev. The
repository copy is byte-for-byte identical to the original email attachment
(SHA-256: `7d52dc5aab9fcb886352d08f85347815b9c1095dc2231622af2633fc827024b2`).
The fractional years and incorrect months below are present in that source.

`iliev_2010_date_corrections.csv` records corrections verified against the
companies' Form 10-K cover pages on 15 October 2026. Each public-float amount
matches the corresponding filing exactly. The `source_url` column links to
the filing supporting each correction.

| Company | CIK | Dataset fiscal year | Original public-float date (month/day/year) | Corrected date | Public float ($) |
|---|---:|---:|---|---|---:|
| Spectrum Control | 92769 | 2004 | 1/31/2004.5 | 2005-01-31 | 41,244,671 |
| Whitehall Jewellers | 868984 | 2003 | 6/31/2001.6 | 2002-07-31 | 161,611,326 |
| Whitehall Jewellers | 868984 | 2004 | 6/31/2002.8 | 2003-07-31 | 169,315,283 |
| Whitehall Jewellers | 868984 | 2005 | 6/30/2004 | 2004-07-30 | 96,774,556 |
| Whitehall Jewellers | 868984 | 2006 | 6/29/2005.2 | 2005-07-29 | 89,827,857 |

The table is keyed by `cik` and `fyear`. Its `pfmonth`, `pfday`, `pfyear`, and
`publicfloat` columns contain the original source values; `publicfloat` is in
dollars before the package's conversion to millions. `corrected_pfdate` is
the complete date reported in the filing. The generation script verifies
that each correction matches exactly one source row and that its original
values still agree, then derives both `pfyear` and `pfdate` from the corrected
date. It does not round years or adjust other invalid dates automatically.

Run `Rscript data-raw/create_iliev_2010.R` from the package root to regenerate
`data/iliev_2010.rda`. These corrections change five `pfdate` values and four
`pfyear` values; all other data values and the 7,214 rows are retained.

Other source anomalies remain, including invalid fiscal dates and some
missing public-float dates. For example, Spectrum's 2004 fiscal date is
November 31 in the source but November 30 in its filing. This correction
table is limited to the public-float dates investigated in
[issue #28](https://github.com/iangow/farr/issues/28); it is not a comprehensive
audit of the source data.
