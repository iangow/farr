#' Download and maintain SEC quarterly filing indexes
#'
#' Download the SEC's `company.gz` indexes as Parquet files compatible with
#' `era_pl.sec`. These functions require the optional arrow package.
#'
#' @param year Integer year, from 1993 through the current SEC calendar year.
#' @param quarter Integer quarter from 1 to 4, no later than the current quarter.
#' @param overwrite Replace an existing file even if its vintage is current.
#' @param data_dir Root directory of the data repository. Must be nonempty.
#' @param schema Single directory name below `data_dir`.
#' @param user_agent SEC user agent identifying your organisation and contact.
#'   If `NULL`, use option `HTTPUserAgent`, then environment variable `USER_AGENT`.
#'   R's generic default user agent is ignored when resolving this fallback.
#'   A nonempty value is required for network requests.
#' @param last_modified Optional expected SEC vintage, as a single nonmissing
#'   `POSIXct` instant or ISO 8601 string with an explicit UTC offset (or `Z`).
#'   This avoids the initial directory request; the vintage is still checked
#'   after downloading. It is never used to relabel an existing file.
#' @param report One of `"all"`, `"update"`, or `"none"`. `"update"` reports
#'   downloads, replacements, and failures; `"all"` also reports unchanged files.
#' @param archive Preserve an existing file in `schema/archive` before replacing
#'   it? Defaults to `FALSE`. Existing archives are left untouched.
#' @param check_all Check every target quarter, including quarters older than an
#'   unchanged file? Defaults to `FALSE`, ending remote checks at the first
#'   unchanged file.
#'
#' @details
#' Files are stored at `data_dir/schema/sec_index_YYYYqQ.parquet`, with columns
#' `company_name`, `form_type`, `cik` (32-bit integer), `date_filed` (date), and
#' `file_name`. Both historical compact dates and ISO dates are supported.
#' The footer's `last_modified` key stores the SEC vintage as an ISO 8601 UTC
#' string. Directory timestamps are interpreted in `America/New_York`, including
#' daylight saving time. Ambiguous timestamps in the repeated autumn hour are
#' rejected. Comparisons use instants, never filesystem timestamps.
#'
#' `sec_parquet_last_modified(year, quarter)` reads the saved index's timestamp
#' without contacting the SEC. Like the download and update functions, it uses
#' `DATA_DIR` by default and looks in the `"edgar"` schema, with `data_dir` and
#' `schema` arguments to select another repository or directory.
#'
#' `sec_get_index(overwrite = FALSE)` reuses an existing file without contacting
#' the SEC. `sec_index_update()` downloads a missing file and replaces files
#' with missing/invalid vintage metadata or an older vintage. Equal or newer
#' local vintages are unchanged. Missing or malformed metadata is reported as
#' `NA` by `sec_parquet_last_modified()`; unreadable Parquet files raise an error.
#'
#' Downloads are staged in the destination directory, parsed, and validated
#' before replacing an active file. A changed remote vintage during download
#' produces a failed status. By default, replaced files are not archived.
#' With `archive = TRUE`, existing files are copied, byte for byte, into
#' `schema/archive` before replacement. Archive names include the old UTC vintage;
#' unknown vintages and timestamp collisions use a content checksum suffix.
#' Existing archives are never overwritten. A directory lock prevents concurrent
#' updates to the same file by these functions. A lock left after a process crash
#' must be removed manually after checking that no update is running.
#'
#' Replacement uses a same-directory rename. If the platform cannot replace an
#' existing file this way, the operation fails and retains the active file.
#' With archiving enabled, a failure may leave a verified archive, but never
#' advances the active file's metadata. Network requests use a five-per-second
#' throttle per R session,
#' with retries spaced at least one second apart and at most three attempts for connection failures, HTTP 429, and selected 5xx
#' responses. Separate R processes must coordinate their request rates.
#'
#' `sec_index_targets()` follows `era_pl.sec`: all quarters from 1993 Q1 through
#' yesterday's quarter, using the SEC's New York calendar. This is a target list,
#' not a guarantee that each historical index exists. `sec_index_local()` lists
#' only active, correctly named files, without descending into archives.
#'
#' `sec_index_update_all()` checks quarters from newest to oldest. By default it
#' ends remote checks at the first unchanged file. Older local files are included
#' in the result as `"unchanged"`, with their locally stored timestamps and no
#' further SEC requests. Missing or unreadable older files return `"failed"`
#' without resuming remote checks. Downloads, updates, and failures during the
#' remote scan do not stop it. Use `check_all = TRUE`
#' to check every target quarter, including older missing files or revisions
#' that the default scan may not reach. An empty repository is populated by
#' checking every target because no existing file can be unchanged.
#'
#' @return `sec_get_index()` and `sec_index_update()` return a one-row tibble;
#'   `sec_index_update_all()` returns one row per target quarter, newest first.
#'   Columns are
#'   `year`, `quarter`, `status` (`"unchanged"`, `"downloaded"`, `"updated"`, or
#'   `"failed"`), `path`, `last_modified` (active vintage as UTC `POSIXct`),
#'   `archive_path` (or `NA`), and `error` (or `NA`). Invalid arguments and missing
#'   configuration raise errors; download, parsing, and filesystem failures return
#'   failed rows. Batch processing continues after individual failures.
#'
#'   `sec_index_available_update()` and `sec_parquet_last_modified()` return a
#'   single UTC `POSIXct` value. `sec_index_local()` returns a tibble with `year`,
#'   `quarter`, `path`, and `last_modified`, including a typed empty tibble when
#'   no files exist. `sec_index_targets()` returns integer `year` and `quarter`
#'   columns. No function creates a database connection; use [load_parquet()]
#'   with an explicit DuckDB connection for lazy queries.
#'
#' @references <https://www.sec.gov/search-filings/edgar-search-assistance/accessing-edgar-data>
#' @examples
#' head(sec_index_targets())
#' \dontrun{
#' # Supply your own organisation/contact in USER_AGENT or HTTPUserAgent.
#' result <- sec_get_index(2022, 2)
#' result$status
#' sec_parquet_last_modified(2022, 2)
#' sec_index_local()
#' sec_index_update(2022, 2)
#' sec_index_update_all()
#' # Check the full history, including older missing or revised files:
#' sec_index_update_all(check_all = TRUE)
#' # With an existing DuckDB connection:
#' filings <- load_parquet(conn, "sec_index_2022q2", schema = "edgar")
#' }
#' @name sec_index
NULL

