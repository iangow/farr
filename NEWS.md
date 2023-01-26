# farr

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
