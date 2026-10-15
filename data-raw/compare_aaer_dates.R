# Compare a separate SEC scrape with the preserved 2021 data, retaining every row.
# Run after refresh_aaer_dates.R, from the repository root:
#   Rscript data-raw/compare_aaer_dates.R output_directory [bao_source_directory]
# The optional directory contains AAER_firm_year.csv and
# data_FraudDetection_JAR2020.csv from JarFraud/FraudDetection.

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(stringr)
})

compare_aaer_dates <- function(output_dir, bao_dir = NULL) {
  env <- new.env()
  load("data/aaer_firm_year.rda", envir = env)
  old <- readRDS("data-raw/aaer_dates_2021.rds")
  new <- readRDS(file.path(output_dir, "aaer_dates_candidate.rds"))
  numbered <- read_csv(file.path(output_dir, "numbered_rows.csv"),
                       show_col_types = FALSE)
  index <- read_csv(file.path(output_dir, "index_rows.csv"),
                    show_col_types = FALSE)
  write_result <- function(x, name) write_csv(x, file.path(output_dir, name))
  keys <- c("aaer_num", "aaer_date")
  old_keys <- distinct(old, across(all_of(keys)))
  new_keys <- distinct(new, across(all_of(keys)))
  old_numbers <- distinct(old, aaer_num)
  new_numbers <- distinct(new, aaer_num)
  bao_numbers <- env$aaer_firm_year |>
    distinct(p_aaer) |>
    transmute(aaer_num = paste0("AAER-", p_aaer))

  by_year <- full_join(count(old, year, name = "bundled_rows"),
                       count(new, year, name = "candidate_rows"), by = "year") |>
    full_join(count(index, year, name = "index_rows"), by = "year") |>
    mutate(bundled_rows = coalesce(bundled_rows, 0L),
           difference = candidate_rows - bundled_rows) |>
    arrange(year)
  write_result(by_year, "comparison_by_year.csv")
  removed <- anti_join(old, new_keys, by = keys)
  added <- anti_join(numbered, old_keys, by = keys)
  write_result(removed, "old_number_date_pairs_missing.csv")
  write_result(added, "new_number_date_pairs.csv")
  write_result(anti_join(old, new_numbers, by = "aaer_num"),
               "old_numbers_missing.csv")
  write_result(anti_join(numbered, old_numbers, by = "aaer_num"),
               "new_numbers.csv")
  write_result(old[duplicated(old) | duplicated(old, fromLast = TRUE), ],
               "old_exact_duplicates.csv")
  write_result(new[duplicated(new) | duplicated(new, fromLast = TRUE), ],
               "new_exact_duplicates.csv")

  repeated_numbers <- function(df) count(df, aaer_num) |> filter(n > 1L)
  write_result(semi_join(old, repeated_numbers(old), by = "aaer_num"),
               "old_repeated_numbers.csv")
  write_result(semi_join(numbered, repeated_numbers(new), by = "aaer_num"),
               "new_repeated_numbers.csv")

  # Compare date sets, avoiding many-to-many joins for repeated AAER numbers.
  collapse_dates <- function(df) df |>
    group_by(aaer_num) |>
    summarise(dates = paste(sort(unique(aaer_date), na.last = TRUE), collapse = "; "),
              .groups = "drop")
  date_changes <- inner_join(collapse_dates(old), collapse_dates(new),
                             by = "aaer_num", suffix = c("_old", "_new")) |>
    filter(dates_old != dates_new) |>
    mutate(in_bao = aaer_num %in% bao_numbers$aaer_num)
  write_result(date_changes, "changed_date_sets.csv")

  # Retain descriptions verbatim. Layout normalization is only a diagnostic.
  # Respondent names and release labels changed substantially in the SEC migration.
  normalize_description <- function(x) x |>
    str_replace_all("(?i)AAER-\\d+[A-Za-z]?", "") |>
    str_replace_all(paste0("(?i)\\b(?:(?:other\\s+)?release\\s+nos?\\.?|",
                            "other\\s+nos?\\.?)\\s*:?"), " ") |>
    str_replace_all("[^[:alnum:]]+", " ") |>
    str_squish() |>
    str_to_lower()
  new_descriptions <- new |>
    mutate(normalized = normalize_description(aaer_desc)) |>
    distinct(aaer_num, aaer_date, normalized)
  description_changes <- old |>
    mutate(normalized = normalize_description(aaer_desc)) |>
    semi_join(new_keys, by = keys) |>
    anti_join(new_descriptions, by = c(keys, "normalized"))
  write_result(description_changes, "old_descriptions_without_normalized_match.csv")

  bao_old <- semi_join(old_keys, bao_numbers, by = "aaer_num")
  bao_new <- semi_join(new_keys, bao_numbers, by = "aaer_num")
  bao_removed <- anti_join(bao_old, bao_new, by = keys)
  bao_added <- anti_join(bao_new, bao_old, by = keys)
  write_result(bind_rows(mutate(bao_removed, change = "removed"),
                         mutate(bao_added, change = "added")),
               "bao_date_pair_changes.csv")

  # The book uses any(aaer_date <= test_date); its labels are therefore governed
  # by the earliest matched release for each firm-year.
  earliest <- function(df) env$aaer_firm_year |>
    mutate(aaer_num = paste0("AAER-", p_aaer)) |>
    left_join(df, by = "aaer_num", relationship = "many-to-many") |>
    tidyr::uncount(max_year - min_year + 1L, .id = "offset") |>
    mutate(fyear = min_year + offset - 1L) |>
    group_by(gvkey, fyear) |>
    summarise(first_aaer = if (all(is.na(aaer_date))) as.Date(NA) else
      min(aaer_date, na.rm = TRUE), .groups = "drop")
  labels <- inner_join(earliest(old_keys), earliest(new_keys),
                        by = c("gvkey", "fyear"), suffix = c("_old", "_new")) |>
    filter(is.na(first_aaer_old) != is.na(first_aaer_new) |
             (!is.na(first_aaer_old) & !is.na(first_aaer_new) &
                first_aaer_old != first_aaer_new))
  write_result(labels, "bao_firm_year_first_date_changes.csv")

  if (!is.null(bao_dir)) {
    raw <- read_csv(file.path(bao_dir, "AAER_firm_year.csv"),
                    show_col_types = FALSE)
    final <- read_csv(file.path(bao_dir, "data_FraudDetection_JAR2020.csv"),
                      show_col_types = FALSE)
    nums <- str_remove(repeated_numbers(old)$aaer_num, "^AAER-")
    presence <- tibble(
      p_aaer = nums,
      author_raw_rows = vapply(nums, function(n) sum(raw$P_AAER == n, na.rm = TRUE), 0L),
      author_final_rows = vapply(nums, function(n) sum(final$p_aaer == n, na.rm = TRUE), 0L),
      bundled_mappings = vapply(nums, function(n)
        sum(env$aaer_firm_year$p_aaer == n), 0L)
    )
    original_path <- file.path(bao_dir, "uscecchini28.csv")
    if (file.exists(original_path)) {
      original <- read_csv(original_path, show_col_types = FALSE)
      presence$author_pre_erratum_rows <- vapply(nums, function(n)
        sum(original$p_aaer == n, na.rm = TRUE), 0L)
      label_keys <- c("gvkey", "fyear", "p_aaer", "misstate")
      stopifnot(setequal(select(original, all_of(label_keys)),
                         select(final, all_of(label_keys))))
    }
    write_result(presence, "bao_repeated_number_presence.csv")
    derived <- final |>
      filter(!is.na(p_aaer)) |>
      mutate(p_aaer = as.character(p_aaer),
             gvkey = str_pad(gvkey, 6, pad = "0"), fyear = as.integer(fyear)) |>
      group_by(p_aaer, gvkey) |>
      summarise(min_year = min(fyear), max_year = max(fyear), .groups = "drop")
    stopifnot(setequal(derived, env$aaer_firm_year))
  }

  metrics <- tibble(
    measure = c("bundled_rows", "candidate_rows", "index_rows",
                "candidate_1999_2021", "candidate_2022_onward",
                "candidate_through_old_last_date", "bundled_exact_duplicate_excess",
                "candidate_exact_duplicate_excess", "old_number_date_pairs_retained",
                "old_number_date_pairs_removed", "new_number_date_pairs_added",
                "old_numbers_missing", "changed_date_sets",
                "bao_date_pairs_removed", "bao_date_pairs_added",
                "bao_firm_year_first_date_changes"),
    value = c(nrow(old), nrow(new), nrow(index), sum(new$year <= 2021),
              sum(new$year >= 2022),
              sum(new$aaer_date <= max(old$aaer_date, na.rm = TRUE)),
              sum(duplicated(old)), sum(duplicated(new)),
              nrow(semi_join(old_keys, new_keys, by = keys)),
              nrow(anti_join(old_keys, new_keys, by = keys)),
              nrow(anti_join(new_keys, old_keys, by = keys)),
              nrow(anti_join(old_numbers, new_numbers, by = "aaer_num")),
              nrow(date_changes), nrow(bao_removed), nrow(bao_added), nrow(labels))
  )
  write_result(metrics, "summary.csv")
  print(metrics, n = Inf)
  print(by_year, n = Inf)
  invisible(metrics)
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if (!length(args)) stop("Supply the scrape output directory")
  compare_aaer_dates(args[[1]], if (length(args) > 1L) args[[2]] else NULL)
}
