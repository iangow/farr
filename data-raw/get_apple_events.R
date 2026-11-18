# Refresh the Apple media-event data from Wikipedia's article headings.
# Run from the farr root: Rscript data-raw/get_apple_events.R [HTML_file] [snapshot_dir]
# Sourcing this file defines functions only. See apple_events.md for provenance.

apple_events_url <- "https://en.wikipedia.org/wiki/List_of_Apple_Inc._media_events"

parse_apple_event_headings <- function(doc, first_year = 2005L) {
    nodes <- rvest::html_elements(doc, ".mw-parser-output h2, .mw-parser-output h3")
    xml2::xml_remove(rvest::html_elements(nodes, ".mw-editsection, .reference"))
    text <- trimws(gsub("\\s+", " ", rvest::html_text2(nodes)))
    kind <- xml2::xml_name(nodes)
    year <- NA_integer_
    rows <- list()
    for (i in seq_along(nodes)) {
        if (kind[i] == "h2") {
            year <- if (grepl("^[0-9]{4}$", text[i])) as.integer(text[i]) else NA_integer_
        } else if (!is.na(year) && year >= first_year) {
            parts <- stringr::str_match(text[i], "^(.*?)\\s*\\(([^()]*)\\)$")
            rows[[length(rows) + 1L]] <- tibble::tibble(
                year = year, heading = text[i],
                event = if (is.na(parts[1, 2])) text[i] else trimws(parts[1, 2]),
                date_text = parts[1, 3]
            )
        }
    }
    if (!length(rows)) stop("No Apple event headings found; refusing an empty refresh.")
    out <- dplyr::bind_rows(rows)
    months <- paste(month.name, collapse = "|")
    pattern <- paste0("\\b(", months, ") ([0-9]{1,2})",
                       "(?:\\s*[-\u2013\u2014]\\s*(?:(", months, ") )?([0-9]{1,2}))?",
                       ",? ([0-9]{4})\\b")
    dates <- stringr::str_match(out$date_text, pattern)
    month <- match(dates[, 2], month.name)
    end_month <- ifelse(is.na(dates[, 4]), month, match(dates[, 4], month.name))
    end_day <- ifelse(is.na(dates[, 5]), dates[, 3], dates[, 5])
    make_date <- function(year, month, day) {
        as.Date(sprintf("%s-%02d-%02d", year, month, as.integer(day)), format = "%Y-%m-%d")
    }
    out$event_date <- make_date(dates[, 6], month, dates[, 3])
    out$end_event_date <- make_date(dates[, 6], end_month, end_day)
    out
}

reconcile_apple_events <- function(candidate, corrections, historical,
                                    as_of = Sys.Date()) {
    for (i in seq_len(nrow(corrections))) {
        fix <- corrections[i, ]
        matches <- which(candidate$year == fix$year & candidate$event == fix$event)
        if (length(matches) != 1L) stop("Expected one heading for correction: ", fix$event)
        j <- matches[1]
        already_fixed <- isTRUE(candidate$event_date[j] == fix$event_date &&
                                    candidate$end_event_date[j] == fix$end_event_date)
        if (!already_fixed && !identical(candidate$date_text[j], fix$expected_date_text)) {
            stop("Unexpected source date for ", fix$event, "; review the correction.")
        }
        candidate$event_date[j] <- fix$event_date
        candidate$end_event_date[j] <- fix$end_event_date
    }
    if (anyNA(candidate[c("event", "event_date", "end_event_date")])) {
        bad <- candidate$heading[is.na(candidate$event_date) | is.na(candidate$end_event_date)]
        stop("Unparsed Apple event dates; review before saving: ", paste(bad, collapse = "; "))
    }
    if (any(as.integer(format(candidate$event_date, "%Y")) != candidate$year) ||
        any(as.integer(format(candidate$end_event_date, "%Y")) != candidate$year)) {
        stop("Apple event date does not agree with its year heading.")
    }
    columns <- c("event", "event_date", "end_event_date")
    out <- candidate[, columns]
    # Retain explicitly reviewed historical events only while absent upstream.
    for (i in seq_len(nrow(historical))) {
        old <- historical[i, columns]
        same_date <- out$event_date == old$event_date
        if (!any(same_date)) out <- dplyr::bind_rows(out, old)
        else if (any(out$end_event_date[same_date] != old$end_event_date)) {
            stop("Historical event duration changed; review before saving.")
        }
    }
    if (!nrow(out) || anyNA(out) || any(!nzchar(trimws(out$event))) ||
        any(out$event_date > out$end_event_date) || anyDuplicated(out$event_date)) {
        stop("Invalid or duplicate Apple events; refusing to save.")
    }
    out <- out[out$end_event_date <= as_of, ]
    out <- out[order(out$event_date), ]
    if (!nrow(out)) stop("No completed Apple events; refusing to save.")
    tibble::as_tibble(out)
}

read_apple_event_corrections <- function() {
    readr::read_csv("data-raw/apple_events_corrections.csv", col_types = "iccDDcc")
}

