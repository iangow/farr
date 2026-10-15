# Reconcile a saved SEC scrape, then rebuild the bundled data.
# Run from the farr root; see aaer_dates.md for the scrape and Python sync steps.
#   Rscript data-raw/get_aaer_dates.R [snapshot_directory]
# This step is offline: raw scraped data and source corrections remain separate.

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
})

reconcile_aaer_dates <- function(candidate, historical, corrections) {
  columns <- c("aaer_num", "aaer_date", "aaer_desc", "year")
  stopifnot(identical(names(candidate), columns),
            identical(names(historical), columns),
            !anyDuplicated(corrections$aaer_num),
            all(corrections$action %in% c("date", "restore")),
            !anyNA(corrections[c("action", "aaer_num", "aaer_date", "year",
                                  "source_url", "reason")]),
            all(as.integer(format(corrections$aaer_date, "%Y")) == corrections$year))

  # The new index is not a complete historical archive. Retain the frozen
  # historical supplements only while their identifiers are absent from it.
  out <- bind_rows(candidate, anti_join(historical, candidate, by = "aaer_num"))
  for (i in seq_len(nrow(corrections))) {
    fix <- corrections[i, ]
    matches <- which(out$aaer_num == fix$aaer_num)
    if (fix$action == "restore" && !length(matches)) {
      if (is.na(fix$aaer_desc)) stop("Missing restoration description: ", fix$aaer_num)
      out <- bind_rows(out, select(fix, all_of(columns)))
    } else {
      # Accept the documented index date or an upstream correction to the
      # verified date. An unexpected new date needs a new source assessment.
      allowed <- if (fix$action == "date") c(fix$index_date, fix$aaer_date) else
        fix$aaer_date
      if (!length(matches) || anyNA(out$aaer_date[matches]) ||
          any(!out$aaer_date[matches] %in% allowed)) {
        stop("Unexpected source observation for ", fix$aaer_num)
      }
      out$aaer_date[matches] <- fix$aaer_date
      out$year[matches] <- fix$year
    }
  }

  # Distinct source entries can share an AAER number. Remove only full-row
  # duplicates (AAER-3448 in the October 2026 scrape), never number-only matches.
  out <- distinct(out) |>
    arrange(year, desc(aaer_date), aaer_num, aaer_desc)
  stopifnot(!anyDuplicated(out), inherits(out$aaer_date, "Date"),
            is.integer(out$year),
            all(as.integer(format(out$aaer_date, "%Y")) == out$year, na.rm = TRUE))
  out
}

build_aaer_dates <- function(snapshot_dir,
                             output_file = "data/aaer_dates.RData") {
  candidate <- readRDS(file.path(snapshot_dir, "aaer_dates_candidate.rds"))
  historical <- read_csv("data-raw/aaer_dates_historical.csv", col_types = "cDci")
  corrections <- read_csv("data-raw/aaer_dates_corrections.csv",
                           col_types = "ccDDcicc")
  aaer_dates <- reconcile_aaer_dates(candidate, historical, corrections)
  save(aaer_dates, file = output_file, compress = "xz", version = 3)
  message("Saved ", nrow(aaer_dates), " reconciled AAER rows to ", output_file)
  invisible(aaer_dates)
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  snapshot_dir <- if (length(args)) args[[1]] else
    "data-raw/aaer_dates_refresh_2026-10-15"
  build_aaer_dates(snapshot_dir)
}
