## Test environments

* Local macOS arm64, R 4.6.1: `R CMD check --as-cran --run-donttest`,
  including the PDF manual, completed with 0 errors, 0 warnings and 0 notes.
* Windows Server 2022 x64, R-devel (2026-10-14 r90673 ucrt): win-builder
  completed with 0 errors, 0 warnings and 0 notes.
  <https://win-builder.r-project.org/lLR4XraZ9k93/00check.log>

## Additional checks

* `urlchecker::url_check()` found no URL problems.
* The full local test suite passed 502 assertions, including synthetic DuckDB
  and PostgreSQL fixtures. Two live-download tests were skipped in that run;
  the release check separately ran the internet-dependent help examples.
* The Windows test suite passed 351 assertions with no failures or warnings.
  Its 30 skips cover CRAN-only download exclusions, unavailable PostgreSQL
  fixtures, and a permissions check where Windows does not enforce the fixture.
* Every exported function is covered by an example and return-value
  documentation. Credential-dependent database examples explain why they are
  wrapped in `\dontrun{}`; download examples use `\donttest{}`.
* Software names are quoted in DESCRIPTION. The book reference uses its title,
  year and DOI; the author and maintainer identities are unchanged.
* The temporary-download test normalizes both directory paths. Buffer
  restoration tests compare the state actually established by the platform,
  including Windows treating an empty environment value as unset. Success
  and both parser-failure paths remain checked.

## Reverse dependencies

There are no CRAN reverse dependencies in Depends, Imports, LinkingTo or
Suggests, verified against the current CRAN package database.

## Release changes

This update corrects event-return calculations and boosting edge cases,
refreshes the AAER dates and corrects selected public-float dates, and expands
the documentation. Details are in NEWS.md.
