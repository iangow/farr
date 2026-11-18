# Maintaining Apple event dates

Run the updater from the farr repository root:

```r
source("data-raw/get_apple_events.R")
build_apple_events()
```

Or run `Rscript data-raw/get_apple_events.R [HTML_file] [new_snapshot_directory]`.
The default source is Wikipedia. A local HTML or gzip file supports an offline
refresh. Sourcing the script only defines functions; it does not download or save.
The script requires rvest, xml2, stringr, tibble, dplyr, readr and httr2.

The updater reads article `h2`/`h3` headings, keeping the existing scope of events
since 2005. It supports the old and current MediaWiki heading layouts, single
dates, and date ranges within or across months. WWDC dates cover the full
conference, as in the previous data. Events ending after `as_of` are excluded.
This remains a Wikipedia-derived list with the explicit supplements below,
not an exhaustive catalogue of all Apple announcements.

Unknown dates, unexpected changes to corrected entries, empty results, duplicate
dates, or the loss of a previously bundled event stop the refresh before the
package data are replaced. The new RData file is saved and checked in a temporary
file beside the destination before rename. On a platform that cannot replace an
existing file with this rename, the update fails and retains the original file.

Each refresh uses a new snapshot directory containing the compressed HTML,
revision URL, retrieval time, checksum, uncorrected extracted headings, final
rows, and a comparison with the previous data. Existing snapshot directories
are never overwritten. Update the row count and coverage in `R/data.R` after
reviewing a refresh, then regenerate documentation with `roxygen2::roxygenise()`.

## November 2026 refresh

The source was [Wikipedia revision 1386303806](https://en.wikipedia.org/w/index.php?title=List_of_Apple_Inc._media_events&oldid=1386303806).
The original script selected `//*[@id="toc"]`, an element absent from the
current page. It returned zero rows and would have saved those over the data.
It also depended on numbered table-of-contents entries and did not restrict the
years, although the page now covers events before 2005.

The original 47 rows, ending on 10 November 2020, are preserved verbatim in
`apple_events_2020.csv`. The refresh has 76 rows, from 11 January 2005 through
9 September 2026. It adds 17 events in 2021–2026 and 12 omissions in 2005–2010.
All original events survive, with one corrected date. Event descriptions now
follow the current headings, so some capitalisation and wording have changed.

The raw heading dates remain in `headings.csv`. The separate
`apple_events_corrections.csv` records three reviewed corrections:

| Event | Wikipedia heading | Applied date | Evidence |
| --- | --- | --- | --- |
| Macworld 2005 | 17 January 2005 | 11 January 2005 | [Apple's Mac mini announcement](https://www.apple.com/newsroom/2005/01/11Apple-Introduces-Mac-mini/) |
| October 2005 special event | Month only | 12 October 2005 | [Apple's video iPod announcement](https://www.apple.com/newsroom/2005/10/12Apple-Unveils-the-New-iPod/) |
| Macworld 2008 | 16 January 2008 | 15 January 2008 | [Apple's MacBook Air announcement](https://www.apple.com/newsroom/2008/01/15Apple-Introduces-MacBook-Air-The-Worlds-Thinnest-Notebook/) |

The 2008 correction also changes the previously bundled data. The other two
corrections apply to newly included historical events. In the comparison file,
the date correction appears as removal of 16 January and addition of 15 January;
it does not represent a dropped event.

`apple_events_historical.csv` retains the 2 December 2019 entry from the old
package, which no longer appears on Wikipedia. [Apple's announcement](https://developer.apple.com/news/?id=12022019a)
confirms the Best of 2019 announcement date. Its original label is retained.
This supplement is used only when the date is absent from the current source.

The latest entries were also checked against Apple's [WWDC26 announcement](https://www.apple.com/newsroom/2026/03/apples-worldwide-developers-conference-returns-the-week-of-june-8/)
and [September 2026 developer newsletter](https://developer.apple.com/hello/september26/).
The refresh does not modify the book or recalculate its analyses.

## Offline validation and reproduction

```sh
Rscript data-raw/check_apple_events.R
```

This verifies the snapshot checksum and exact reconstruction of the bundled
RData, historical coverage, date corrections, WWDC ranges, both heading layouts,
future-event exclusion, source drift, returning historical entries, and
preservation of an existing output after failed or incomplete input.

To rebuild into a separate location:

```r
source("data-raw/get_apple_events.R")
build_apple_events(
  source = "data-raw/apple_events_refresh_2026-11-17/wikipedia.html.gz",
  snapshot_dir = tempfile("apple-events-snapshot-"),
  output_file = file.path(tempdir(), "apple_events.RData"),
  as_of = as.Date("2026-11-17")
)
```
