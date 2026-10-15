## Test environments

* Local macOS arm64, R 4.6.1: `R CMD check --as-cran --run-donttest`,
  including the PDF manual, completed with 0 errors, 0 warnings and 0 notes.
* Windows R-devel: submitted to win-builder; result pending.

## Additional checks

* `urlchecker::url_check()` found no URL problems.
* The full local test suite passed 499 assertions, including synthetic DuckDB
  and PostgreSQL fixtures. Two live-download tests were skipped in that run;
  the release check separately ran the internet-dependent help examples.
* Every exported function is covered by an example and return-value
  documentation. Credential-dependent database examples explain why they are
  wrapped in `\dontrun{}`; download examples use `\donttest{}`.
* Software names are quoted in DESCRIPTION and the book reference is given
  as authors (year) followed by its DOI.

## Reverse dependencies

There are no CRAN reverse dependencies in Depends, Imports, LinkingTo or
Suggests, verified against the current CRAN package database.

## Release changes

This update corrects event-return calculations and boosting edge cases,
refreshes the AAER dates and corrects selected public-float dates, and expands
the documentation. Details are in NEWS.md.