read_apple_event_history <- function() {
    readr::read_csv("data-raw/apple_events_historical.csv", col_types = "cDDcc")
}

compare_apple_events <- function(old, new) {
    # Dates identify events. Case-only title changes are reported separately.
    changes <- dplyr::full_join(old, new, by = "event_date", suffix = c("_old", "_new"))
    changes$change <- ifelse(is.na(changes$event_old), "added",
                            ifelse(is.na(changes$event_new), "removed", "unchanged"))
    both <- !is.na(changes$event_old) & !is.na(changes$event_new)
    different <- both & (changes$event_old != changes$event_new |
                            changes$end_event_date_old != changes$end_event_date_new)
    changes$change[different] <- "revised"
    changes[order(changes$event_date), ]
}

build_apple_events <- function(source = apple_events_url,
                               snapshot_dir = file.path("data-raw", paste0("apple_events_refresh_", Sys.Date())),
                               output_file = "data/apple_events.RData", as_of = Sys.Date()) {
    if (dir.exists(snapshot_dir)) stop("Snapshot directory already exists; choose a new directory.")
    if (grepl("^https?://", source)) {
        req <- httr2::request(source)
        req <- httr2::req_user_agent(req, "farr data refresh (https://github.com/iangow/farr)")
        req <- httr2::req_timeout(req, 60)
        content <- httr2::resp_body_raw(httr2::req_perform(req))
    } else {
        con <- gzfile(source, "rb")
        content <- tryCatch(readBin(con, "raw", n = 20 * 1024^2), finally = close(con))
    }
    doc <- xml2::read_html(content)
    permanent <- rvest::html_attr(rvest::html_element(doc, "#t-permalink a"), "href")
    if (is.na(permanent) || !grepl("oldid=[0-9]+", permanent)) {
        stop("Wikipedia revision identifier missing; refusing an untraceable refresh.")
    }
    revision <- sub(".*oldid=([0-9]+).*", "\\1", permanent)
    candidate <- parse_apple_event_headings(doc)
    corrections <- read_apple_event_corrections()
    historical <- read_apple_event_history()
    apple_events <- reconcile_apple_events(candidate, corrections, historical, as_of)

    # Every previously bundled event must survive, allowing reviewed date fixes.
    if (file.exists(output_file)) {
        old <- new.env(parent = emptyenv())
        load(output_file, envir = old)
        previous <- old$apple_events
        corrected_dates <- previous$event_date
        for (i in seq_len(nrow(corrections))) {
            key <- trimws(tolower(previous$event)) == tolower(corrections$event[i]) &
                as.integer(format(previous$event_date, "%Y")) == corrections$year[i]
            corrected_dates[key] <- corrections$event_date[i]
        }
        if (!all(corrected_dates %in% apple_events$event_date)) {
            stop("Previously bundled events are missing; review before saving.")
        }
    } else previous <- apple_events[0, ]

    dir.create(snapshot_dir, recursive = TRUE)
    snapshot <- file.path(snapshot_dir, "wikipedia.html.gz")
    con <- gzfile(snapshot, "wb")
    tryCatch(writeBin(content, con), finally = close(con))
    readr::write_csv(candidate, file.path(snapshot_dir, "headings.csv"))
    readr::write_csv(apple_events, file.path(snapshot_dir, "apple_events.csv"))
    readr::write_csv(compare_apple_events(previous, apple_events), file.path(snapshot_dir, "changes.csv"))
    metadata <- data.frame(
        Source = apple_events_url,
        Revision = revision,
        Permanent = paste0("https://en.wikipedia.org/w/index.php?title=List_of_Apple_Inc._media_events&oldid=", revision),
        Retrieved_UTC = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
        As_of = as.character(as_of),
        Snapshot_MD5 = unname(tools::md5sum(snapshot)),
        Source_headings = nrow(candidate), Output_rows = nrow(apple_events)
    )
    write.dcf(metadata, file.path(snapshot_dir, "source.dcf"))
    staged <- tempfile(".apple-events-", tmpdir = dirname(output_file))
    on.exit(unlink(staged), add = TRUE)
    save(apple_events, file = staged, compress = "xz", version = 3)
    check <- new.env(parent = emptyenv())
    load(staged, envir = check)
    if (!identical(check$apple_events, apple_events)) stop("Saved data failed validation.")
    if (!file.rename(staged, output_file)) stop("Could not replace data; original file retained.")
    message("Saved ", nrow(apple_events), " events through ", max(apple_events$end_event_date),
            "; source revision ", revision, ".")
    invisible(apple_events)
}

if (sys.nframe() == 0L) {
    args <- commandArgs(trailingOnly = TRUE)
    source <- if (length(args)) args[1] else apple_events_url
    snapshot <- if (length(args) > 1L) args[2] else
        file.path("data-raw", paste0("apple_events_refresh_", Sys.Date()))
    build_apple_events(source, snapshot)
}
