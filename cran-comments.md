## Reason for this early update

farr 1.1.0 was published on CRAN on 2026-10-16. This patch is being submitted
so soon because of an upstream compatibility change in DuckDB 2.0.0.

On 2026-10-21, the DuckDB maintainer reported 12 failing farr tests in a
reverse-dependency check immediately before submitting DuckDB 2.0.0 to CRAN:
<https://github.com/iangow/farr/issues/34>.

With its default settings, DuckDB 2.0.0 returns NaN for the logarithm of a
negative number instead of raising an error. farr previously relied on that
error to reject returns below -1. This update adds an explicit check without
changing the user's DuckDB settings. It preserves complete-loss and
missing-value handling, and does not change the public API or packaged data.

## Additional checks

* Local macOS arm64, R 4.6.1: `R CMD check --as-cran --run-donttest`
  completed with 0 errors, 0 warnings and 1 NOTE, both with DuckDB 1.5.6
  and with the DuckDB 2.0.0 release candidate. These checks included the
  internet-dependent help examples and PDF manual.
* The sole NOTE was "Days since last update: 5". The reason for this early
  compatibility update is explained above.
* The full local suite passed 571 assertions with no failures or warnings,
  including synthetic DuckDB 2.0.0 and PostgreSQL fixtures. Two live-download
  tests were skipped in that run.
* The focused cumulative-return tests also passed 130 assertions with the
  current CRAN release of DuckDB, 1.5.6.
* Invalid stock, market and size-portfolio returns are tested with DuckDB's
  `ieee_floating_point_ops` setting both enabled and disabled, including
  windows containing complete losses or missing values. The tests verify
  that the connection setting is preserved.
* DuckDB 2.0.0 was tested using the maintainer's r-universe release candidate
  (R package version 1.99.99.9001, engine version v2.0.0).

## Reverse dependencies

The current CRAN package page lists no reverse dependencies.