#' @rdname sec_index
#' @export
sec_get_index <- function(year, quarter, overwrite = FALSE,
                          data_dir = Sys.getenv("DATA_DIR"), schema = "edgar",
                          user_agent = NULL, last_modified = NULL, archive = FALSE) {
    sec_check_quarter(year, quarter)
    sec_check_archive(archive)
    if (!is.logical(overwrite) || length(overwrite) != 1L || is.na(overwrite)) {
        stop("`overwrite` must be TRUE or FALSE.", call. = FALSE)
    }
    path <- sec_index_path(year, quarter, data_dir, schema)
    sec_require_arrow()
    expected <- sec_expected_vintage(last_modified)
    if (!overwrite && file.exists(path)) {
        return(sec_reuse(year, quarter, path))
    }
    agent <- sec_user_agent(user_agent)
    sec_acquire(year, quarter, path, agent, expected, update = FALSE,
                overwrite = overwrite, archive = archive)
}

#' @rdname sec_index
#' @export
sec_index_available_update <- function(year, quarter, user_agent = NULL) {
    sec_check_quarter(year, quarter)
    agent <- sec_user_agent(user_agent)
    sec_listing_vintage(sec_request(sec_index_url(year, quarter), agent))
}

#' @rdname sec_index
#' @export
sec_parquet_last_modified <- function(year, quarter, data_dir = Sys.getenv("DATA_DIR"),
                                      schema = "edgar") {
    sec_check_quarter(year, quarter)
    path <- sec_index_path(year, quarter, data_dir, schema)
    sec_read_parquet_vintage(path)
}

#' @rdname sec_index
#' @export
sec_index_local <- function(data_dir = Sys.getenv("DATA_DIR"), schema = "edgar") {
    directory <- sec_index_directory(data_dir, schema)
    sec_require_arrow()
    paths <- list.files(directory, pattern = "^sec_index_[0-9]{4}q[1-4]\\.parquet$",
                        full.names = TRUE, recursive = FALSE)
    paths <- paths[!dir.exists(paths)]
    tibble::tibble(
        year = as.integer(substr(basename(paths), 11, 14)),
        quarter = as.integer(substr(basename(paths), 16, 16)),
        path = paths,
        last_modified = sec_time(vapply(paths, function(path) {
            as.numeric(sec_read_parquet_vintage(path))
        }, numeric(1)))
    )
}

