# Changelog

## farr 1.0.9000

- Added
  [`duckdb_to_parquet()`](https://iangow.github.io/farr/reference/duckdb_to_parquet.md).
- [`get_ff_ind()`](https://iangow.github.io/farr/reference/get_ff_ind.md)
  now caches downloaded Fama-French industry zip files by default and
  supports `refresh_cache = TRUE`.
- Added a pkgdown site with Bootstrap 5 styling, a dark-mode toggle, and
  a Quarto article scaffold.

## farr 1.0.0

CRAN release: 2025-11-17

- The are now no duplicates in `gvkey_ciks`.
- There is a `keep_max` argument in
  [`get_me_breakpoints()`](https://iangow.github.io/farr/reference/get_me_breakpoints.md).
- Documentation fixes have been made.

## farr 0.3.2

CRAN release: 2025-09-01

- The
  [`get_me_breakpoints()`](https://iangow.github.io/farr/reference/get_me_breakpoints.md)
  function works with current data format.

## farr 0.3.1

- Updated code to reflect changes in `tidyselect` package.
- Updated code to reflect changes in Fama-French data.

## farr 0.3.0

CRAN release: 2024-02-29

- Tweaked `test_scores` data (now two files).
- Added
  [`system_time()`](https://iangow.github.io/farr/reference/system_time.md).

## farr 0.2.39

CRAN release: 2023-12-13

## farr 0.2.38

- Tweaks for CRAN submission.

## farr 0.2.36

- Added parquet-related functions:
  [`load_parquet()`](https://iangow.github.io/farr/reference/load_parquet.md)
  and
  [`pg_to_parquet()`](https://iangow.github.io/farr/reference/pg_to_parquet.md).
- Added `gvkey_ciks` data.

## farr 0.2.35

- Added `cmsw_2018` data.
- Fixes to documentation.

## farr 0.2.34

- Fixes to data and documentation.

## farr 0.2.33

- Updated tests.

## farr 0.2.32

- Removed duplicates from names data.

## farr 0.2.30

CRAN release: 2023-01-28

- Added `aus_banks` data sets.

## farr 0.2.29

- Added `rusboost` function.

## farr 0.2.28

- Added Zhang (2007) data.

## farr 0.2.27

CRAN release: 2022-06-30

- Added tests.
- Added examples.

## farr 0.2.26

- Added `sho_r3000_sample` data set.
- Added `sho_r3000_gvkeys` data set.

## farr 0.2.25

- Replaced `df_to_pg()` with `copy_inline()` from `dbplyr` package.

## farr 0.2.24

- Added `sho_r3000` data set.
- Renamed FHK data sets.

## farr 0.2.23

- Added `sho_tickers` data set.

## farr 0.2.22

- Added `form_deciles` function.

## farr 0.2.21

- Added Reg SHO data sets (`sho_pilot` and `sho_firm_years`).

## farr 0.2.20

- Added `get_size_rets_monthly` and `get_me_breakpoints` functions.

## farr 0.2.16

- Removed `read_only` arguments.

## farr 0.2.15

- Added random assignment option to `get_test_scores`.

## farr 0.2.14

- Tweaked `df_to_pg()` to use `VALUES`.

## farr 0.2.13

- Use dbQuoteLiteral() in df_to_pg().

## farr 0.2.12

- Added
  [`get_test_scores()`](https://iangow.github.io/farr/reference/get_test_scores.md)
  function.

## farr 0.2.11

- Fixes to cumulative returns code.
- Added monthly returns.

## farr 0.2.10

- Added two data sets related to LLZ 2018.
  - `llz_2018`: GVKEYs.
  - `undisclosed_names`: For disclosure variable.

## farr 0.2.9

- Added `idd_dates` (data) and
  [`get_idd_periods()`](https://iangow.github.io/farr/reference/get_idd_periods.md)
  (function)
- Added `state_hq` data.

## farr 0.2.8

- Reverted to earlier form of `df_to_pg()` function
  ([\#1](https://github.com/iangow/farr/issues/1)).
- Added `test_scores` data.

## farr 0.2.7

- Added `comp` data set.

## farr 0.2.6

- Now use
  [`DBI::dbQuoteLiteral()`](https://dbi.r-dbi.org/reference/dbQuoteLiteral.html)
  in `df_to_pg()` function
  ([\#1](https://github.com/iangow/farr/issues/1)).

## farr 0.2.5

- Added `get_ff_ind` function.

## farr 0.2.4

- Added `get_got_data` function.
