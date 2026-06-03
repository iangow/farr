# Package index

## Event Studies

Helpers for event dates, event returns, and event windows.

- [`get_annc_dates()`](https://iangow.github.io/farr/reference/get_annc_dates.md)
  : Produce a table mapping announcements to trading dates
- [`get_event_dates()`](https://iangow.github.io/farr/reference/get_event_dates.md)
  : Produce a table mapping announcements to trading dates
- [`get_event_rets()`](https://iangow.github.io/farr/reference/get_event_rets.md)
  : Produce a table of event returns
- [`get_event_cum_rets()`](https://iangow.github.io/farr/reference/get_event_cum_rets.md)
  : Produce a table of cumulative event returns
- [`get_event_cum_rets_mth()`](https://iangow.github.io/farr/reference/get_event_cum_rets_mth.md)
  : Produce a table of cumulative event returns using monthly data
- [`get_trading_dates()`](https://iangow.github.io/farr/reference/get_trading_dates.md)
  : Produce a table mapping dates on CRSP to "trading days"

## Data Retrieval

Helpers that retrieve external data or convert database outputs.

- [`get_ff_ind()`](https://iangow.github.io/farr/reference/get_ff_ind.md)
  : Fetch Fama-French industry grouping.
- [`get_me_breakpoints()`](https://iangow.github.io/farr/reference/get_me_breakpoints.md)
  : Create a table of with cut-offs for size portfolios
- [`get_size_rets_monthly()`](https://iangow.github.io/farr/reference/get_size_rets_monthly.md)
  : Create a table of monthly returns for size portfolios
- [`get_got_data()`](https://iangow.github.io/farr/reference/get_got_data.md)
  : Generate simulated data as described in Gow, Ormazabal and Taylor
  (2010).
- [`load_parquet()`](https://iangow.github.io/farr/reference/load_parquet.md)
  : Function to load parquet file into database.
- [`pg_to_parquet()`](https://iangow.github.io/farr/reference/pg_to_parquet.md)
  : Save WRDS table as parquet file.
- [`duckdb_to_parquet()`](https://iangow.github.io/farr/reference/duckdb_to_parquet.md)
  : Export a DuckDB-backed lazy table to Parquet via COPY

## Research Design

Utilities used in empirical accounting examples.

- [`form_deciles()`](https://iangow.github.io/farr/reference/form_deciles.md)
  : Form deciles

- [`get_idd_periods()`](https://iangow.github.io/farr/reference/get_idd_periods.md)
  : Period for Inevitable Disclosure Doctrine (IDD)

- [`get_test_scores()`](https://iangow.github.io/farr/reference/get_test_scores.md)
  : A function returning data on test_scores

- [`system_time()`](https://iangow.github.io/farr/reference/system_time.md)
  :

  Version of [`system.time()`](https://rdrr.io/r/base/system.time.html)
  that works with assignment

## Data Cleaning and Metrics

- [`truncate()`](https://iangow.github.io/farr/reference/truncate.md) :
  Truncate a vector.
- [`winsorize()`](https://iangow.github.io/farr/reference/winsorize.md)
  : Winsorize a vector
- [`auc()`](https://iangow.github.io/farr/reference/auc.md) : Area under
  curve
- [`confusion_stats()`](https://iangow.github.io/farr/reference/confusion_stats.md)
  : Confusion statistics.
- [`ndcg()`](https://iangow.github.io/farr/reference/ndcg.md) :
  Calculate metric: NDCG at k
- [`roc()`](https://iangow.github.io/farr/reference/roc.md) : A function
  returning data for a ROC plot.
- [`rus()`](https://iangow.github.io/farr/reference/rus.md) : Random
  under-sampling function
- [`rusboost()`](https://iangow.github.io/farr/reference/rusboost.md) :
  RUSBoost for two-class problems

## Data

Included data sets used by the book and examples.

- [`aaer_dates`](https://iangow.github.io/farr/reference/aaer_dates.md)
  : AAER dates from SEC
- [`aaer_firm_year`](https://iangow.github.io/farr/reference/aaer_firm_year.md)
  : AAERs from Bao et al. (2020)
- [`apple_events`](https://iangow.github.io/farr/reference/apple_events.md)
  : Dates for Apple Events
- [`aus_bank_funds`](https://iangow.github.io/farr/reference/aus_bank_funds.md)
  : Australian bank fundamental data
- [`aus_bank_rets`](https://iangow.github.io/farr/reference/aus_bank_rets.md)
  : Australian bank stock market data
- [`aus_banks`](https://iangow.github.io/farr/reference/aus_banks.md) :
  Australian banks
- [`bloomfield_2021`](https://iangow.github.io/farr/reference/bloomfield_2021.md)
  : Firm-years in RDD analysis of Bloomfield (2021)
- [`by_tag_year`](https://iangow.github.io/farr/reference/by_tag_year.md)
  : Tags on StackOverflow
- [`camp_attendance`](https://iangow.github.io/farr/reference/camp_attendance.md)
  : Camp attendance
- [`cmsw_2018`](https://iangow.github.io/farr/reference/cmsw_2018.md) :
  Data for CMSW
- [`comp`](https://iangow.github.io/farr/reference/comp.md) : Data on
  accruals and auditor choice
- [`fhk_firm_years`](https://iangow.github.io/farr/reference/fhk_firm_years.md)
  : Firm-years for replication of Fang, Huang and Karpoff (2016)
- [`fhk_pilot`](https://iangow.github.io/farr/reference/fhk_pilot.md) :
  Treatment indicators for SHO pilot firms
- [`gvkey_ciks`](https://iangow.github.io/farr/reference/gvkey_ciks.md)
  : GVKEY-CIK links
- [`idd_dates`](https://iangow.github.io/farr/reference/idd_dates.md) :
  Dates for Inevitable Disclosure Doctrine (IDD)
- [`iliev_2010`](https://iangow.github.io/farr/reference/iliev_2010.md)
  : Data on public float
- [`llz_2018`](https://iangow.github.io/farr/reference/llz_2018.md) :
  GVKEYs used in Li, Lin and Zhang (2018).
- [`michels_2017`](https://iangow.github.io/farr/reference/michels_2017.md)
  : Data on firms suffering natural disasters
- [`sho_r3000`](https://iangow.github.io/farr/reference/sho_r3000.md) :
  Russell 3000 stocks at time of SEC Reg SHO sample formation
- [`sho_r3000_gvkeys`](https://iangow.github.io/farr/reference/sho_r3000_gvkeys.md)
  : Russell 3000 sample used by SEC with GVKEYs
- [`sho_r3000_sample`](https://iangow.github.io/farr/reference/sho_r3000_sample.md)
  : Russell 3000 sample used by SEC
- [`sho_tickers`](https://iangow.github.io/farr/reference/sho_tickers.md)
  : Tickers of pilot firms for Reg SHO
- [`state_hq`](https://iangow.github.io/farr/reference/state_hq.md) :
  Data on firm headquarters based on SEC EDGAR filings
- [`test_scores`](https://iangow.github.io/farr/reference/test_scores.md)
  : Test scores
- [`undisclosed_names`](https://iangow.github.io/farr/reference/undisclosed_names.md)
  : Customer names that represent non-disclosures
- [`zhang_2007_events`](https://iangow.github.io/farr/reference/zhang_2007_events.md)
  : Event dates from Zhang (2007)
- [`zhang_2007_windows`](https://iangow.github.io/farr/reference/zhang_2007_windows.md)
  : Event windows from Zhang (2007)
