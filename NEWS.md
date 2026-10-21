# farr 1.1.1
* Cumulative event returns explicitly reject returns below -1 in DuckDB,
  including DuckDB 2.0 with `ieee_floating_point_ops` enabled (#34).

# farr 1.1.0
* Expanded runnable examples and return-value documentation, documented the
  prediction method for `rusboost()` objects, and clarified which examples
  require internet access or database credentials.
* `get_size_rets_monthly()` now downloads over HTTPS to a temporary file,
  removes it even on failure, and restores `VROOM_CONNECTION_SIZE` after parsing
  instead of changing the caller's files or environment (#33).
* `rusboost()` now retains a perfect learner as the sole predictive learner
  with weight 1 and reports an error if no usable learner is fitted (#32).
  Random undersampling handles singleton classes safely and validates class
  counts and majority sample sizes.
* Monthly cumulative-return windows now include the full ending month for
  nonzero offsets, including transitions from shorter to longer months.
* Daily and monthly cumulative event returns now handle complete losses
  (`ret = -1`) in stocks and benchmarks (#31). Missing-value handling is
  unchanged, and returns below -1 continue to raise an error.
* `get_event_rets()` now retains non-trading-day announcements (#30),
  measuring relative trading days from the next trading day while keeping
  the original announcement dates.
* Corrected `get_got_data()` to use `rho_E` for firm-specific error
  persistence (#29). Simulations with unequal `rho_X` and `rho_E` now
  follow the requested error process; equal-parameter results are unchanged.
* Refreshed `aaer_dates` through October 2026, with 3,386 rows. The data steps
  apply source-backed date and coverage corrections, preserve historical
  entries absent from the current SEC index, and remove exact duplicates (#27).
* Corrected five public-float dates in `iliev_2010` using the original 10-Ks,
  including four fractional years. The original CSV is preserved, with an
  explicit correction table and filing references in `data-raw` (#28).
* Corrected tree weights in `predict.rusboost(type = "prob")` (#26), including
  predictions for a single observation or weak learner. Probability predictions
  require finite, nonnegative weights with a positive finite total.
* Corrected the `by_tag_year` documentation: `year_total` counts questions
  across all tags in a year, rather than questions with a specific tag.
* `get_ff_ind()` now caches downloaded Fama-French industry zip files by
  default and supports `refresh_cache = TRUE`.
* Added a pkgdown site with Bootstrap 5 styling, a dark-mode toggle, and a
  Quarto article scaffold.

# farr 1.0.1
* Added `duckdb_to_parquet()`.
* Fixed the lazy table returned by `duckdb_to_parquet()` by removing the
  `dbplyr::sql()` wrapper around `read_parquet()`.
* Updated internet-dependent examples and tests so they do not run on CRAN.

# farr 1.0.0
* The are now no duplicates in `gvkey_ciks`.
* There is a `keep_max` argument in `get_me_breakpoints()`.
* Documentation fixes have been made.

# farr 0.3.2
* The `get_me_breakpoints()` function works with current data format.

# farr 0.3.1

* Updated code to reflect changes in `tidyselect` package.
* Updated code to reflect changes in Fama-French data.

# farr 0.3.0

* Tweaked `test_scores` data (now two files).
* Added `system_time()`.

# farr 0.2.39

# farr 0.2.38

* Tweaks for CRAN submission.

# farr 0.2.36

* Added parquet-related functions: `load_parquet()` and `pg_to_parquet()`.
* Added `gvkey_ciks` data.

# farr 0.2.35

* Added `cmsw_2018` data.
* Fixes to documentation.

# farr 0.2.34

* Fixes to data and documentation.

# farr 0.2.33

* Updated tests.

# farr 0.2.32

* Removed duplicates from names data.

# farr 0.2.30

* Added `aus_banks` data sets.

# farr 0.2.29

* Added `rusboost` function.

# farr 0.2.28

* Added Zhang (2007) data.

# farr 0.2.27

* Added tests.
* Added examples.

# farr 0.2.26

* Added `sho_r3000_sample` data set.
* Added `sho_r3000_gvkeys` data set.

# farr 0.2.25

* Replaced `df_to_pg()` with `copy_inline()` from `dbplyr` package.

# farr 0.2.24

* Added `sho_r3000` data set.
* Renamed FHK data sets.

# farr 0.2.23

* Added `sho_tickers` data set.

# farr 0.2.22

* Added `form_deciles` function.

# farr 0.2.21

* Added Reg SHO data sets (`sho_pilot` and `sho_firm_years`).

# farr 0.2.20

* Added `get_size_rets_monthly` and `get_me_breakpoints` functions.

# farr 0.2.16

* Removed `read_only` arguments.

# farr 0.2.15

* Added random assignment option to `get_test_scores`.

# farr 0.2.14

* Tweaked `df_to_pg()` to use `VALUES`.

# farr 0.2.13

* Use dbQuoteLiteral() in df_to_pg().

# farr 0.2.12

* Added `get_test_scores()` function.

# farr 0.2.11

* Fixes to cumulative returns code.
* Added monthly returns.

# farr 0.2.10

* Added two data sets related to LLZ 2018.
    * `llz_2018`: GVKEYs.
    * `undisclosed_names`: For disclosure variable.

# farr 0.2.9

* Added `idd_dates` (data) and `get_idd_periods()` (function)
* Added `state_hq` data.

# farr 0.2.8

* Reverted to earlier form of `df_to_pg()` function (#1).
* Added `test_scores` data.

# farr 0.2.7

* Added `comp` data set.

# farr 0.2.6

* Now use `DBI::dbQuoteLiteral()` in `df_to_pg()`  function (#1).

# farr 0.2.5

* Added `get_ff_ind` function.

# farr 0.2.4

* Added `get_got_data` function.
