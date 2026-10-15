# Offline integration checks for the maintained AAER data steps.
# Run from the repository root: Rscript data-raw/check_aaer_dates.R
source("data-raw/get_aaer_dates.R")

candidate <- readRDS("data-raw/aaer_dates_refresh_2026-10-15/aaer_dates_candidate.rds")
historical <- read_csv("data-raw/aaer_dates_historical.csv", col_types = "cDci")
corrections <- read_csv("data-raw/aaer_dates_corrections.csv", col_types = "ccDDcicc")
reconciled <- reconcile_aaer_dates(candidate, historical, corrections)
env <- new.env()
load("data/aaer_dates.RData", envir = env)
stopifnot(identical(reconciled, env$aaer_dates))

# Applying corrections twice, or encountering an upstream fix, is harmless.
stopifnot(identical(reconcile_aaer_dates(reconciled, historical, corrections),
                    reconciled))
upstream_fixed <- candidate
upstream_fixed$aaer_date[upstream_fixed$aaer_num == "AAER-1209"] <- as.Date("1999-11-16")
stopifnot(identical(reconcile_aaer_dates(upstream_fixed, historical, corrections),
                    reconciled))

# Unexpected source changes must fail instead of silently acquiring our date.
unexpected <- candidate
unexpected$aaer_date[unexpected$aaer_num == "AAER-1209"] <- as.Date("1999-11-18")
failure <- tryCatch(reconcile_aaer_dates(unexpected, historical, corrections),
                    error = identity)
stopifnot(inherits(failure, "error"),
          grepl("Unexpected source observation for AAER-1209", conditionMessage(failure)))

# A historical entry that reappears in the index should not be appended again.
returned <- filter(historical, aaer_num == "AAER-1271")
returned$aaer_desc <- "A refreshed source description"
with_returned <- reconcile_aaer_dates(bind_rows(candidate, returned), historical, corrections)
stopifnot(sum(with_returned$aaer_num == "AAER-1271") == 1L,
          with_returned$aaer_desc[with_returned$aaer_num == "AAER-1271"] == returned$aaer_desc)

# All old identifiers survive, allowing the verified x2218 -> 2218 correction.
old <- readRDS("data-raw/aaer_dates_2021.rds")
old$aaer_num[old$aaer_num == "AAER-x2218"] <- "AAER-2218"
stopifnot(all(old$aaer_num %in% reconciled$aaer_num),
          nrow(candidate) == 3361L, sum(duplicated(candidate)) == 1L)
message("AAER rebuild, idempotence, upstream corrections, drift detection and historical coverage passed")