#' @rdname sec_index
#' @export
sec_index_targets <- function() {
    yesterday <- sec_today() - 1
    end_year <- as.integer(format(yesterday, "%Y"))
    end_quarter <- (as.integer(format(yesterday, "%m")) - 1L) %/% 3L + 1L
    quarters <- seq.int(1993L * 4L, end_year * 4L + end_quarter - 1L)
    tibble::tibble(year = quarters %/% 4L, quarter = quarters %% 4L + 1L)
}

#' @rdname sec_index
#' @export
sec_index_update <- function(year, quarter, data_dir = Sys.getenv("DATA_DIR"),
                             schema = "edgar", user_agent = NULL,
                             last_modified = NULL, report = "all", archive = FALSE) {
    sec_check_quarter(year, quarter)
    sec_check_archive(archive)
    path <- sec_index_path(year, quarter, data_dir, schema)
    report <- match.arg(report, c("all", "update", "none"))
    sec_require_arrow()
    agent <- sec_user_agent(user_agent)
    expected <- sec_expected_vintage(last_modified)
    result <- sec_acquire(year, quarter, path, agent, expected, update = TRUE, archive = archive)
    sec_report(result, report)
    result
}

#' @rdname sec_index
#' @export
sec_index_update_all <- function(data_dir = Sys.getenv("DATA_DIR"),
                                 schema = "edgar", user_agent = NULL,
                                 report = "update", archive = FALSE, check_all = FALSE) {
    sec_index_directory(data_dir, schema)
    sec_check_archive(archive)
    if (!is.logical(check_all) || length(check_all) != 1L || is.na(check_all)) {
        stop("`check_all` must be TRUE or FALSE.", call. = FALSE)
    }
    sec_require_arrow()
    agent <- sec_user_agent(user_agent)
    report <- match.arg(report, c("all", "update", "none"))
    targets <- sec_index_targets()
    targets <- targets[rev(seq_len(nrow(targets))), ]
    results <- vector("list", nrow(targets))
    check_remote <- TRUE
    for (i in seq_len(nrow(targets))) {
        if (check_remote) {
            result <- sec_index_update(targets$year[i], targets$quarter[i], data_dir, schema,
                                       agent, report = report, archive = archive)
            if (!check_all && result$status == "unchanged") check_remote <- FALSE
        } else {
            path <- sec_index_path(targets$year[i], targets$quarter[i], data_dir, schema)
            result <- sec_reuse(targets$year[i], targets$quarter[i], path)
            sec_report(result, report)
        }
        results[[i]] <- result
    }
    dplyr::bind_rows(results)
}

sec_time <- function(x = NA_real_) {
    as.POSIXct(x, origin = "1970-01-01", tz = "UTC")
}

sec_today <- function() as.Date(format(Sys.time(), tz = "America/New_York", "%Y-%m-%d"))

sec_require_arrow <- function() {
    if (!requireNamespace("arrow", quietly = TRUE)) {
        stop("The arrow package is required for SEC Parquet indexes.", call. = FALSE)
    }
}

sec_read_parquet_vintage <- function(path) {
    sec_require_arrow()
    metadata <- arrow::ParquetFileReader$create(path)$GetSchema()$metadata
    sec_parse_vintage(metadata[["last_modified"]])
}

sec_check_archive <- function(archive) {
    if (!is.logical(archive) || length(archive) != 1L || is.na(archive)) {
        stop("`archive` must be TRUE or FALSE.", call. = FALSE)
    }
}

sec_check_quarter <- function(year, quarter) {
    whole <- function(x) is.numeric(x) && length(x) == 1L &&
        is.finite(x) && x == trunc(x)
    today <- sec_today()
    this_year <- as.integer(format(today, "%Y"))
    this_quarter <- (as.integer(format(today, "%m")) - 1L) %/% 3L + 1L
    if (!whole(year) || year < 1993 || year > this_year) {
        stop("`year` must be an integer from 1993 through the current SEC year.", call. = FALSE)
    }
    if (!whole(quarter) || quarter < 1 || quarter > 4 ||
        (year == this_year && quarter > this_quarter)) {
        stop("`quarter` must be 1 to 4 and no later than the current SEC quarter.", call. = FALSE)
    }
}

