# Scrape the current SEC index without replacing the bundled aaer_dates data.
# Run from the repository root:
#   Rscript data-raw/refresh_aaer_dates.R [output_directory]
# HTML is cached in output_directory/html so interrupted runs can be resumed.
# Use a new output directory for a fresh snapshot.

suppressPackageStartupMessages({
  library(dplyr)
  library(rvest)
  library(stringr)
  library(readr)
})

scrape_aaer_index <- function(output_dir,
                             years = 1999:as.integer(format(Sys.Date(), "%Y"))) {
  base_url <- paste0("https://www.sec.gov/enforcement-litigation/",
                     "accounting-auditing-enforcement-releases")
  cache_dir <- file.path(output_dir, "html")
  dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)
  writeLines("html/", file.path(output_dir, ".gitignore"))
  user_agent <- Sys.getenv("SEC_USER_AGENT", "Ian Gow iandgow@gmail.com")
  rows <- list()
  pages <- list()

  for (yr in years) {
    page <- 0L
    observed <- 0L
    expected <- NA_integer_
    repeat {
      url <- paste0(base_url, "?aId=edit-year&year=", yr,
                    "&month=All&page=", page)
      path <- file.path(cache_dir, sprintf("%d-%02d.html", yr, page))
      if (!file.exists(path)) {
        Sys.sleep(0.2)
        partial <- paste0(path, ".partial")
        status <- system2("curl", c("-L", "--fail", "--silent", "--show-error",
                                   "--max-time", "60", "--retry", "2",
                                   "-A", shQuote(user_agent), shQuote(url),
                                   "-o", shQuote(partial)))
        if (status != 0L) stop("Download failed: ", url)
        if (!file.rename(partial, path)) stop("Cannot save ", path)
      }
      html <- read_html(path)
      footer <- html_element(html, ".view-footer") |> html_text2()
      bounds <- str_match(footer, "([0-9,]+) to ([0-9,]+) of ([0-9,]+) items")
      bounds <- as.integer(str_remove_all(bounds[1, 2:4], ","))
      nodes <- html_elements(html, "tr.pr-list-page-row")
      if (anyNA(bounds) || length(nodes) == 0L ||
          bounds[1] != observed + 1L ||
          bounds[2] - bounds[1] + 1L != length(nodes)) {
        stop("Unexpected page layout or pagination: ", url)
      }
      if (is.na(expected)) expected <- bounds[3]
      if (bounds[3] != expected) stop("Index total changed during scrape: ", url)
      time_nodes <- html_elements(nodes, "time")
      date_text <- html_text2(time_nodes)
      # Parse the displayed English date explicitly. Automatic date guessing can
      # misread "Sept. 11, 2002" as November 20, 2002. Cross-check the HTML date.
      parts <- str_match(str_squish(date_text),
                         "^([A-Za-z]+)\\.?\\s+(\\d{1,2}),\\s+(\\d{4})$")
      months <- match(substr(parts[, 2], 1, 3), month.abb)
      dates <- as.Date(sprintf("%s-%02d-%02d", parts[, 4], months,
                               as.integer(parts[, 3])))
      datetime <- html_attr(time_nodes, "datetime")
      timestamps <- as.POSIXct(datetime, format = "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
      html_dates <- as.Date(timestamps, tz = "America/New_York")
      if (length(dates) != length(nodes) || anyNA(dates) || anyNA(html_dates) ||
          any(dates != html_dates) || any(format(dates, "%Y") != yr)) {
        stop("Invalid or conflicting dates: ", url)
      }
      respondents <- html_element(nodes, ".release-view__respondents") |>
        html_text2()
      releases <- html_element(nodes, paste0(".view-table_subfield_release_number ",
                                             ".view-table_subfield_value")) |>
        html_text2()
      links <- html_element(nodes, ".release-view__respondents a") |>
        html_attr("href")
      if (anyNA(respondents) || anyNA(links)) stop("Missing respondents: ", url)
      idx <- length(rows) + 1L
      rows[[idx]] <- tibble(
        year = as.integer(yr), page = page,
        row_in_year = observed + seq_along(nodes),
        aaer_date = dates, date_text = date_text, index_datetime = datetime,
        respondents = respondents, release_numbers = releases,
        release_url = xml2::url_absolute(links, base_url), index_url = url
      )
      pages[[idx]] <- tibble(
        year = as.integer(yr), page = page, index_url = url,
        index_rows = length(nodes), index_total = expected,
        first_row = bounds[1], last_row = bounds[2],
        cached_file = file.path("html", basename(path)),
        file_md5 = unname(tools::md5sum(path)),
        downloaded_utc = format(file.info(path)$mtime, tz = "UTC", usetz = TRUE)
      )
      observed <- observed + length(nodes)
      message(yr, " page ", page, ": ", observed, "/", expected)
      if (observed == expected) break
      if (observed > expected) stop("Too many rows: ", url)
      page <- page + 1L
    }
  }

  index <- bind_rows(rows)
  index$aaer_numbers <- str_extract_all(index$release_numbers,
                                       "\\bAAER-\\d+[A-Za-z]?\\b")
  # A release field can repeat the same AAER identifier. Emit one association
  # per number per index row; preserve distinct index rows, even if identical.
  index$aaer_numbers <- lapply(index$aaer_numbers, unique)
  unnumbered <- filter(index, lengths(aaer_numbers) == 0L) |>
    select(-aaer_numbers)
  numbered <- index |>
    tidyr::unnest_longer(aaer_numbers, values_to = "aaer_num")
  candidate <- numbered |>
    transmute(aaer_num, aaer_date,
              aaer_desc = paste0(respondents, "\nRelease No. ", release_numbers),
              year)
  write_csv(select(index, -aaer_numbers), file.path(output_dir, "index_rows.csv"))
  write_csv(bind_rows(pages), file.path(output_dir, "pages.csv"))
  write_csv(unnumbered, file.path(output_dir, "unnumbered_rows.csv"))
  write_csv(numbered, file.path(output_dir, "numbered_rows.csv"))
  write_csv(candidate, file.path(output_dir, "aaer_dates_candidate.csv"))
  saveRDS(candidate, file.path(output_dir, "aaer_dates_candidate.rds"), compress = "xz")
  invisible(candidate)
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  output_dir <- if (length(args)) args[[1]] else
    file.path("data-raw", paste0("aaer_dates_refresh_", Sys.Date()))
  scrape_aaer_index(output_dir)
}
