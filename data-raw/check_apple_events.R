# Offline checks for the Wikipedia updater and bundled Apple events.
# Run from the farr root: Rscript data-raw/check_apple_events.R
source("data-raw/get_apple_events.R")
library(testthat)

snapshot <- "data-raw/apple_events_refresh_2026-11-17"
corrections <- read_apple_event_corrections()
historical <- read_apple_event_history()
metadata <- read.dcf(file.path(snapshot, "source.dcf"))
candidate <- parse_apple_event_headings(xml2::read_html(file.path(snapshot, "wikipedia.html.gz")))
reconciled <- reconcile_apple_events(candidate, corrections, historical,
                                      as_of = as.Date(metadata[1, "As_of"]))
e <- new.env(); load("data/apple_events.RData", envir = e)
old <- readr::read_csv("data-raw/apple_events_2020.csv", col_types = "cDD")

expect_identical(unname(tools::md5sum(file.path(snapshot, "wikipedia.html.gz"))),
                 unname(metadata[1, "Snapshot_MD5"]))
expect_identical(reconciled, e$apple_events)
expect_equal(nrow(candidate), 75L)
expect_equal(nrow(reconciled), 76L)
expect_equal(min(reconciled$event_date), as.Date("2005-01-11"))
expect_equal(max(reconciled$end_event_date), as.Date("2026-09-09"))
expect_identical(names(reconciled), c("event", "event_date", "end_event_date"))
expect_false(anyNA(reconciled))
expect_false(anyDuplicated(reconciled$event_date) > 0L)
old$event_date[old$event_date == as.Date("2008-01-16")] <- as.Date("2008-01-15")
expect_true(all(old$event_date %in% reconciled$event_date))
expect_equal(sum(reconciled$event_date > as.Date("2020-11-10")), 17L)
expect_equal(reconciled$end_event_date[reconciled$event == "WWDC 2026"], as.Date("2026-06-12"))
expect_equal(reconciled$event_date[reconciled$event == "Macworld 2005"], as.Date("2005-01-11"))
expect_equal(sum(reconciled$event_date == as.Date("2019-12-02")), 1L)

# Wikipedia can adopt a correction without causing duplicate or changed rows.
fixed <- candidate
for (i in seq_len(nrow(corrections))) {
    at <- fixed$year == corrections$year[i] & fixed$event == corrections$event[i]
    fixed$event_date[at] <- corrections$event_date[i]
    fixed$end_event_date[at] <- corrections$end_event_date[i]
    fixed$date_text[at] <- format(corrections$event_date[i], "%B %d, %Y")
}
expect_identical(reconcile_apple_events(fixed, corrections, historical), reconciled)
drift <- candidate
drift$date_text[drift$event == "Macworld 2005"] <- "January 19, 2005"
expect_error(reconcile_apple_events(drift, corrections, historical), "Unexpected source date")
returned <- candidate[1, ]
returned$year <- 2019L
returned$event <- "Apple event"
returned$event_date <- returned$end_event_date <- as.Date("2019-12-02")
with_returned <- reconcile_apple_events(dplyr::bind_rows(candidate, returned), corrections, historical)
expect_equal(sum(with_returned$event_date == as.Date("2019-12-02")), 1L)

# Both MediaWiki heading layouts work without a table of contents.
headings <- c('<h2><span class="mw-headline">2026</span></h2>',
              '<h3><span>Event (June 30-July 2, 2026)</span><span class="mw-editsection">[edit]</span></h3>',
              '<div class="mw-heading"><h3>WWDC (June 8\u201312, 2026)</h3></div>',
              '<h3>Single (September 9, 2026, California)</h3>',
              '<h3>Future (December 1, 2026)</h3>')
synthetic <- xml2::read_html(paste0('<div class="mw-parser-output">', paste(headings, collapse = ""), '</div>'))
parsed <- parse_apple_event_headings(synthetic)
expect_equal(parsed$event, c("Event", "WWDC", "Single", "Future"))
expect_equal(parsed$end_event_date[1], as.Date("2026-07-02"))
expect_equal(parsed$end_event_date[2], as.Date("2026-06-12"))
expect_equal(nrow(reconcile_apple_events(parsed, corrections[0, ], historical[0, ],
                                        as_of = as.Date("2026-11-17"))), 3L)
expect_error(parse_apple_event_headings(xml2::read_html('<html>Site unavailable</html>')), "No Apple event")
parsed$event_date[1] <- as.Date(NA)
expect_error(reconcile_apple_events(parsed, corrections[0, ], historical[0, ]), "Unparsed")
parsed <- candidate
parsed$end_event_date[2] <- parsed$event_date[2] - 1
expect_error(reconcile_apple_events(parsed, corrections, historical), "Invalid")
expect_error(reconcile_apple_events(dplyr::bind_rows(candidate, candidate[2, ]), corrections, historical), "duplicate")

# Exercise staging and the historical-coverage guard with temporary outputs.
local({
    directory <- tempfile("apple-rebuild-")
    dir.create(directory)
    on.exit(unlink(directory, recursive = TRUE))
    output <- file.path(directory, "apple_events.RData")
    file.copy("data/apple_events.RData", output)
    build_apple_events(file.path(snapshot, "wikipedia.html.gz"),
                       file.path(directory, "snapshot"), output, as.Date("2026-11-17"))
    rebuilt <- new.env(); load(output, envir = rebuilt)
    expect_identical(rebuilt$apple_events, reconciled)
    before <- unname(tools::md5sum(output))
    bad_source <- file.path(directory, "empty.html")
    writeLines('<html>Site unavailable</html>', bad_source)
    expect_error(build_apple_events(bad_source, file.path(directory, "failed"), output), "revision")
    expect_identical(unname(tools::md5sum(output)), before)
    trimmed <- xml2::read_html(file.path(snapshot, "wikipedia.html.gz"))
    missing <- rvest::html_elements(trimmed, ".mw-parser-output h3")
    xml2::xml_remove(missing[grepl("WWDC 2025", rvest::html_text2(missing))])
    trimmed_file <- file.path(directory, "trimmed.html")
    xml2::write_html(trimmed, trimmed_file)
    expect_error(build_apple_events(trimmed_file, file.path(directory, "missing"), output), "Previously bundled")
    expect_identical(unname(tools::md5sum(output)), before)
})
message("Apple events: offline rebuild, parsing, provenance, corrections and failure checks passed")