sec_index_directory <- function(data_dir, schema) {
    scalar_string <- function(x) is.character(x) && length(x) == 1L &&
        !is.na(x) && nzchar(trimws(x))
    if (!scalar_string(data_dir)) stop("`data_dir` must be a nonempty path.", call. = FALSE)
    if (!scalar_string(schema) || schema %in% c(".", "..") ||
        grepl("[/\\\\]", schema)) {
        stop("`schema` must be a single directory name.", call. = FALSE)
    }
    file.path(normalizePath(path.expand(data_dir), mustWork = FALSE), schema)
}

sec_index_path <- function(year, quarter, data_dir, schema) {
    file.path(sec_index_directory(data_dir, schema),
              sprintf("sec_index_%dq%d.parquet", as.integer(year), as.integer(quarter)))
}

sec_user_agent <- function(user_agent) {
    if (is.null(user_agent)) {
        user_agent <- getOption("HTTPUserAgent")
        generic <- is.character(user_agent) && length(user_agent) == 1L &&
            !is.na(user_agent) && grepl("^R \\([0-9]", user_agent)
        empty <- is.character(user_agent) && length(user_agent) == 1L &&
            !is.na(user_agent) && !nzchar(trimws(user_agent))
        if (is.null(user_agent) || generic || empty) user_agent <- Sys.getenv("USER_AGENT")
    }
    if (!is.character(user_agent) || length(user_agent) != 1L ||
        is.na(user_agent) || !nzchar(trimws(user_agent)) || grepl("[\r\n]", user_agent)) {
        stop("Supply an SEC `user_agent`, option HTTPUserAgent, or USER_AGENT with your organisation and contact.",
             call. = FALSE)
    }
    user_agent
}

sec_index_url <- function(year, quarter) {
    sprintf("https://www.sec.gov/Archives/edgar/full-index/%d/QTR%d/",
            as.integer(year), as.integer(quarter))
}

# A shared throttle realm covers all directory and download requests.
sec_request <- function(url, user_agent) {
    req <- httr2::request(url)
    req <- httr2::req_user_agent(req, user_agent)
    req <- httr2::req_timeout(req, 120)
    req <- httr2::req_throttle(req, capacity = 1, fill_time_s = 0.2,
                              realm = "farr-sec")
    req <- httr2::req_retry(req, max_tries = 3, max_seconds = 180,
                           retry_on_failure = TRUE,
                           after = function(resp) max(1, httr2::resp_retry_after(resp)),
                           is_transient = function(resp) {
                               httr2::resp_status(resp) %in% c(429, 500, 502, 503, 504)
                           })
    httr2::resp_body_raw(httr2::req_perform(req))
}

sec_parse_vintage <- function(value) {
    pattern <- paste0("^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:",
                      "[0-9]{2}(\\.[0-9]+)?(Z|[+-][0-9]{2}:[0-9]{2})$")
    if (!is.character(value) || length(value) != 1L || is.na(value) ||
        !grepl(pattern, value)) return(sec_time())
    value <- sub("Z$", "+0000", value)
    value <- sub("([+-][0-9]{2}):([0-9]{2})$", "\\1\\2", value)
    sec_time(as.numeric(suppressWarnings(strptime(value, "%Y-%m-%dT%H:%M:%OS%z", tz = "UTC"))))
}

sec_expected_vintage <- function(value) {
    if (is.null(value)) return(NULL)
    parsed <- if (inherits(value, "POSIXct")) sec_time(as.numeric(value)) else sec_parse_vintage(value)
    if (length(parsed) != 1L || is.na(parsed) || !is.finite(as.numeric(parsed))) {
        stop("`last_modified` must be a POSIXct instant or an ISO 8601 timestamp with a timezone.",
             call. = FALSE)
    }
    parsed
}

sec_listing_vintage <- function(content) {
    html <- xml2::read_html(content)
    links <- xml2::xml_find_all(html, "//tr/td/a")
    selected <- links[trimws(xml2::xml_text(links)) == "company.gz"]
    if (length(selected) != 1L) stop("SEC listing must contain one company.gz row.")
    cells <- xml2::xml_text(xml2::xml_find_all(selected, "../../td"))
    timestamp <- trimws(cells[grepl("[0-9]{2}/[0-9]{2}/[0-9]{4}", cells)])
    if (length(timestamp) != 1L) stop("SEC listing has no unambiguous company.gz timestamp.")
    # Parse AM/PM numerically so the caller's locale cannot change the result.
    pattern <- "^([0-9]{2})/([0-9]{2})/([0-9]{4}) ([0-9]{1,2}):([0-9]{2}):([0-9]{2}) (AM|PM)$"
    parts <- regmatches(timestamp, regexec(pattern, timestamp))[[1]]
    if (length(parts) != 8L) stop("Invalid SEC directory timestamp.")
    hour <- as.integer(parts[5])
    if (hour < 1L || hour > 12L) stop("Invalid SEC directory hour.")
    hour <- hour %% 12L + if (parts[8] == "PM") 12L else 0L
    stamp <- sprintf("%s-%s-%s %02d:%s:%s", parts[4], parts[2], parts[3],
                     hour, parts[6], parts[7])
    value <- as.POSIXct(strptime(stamp, "%Y-%m-%d %H:%M:%S", tz = "America/New_York"))
    if (is.na(value) || format(value, "%Y-%m-%d %H:%M:%S", tz = "America/New_York") != stamp) {
        stop("Invalid SEC directory timestamp.")
    }
    neighbours <- value + c(-3600, 3600)
    if (any(format(neighbours, "%Y-%m-%d %H:%M:%S", tz = "America/New_York") == stamp)) {
        stop("Ambiguous SEC timestamp during the daylight saving transition.")
    }
    sec_time(as.numeric(value))
}

sec_parse_company <- function(content) {
    if (!is.raw(content) || length(content) < 2L ||
        !identical(content[1:2], as.raw(c(31, 139)))) stop("Expected a gzip SEC index.")
    bytes <- withCallingHandlers(memDecompress(content, "gzip"),
                                 warning = function(w) stop(conditionMessage(w)))
    lines <- strsplit(iconv(rawToChar(bytes), from = "macintosh", to = "UTF-8"), "\n", fixed = TRUE)[[1]]
    if (length(lines) < 11L) stop("SEC index has no data rows.")
    rows <- sub("\r$", "", lines[-seq_len(10L)])
    rows <- rows[nzchar(trimws(rows))]
    if (!length(rows) || any(nchar(rows) < 104L)) stop("Invalid or empty SEC index rows.")
    field <- function(start, end) trimws(substr(rows, start, end))
    cik_text <- field(80L, 91L)
    cik <- suppressWarnings(as.integer(cik_text))
    if (any(nzchar(cik_text) & (!grepl("^[0-9]+$", cik_text) | is.na(cik)))) {
        stop("Invalid CIK in SEC index.")
    }
    dates <- field(92L, 103L)
    compact <- grepl("^[0-9]{8}$", dates)
    dates[compact] <- sub("^([0-9]{4})([0-9]{2})([0-9]{2})$", "\\1-\\2-\\3", dates[compact])
    filed <- as.Date(dates, format = "%Y-%m-%d")
    if (any(!grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2}$", dates) | is.na(filed)) ||
        any(format(filed, "%Y-%m-%d") != dates)) stop("Invalid filing date in SEC index.")
    result <- tibble::tibble(company_name = field(1L, 62L), form_type = field(63L, 79L),
                             cik = cik, date_filed = filed, file_name = field(104L, max(nchar(rows))))
    if (any(!nzchar(result$company_name) | !nzchar(result$form_type) | !nzchar(result$file_name))) {
        stop("SEC index has missing required text fields.")
    }
    result
}

sec_write_parquet <- function(data, path, vintage) {
    table <- arrow::as_arrow_table(data)
    metadata <- table$schema$metadata
    metadata$last_modified <- format(vintage, "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
    table <- table$ReplaceSchemaMetadata(metadata)
    arrow::write_parquet(table, path)
}

sec_validate_parquet <- function(path, vintage, rows) {
    table <- arrow::read_parquet(path, as_data_frame = FALSE)
    expected <- c("company_name", "form_type", "cik", "date_filed", "file_name")
    if (!identical(table$schema$names, expected) || table$num_rows != rows) {
        stop("Staged SEC index has incorrect columns or row count.")
    }
    types <- vapply(expected, function(name) table$schema$GetFieldByName(name)$type$ToString(), character(1))
    if (any(!types[c(1, 2, 5)] %in% c("string", "large_string")) ||
        types[3] != "int32" || types[4] != "date32[day]") stop("Staged SEC index has incorrect column types.")
    if (!isTRUE(sec_read_parquet_vintage(path) == vintage)) stop("Staged SEC index has incorrect vintage metadata.")
}

sec_status <- function(year, quarter, path, status, vintage = sec_time(),
                        archive = NA_character_, error = NA_character_) {
    tibble::tibble(year = as.integer(year), quarter = as.integer(quarter), status = status,
                   path = path, last_modified = vintage, archive_path = archive, error = error)
}

sec_reuse <- function(year, quarter, path) {
    tryCatch(sec_status(year, quarter, path, "unchanged", sec_read_parquet_vintage(path)),
             error = function(e) sec_status(year, quarter, path, "failed", error = conditionMessage(e)))
}

sec_checksum <- function(path) unname(tools::md5sum(path))

sec_archive <- function(path, vintage, checksum) {
    directory <- file.path(dirname(path), "archive")
    dir.create(directory, recursive = TRUE, showWarnings = FALSE)
    stem <- tools::file_path_sans_ext(basename(path))
    suffix <- if (is.na(vintage)) paste0("unknown_modified_", checksum) else
        format(vintage, "%Y%m%dT%H%M%SZ", tz = "UTC")
    archive <- file.path(directory, paste0(stem, "_", suffix, ".parquet"))
    if (file.exists(archive) && !identical(sec_checksum(archive), checksum)) {
        archive <- file.path(directory, paste0(stem, "_", suffix, "_", checksum, ".parquet"))
    }
    if (!file.exists(archive) && !file.copy(path, archive, overwrite = FALSE, copy.date = TRUE)) {
        stop("Could not archive the active SEC index.")
    }
    if (!identical(sec_checksum(archive), checksum)) stop("SEC archive checksum mismatch; no files replaced.")
    archive
}

sec_replace <- function(from, to) {
    if (!file.rename(from, to)) stop("Could not atomically replace the SEC index; active file retained.")
}

sec_acquire <- function(year, quarter, path, agent, expected, update,
                        overwrite = FALSE, archive = FALSE) {
    old_vintage <- sec_time()
    archive_path <- NA_character_
    tryCatch({
        directory <- dirname(path)
        dir.create(directory, recursive = TRUE, showWarnings = FALSE)
        lock <- paste0(path, ".lock")
        if (!dir.create(lock, showWarnings = FALSE)) stop("Cannot acquire SEC index lock: ", lock)
        on.exit(unlink(lock, recursive = TRUE), add = TRUE)
        if (dir.exists(path)) stop("SEC index destination is a directory.")
        existed <- file.exists(path)
        original <- if (existed) sec_checksum(path) else NA_character_
        if (existed) old_vintage <- sec_read_parquet_vintage(path)
        if (existed && !update && !overwrite) {
            return(sec_status(year, quarter, path, "unchanged", old_vintage))
        }
        vintage <- if (is.null(expected)) sec_index_available_update(year, quarter, agent) else expected
        if (update && existed && !is.na(old_vintage) && old_vintage >= vintage) {
            return(sec_status(year, quarter, path, "unchanged", old_vintage))
        }
        data <- sec_parse_company(sec_request(paste0(sec_index_url(year, quarter), "company.gz"), agent))
        after <- sec_index_available_update(year, quarter, agent)
        if (!isTRUE(after == vintage)) stop("SEC vintage changed during download; retry the update.")
        staged <- tempfile(".sec-index-", tmpdir = directory, fileext = ".parquet")
        on.exit(unlink(staged), add = TRUE)
        sec_write_parquet(data, staged, vintage)
        sec_validate_parquet(staged, vintage, nrow(data))
        if (file.exists(path) != existed || (existed && !identical(sec_checksum(path), original))) {
            stop("Active SEC index changed during download; no replacement made.")
        }
        if (existed && archive) archive_path <- sec_archive(path, old_vintage, original)
        sec_replace(staged, path)
        sec_status(year, quarter, path, if (existed) "updated" else "downloaded", vintage, archive_path)
    }, error = function(e) {
        active_vintage <- tryCatch({
            if (file.exists(path) && !dir.exists(path)) sec_read_parquet_vintage(path) else sec_time()
        }, error = function(e) sec_time())
        sec_status(year, quarter, path, "failed", active_vintage, archive_path, conditionMessage(e))
    })
}

sec_report <- function(result, report) {
    if (report == "all" || (report == "update" && result$status != "unchanged")) {
        message(sprintf("%dq%d: %s%s", result$year, result$quarter, result$status,
                        if (is.na(result$error)) "" else paste0(" (", result$error, ")")))
    }
}
