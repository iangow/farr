sec_fixture <- function(company = "CAFÉ INC", date = "2022-04-01", cik = "1234567",
                         form = "SC 13G/A", filename = "edgar/data/1234567/filing.txt") {
    pad <- function(x, width) paste0(x, strrep(" ", width - nchar(x)))
    row <- paste0(pad(company, 62), pad(form, 17), pad(cik, 12), pad(date, 12), filename)
    lines <- c(rep("SEC fixture header", 10), row, "", "   ")
    path <- tempfile(fileext = ".gz")
    on.exit(unlink(path))
    con <- gzfile(path, "wb")
    writeBin(charToRaw(iconv(paste0(paste(lines, collapse = "\n"), "\n"),
                            to = "macintosh")), con)
    close(con)
    readBin(path, "raw", n = file.info(path)$size)
}

sec_listing <- function(stamp = "04/02/2022 10:15:30 PM") {
    charToRaw(paste0('<html><table><tr><th>Name</th><th>Size</th><th>Last Modified</th></tr>',
                    '<tr><td><a href="company.gz">company.gz</a></td><td>999</td><td>',
                    stamp, '</td></tr></table></html>'))
}

sec_test_dir <- function(env = parent.frame()) {
    path <- tempfile("sec-test-")
    dir.create(path)
    withr::defer(unlink(path, recursive = TRUE), envir = env)
    path
}

sec_mock_http <- function(content = sec_fixture(), stamp = "04/02/2022 10:15:30 PM",
                           env = parent.frame()) {
    testthat::local_mocked_bindings(sec_request = function(url, user_agent) {
        if (endsWith(url, "company.gz")) content else sec_listing(stamp)
    }, .env = env, .package = "farr")
}

sec_seed <- function(directory, vintage = "2022-04-03T02:15:30Z", company = "OLD CO") {
    dir.create(file.path(directory, "edgar"), showWarnings = FALSE)
    path <- file.path(directory, "edgar", "sec_index_2022q2.parquet")
    table <- arrow::as_arrow_table(sec_parse_company(sec_fixture(company)))
    metadata <- table$schema$metadata
    if (!is.null(vintage)) metadata$last_modified <- vintage
    table <- table$ReplaceSchemaMetadata(metadata)
    arrow::write_parquet(table, path)
    path
}

test_that("fixed-width parsing matches the Python contract", {
    parsed <- sec_parse_company(sec_fixture())
    expect_identical(names(parsed), c("company_name", "form_type", "cik", "date_filed", "file_name"))
    expect_identical(parsed$company_name, "CAFÉ INC")
    expect_identical(parsed$form_type, "SC 13G/A")
    expect_identical(parsed$cik, 1234567L)
    expect_identical(parsed$date_filed, as.Date("2022-04-01"))
    expect_identical(parsed$file_name, "edgar/data/1234567/filing.txt")
    old <- sec_parse_company(sec_fixture(date = "19930104", cik = "", form = "ABCDEFGHIJKLMNOPQ"))
    expect_identical(old$date_filed, as.Date("1993-01-04"))
    expect_identical(old$cik, NA_integer_)
    expect_identical(old$form_type, "ABCDEFGHIJKLMNOPQ")
    expect_error(sec_parse_company(charToRaw("<html>Access denied</html>")), "gzip")
    expect_error(sec_parse_company(sec_fixture(cik = "12oops")), "CIK")
    expect_error(sec_parse_company(sec_fixture(cik = "9999999999")), "CIK")
    expect_error(sec_parse_company(sec_fixture(date = "2022-02-30")), "date")
    expect_error(sec_parse_company(sec_fixture(date = "20220401x")), "date")
    expect_error(sec_parse_company(sec_fixture(filename = "")), "rows|fields")
})

test_that("SEC listing timestamps use New York offsets independently of R timezone", {
    withr::local_timezone("Pacific/Auckland")
    winter <- sec_listing_vintage(sec_listing("01/15/2022 12:00:00 AM"))
    summer <- sec_listing_vintage(sec_listing("07/15/2022 12:00:00 PM"))
    expect_equal(winter, as.POSIXct("2022-01-15 05:00:00", tz = "UTC"))
    expect_equal(summer, as.POSIXct("2022-07-15 16:00:00", tz = "UTC"))
    expect_error(sec_listing_vintage(charToRaw("<html>Not an index</html>")), "company.gz")
    expect_error(sec_listing_vintage(sec_listing("02/30/2022 12:00:00 PM")), "timestamp")
    expect_error(sec_listing_vintage(sec_listing("03/13/2022 02:30:00 AM")), "timestamp")
    expect_error(sec_listing_vintage(sec_listing("11/06/2022 01:30:00 AM")), "Ambiguous")
})

test_that("metadata reads aware timestamps and treats unknown vintages as missing", {
    skip_if_not_installed("arrow")
    directory <- sec_test_dir()
    utc <- sec_parse_vintage("2022-04-03T02:15:30Z")
    for (stamp in c("2022-04-03T02:15:30Z", "2022-04-02T22:15:30-04:00",
                    "2022-04-03T12:15:30+10:00")) {
        expect_equal(sec_parquet_last_modified(sec_seed(directory, stamp)), utc)
    }
    for (stamp in list(NULL, "", "garbage", "2022-04-03T02:15:30", "2022-02-30T00:00:00Z", "2022-04-01T00:00:00+25:00")) {
        expect_true(is.na(sec_parquet_last_modified(sec_seed(directory, stamp))))
    }
    expect_error(sec_parquet_last_modified(file.path(directory, "absent.parquet")))
    data <- arrow::as_arrow_table(sec_parse_company(sec_fixture()))
    data <- data$ReplaceSchemaMetadata(list(custom = "retained"))
    path <- file.path(directory, "custom.parquet")
    sec_write_parquet(data, path, utc)
    expect_identical(arrow::ParquetFileReader$create(path)$GetSchema()$metadata$custom, "retained")
    expect_equal(sec_parquet_last_modified(path), utc)
})

test_that("downloads produce typed Parquet, status records, and lazy DuckDB tables", {
    skip_if_not_installed("arrow")
    directory <- sec_test_dir()
    sec_mock_http()
    result <- sec_get_index(2022, 2, data_dir = directory, user_agent = "Tests test@example.org")
    expect_identical(result$status, "downloaded")
    expect_true(is.na(result$error))
    expect_true(is.na(result$archive_path))
    expect_equal(result$last_modified, sec_parse_vintage("2022-04-03T02:15:30Z"))
    expect_equal(arrow::read_parquet(result$path), sec_parse_company(sec_fixture()))
    sec_validate_parquet(result$path, result$last_modified, 1L)
    expect_length(list.files(dirname(result$path), all.files = TRUE, pattern = "lock|sec-index"), 0L)
    skip_if_not_installed("duckdb")
    driver_args <- if ("shared_home" %in% names(formals(duckdb::duckdb))) {
        list(shared_home = FALSE)
    } else list(config = list(home_directory = tempdir()))
    conn <- DBI::dbConnect(do.call(duckdb::duckdb, driver_args))
    on.exit(DBI::dbDisconnect(conn, shutdown = TRUE), add = TRUE)
    lazy <- load_parquet(conn, "sec_index_2022q2", schema = "edgar", data_dir = directory)
    expect_s3_class(lazy, "tbl_lazy")
    expect_equal(dplyr::collect(lazy), sec_parse_company(sec_fixture()))
})

test_that("get reuses without an agent or any request and update compares instants", {
    skip_if_not_installed("arrow")
    directory <- sec_test_dir()
    path <- sec_seed(directory)
    before <- sec_checksum(path)
    withr::local_options(HTTPUserAgent = NULL)
    withr::local_envvar(USER_AGENT = NA)
    local_mocked_bindings(sec_request = function(...) stop("Unexpected request"))
    reused <- sec_get_index(2022, 2, data_dir = directory)
    expect_identical(reused$status, "unchanged")
    expect_identical(sec_checksum(path), before)
    local_mocked_bindings(sec_index_available_update = function(...) sec_parse_vintage("2022-04-02T22:15:30-04:00"))
    same <- sec_index_update(2022, 2, data_dir = directory, user_agent = "test", report = "none")
    expect_identical(same$status, "unchanged")
    local_mocked_bindings(sec_index_available_update = function(...) sec_parse_vintage("2022-04-01T00:00:00Z"))
    older <- sec_index_update(2022, 2, data_dir = directory, user_agent = "test", report = "none")
    expect_identical(older$status, "unchanged")
    expect_identical(sec_checksum(path), before)
    expect_false(dir.exists(file.path(directory, "edgar", "archive")))
})

test_that("updates archive old bytes and overwrite refreshes an equal vintage", {
    skip_if_not_installed("arrow")
    directory <- sec_test_dir()
    path <- sec_seed(directory, "2022-04-01T00:00:00Z")
    before <- sec_checksum(path)
    sec_mock_http()
    updated <- sec_index_update(2022, 2, data_dir = directory, user_agent = "test", report = "none")
    expect_identical(updated$status, "updated")
    expect_identical(sec_checksum(updated$archive_path), before)
    expect_identical(basename(updated$archive_path), "sec_index_2022q2_20220401T000000Z.parquet")
    expect_equal(sec_parquet_last_modified(updated$archive_path), sec_parse_vintage("2022-04-01T00:00:00Z"))
    expect_equal(sec_parquet_last_modified(path), updated$last_modified)
    forced <- sec_get_index(2022, 2, overwrite = TRUE, data_dir = directory, user_agent = "test")
    expect_identical(forced$status, "updated")
    expect_true(file.exists(forced$archive_path))
})

test_that("unknown vintages are refreshed, archived distinctly, and never merely restamped", {
    skip_if_not_installed("arrow")
    directory <- sec_test_dir()
    sec_mock_http()
    archives <- character()
    for (vintage in list(NULL, "not-a-vintage")) {
        path <- sec_seed(directory, vintage)
        before <- sec_checksum(path)
        updated <- sec_index_update(2022, 2, data_dir = directory, user_agent = "test", report = "none")
        expect_identical(updated$status, "updated")
        expect_match(updated$archive_path, "unknown_modified_")
        expect_identical(sec_checksum(updated$archive_path), before)
        expect_identical(arrow::read_parquet(path)$company_name, "CAFÉ INC")
        archives <- c(archives, updated$archive_path)
    }
    expect_length(unique(archives), 2L)
    expect_true(all(file.exists(archives)))
})

test_that("timestamp archive collisions preserve every distinct version", {
    skip_if_not_installed("arrow")
    directory <- sec_test_dir()
    sec_mock_http()
    archives <- character()
    for (company in c("ONE", "TWO", "TWO")) {
        path <- sec_seed(directory, "2022-04-01T00:00:00Z", company)
        before <- sec_checksum(path)
        updated <- sec_get_index(2022, 2, overwrite = TRUE, data_dir = directory, user_agent = "test")
        expect_identical(updated$status, "updated")
        expect_identical(sec_checksum(updated$archive_path), before)
        archives <- c(archives, updated$archive_path)
    }
    expect_length(unique(archives), 2L)
    expect_identical(arrow::read_parquet(archives[1])$company_name, "ONE")
    expect_identical(arrow::read_parquet(archives[2])$company_name, "TWO")
})

test_that("download, parse, validation, archive and replacement failures retain the active file", {
    skip_if_not_installed("arrow")
    for (stage in c("sec_request", "sec_write_parquet", "sec_validate_parquet", "sec_archive", "sec_replace")) {
        local({
            directory <- sec_test_dir()
            path <- sec_seed(directory, "2022-04-01T00:00:00Z")
            before <- sec_checksum(path)
            sec_mock_http()
            mocks <- setNames(list(function(...) stop("Injected failure")), stage)
            do.call(local_mocked_bindings, c(mocks, list(.env = environment(), .package = "farr")))
            result <- sec_index_update(2022, 2, data_dir = directory, user_agent = "test", report = "none")
            expect_identical(result$status, "failed", info = stage)
            expect_match(result$error, "Injected failure", info = stage)
            expect_identical(sec_checksum(path), before, info = stage)
            expect_equal(result$last_modified, sec_parquet_last_modified(path))
            expect_length(list.files(dirname(path), all.files = TRUE, pattern = "lock|sec-index"), 0L)
        })
    }
    directory <- sec_test_dir()
    path <- sec_seed(directory, "2022-04-01T00:00:00Z")
    before <- sec_checksum(path)
    sec_mock_http(content = charToRaw("server error"))
    result <- sec_index_update(2022, 2, data_dir = directory, user_agent = "test", report = "none")
    expect_identical(result$status, "failed")
    expect_match(result$error, "gzip")
    expect_identical(sec_checksum(path), before)
})

test_that("vintage changes and stale supplied timestamps cannot publish mismatched provenance", {
    skip_if_not_installed("arrow")
    directory <- sec_test_dir()
    path <- sec_seed(directory, "2022-04-01T00:00:00Z")
    before <- sec_checksum(path)
    sec_mock_http()
    calls <- 0L
    local_mocked_bindings(sec_index_available_update = function(...) {
        calls <<- calls + 1L
        sec_parse_vintage(if (calls == 1L) "2022-04-03T02:15:30Z" else "2022-04-04T02:15:30Z")
    })
    result <- sec_index_update(2022, 2, data_dir = directory, user_agent = "test", report = "none")
    expect_identical(result$status, "failed")
    expect_match(result$error, "vintage changed")
    expect_identical(sec_checksum(path), before)
    supplied <- sec_get_index(2022, 2, overwrite = TRUE, data_dir = directory,
                              user_agent = "test", last_modified = "2022-04-03T02:15:30Z")
    expect_identical(supplied$status, "failed")
    expect_identical(sec_checksum(path), before)
})

test_that("locks and external changes prevent replacement", {
    skip_if_not_installed("arrow")
    directory <- sec_test_dir()
    path <- sec_seed(directory, "2022-04-01T00:00:00Z")
    dir.create(paste0(path, ".lock"))
    sec_mock_http()
    locked <- sec_get_index(2022, 2, overwrite = TRUE, data_dir = directory, user_agent = "test")
    expect_identical(locked$status, "failed")
    expect_true(dir.exists(paste0(path, ".lock")))
    unlink(paste0(path, ".lock"), recursive = TRUE)
    local_mocked_bindings(sec_request = function(url, user_agent) {
        if (endsWith(url, "company.gz")) {
            sec_seed(directory, "2022-04-02T00:00:00Z", "OTHER WRITER")
            sec_fixture()
        } else sec_listing()
    })
    changed <- sec_get_index(2022, 2, overwrite = TRUE, data_dir = directory, user_agent = "test")
    expect_identical(changed$status, "failed")
    expect_match(changed$error, "Active SEC index changed")
    expect_equal(changed$last_modified, sec_parquet_last_modified(path))
    expect_identical(arrow::read_parquet(path)$company_name, "OTHER WRITER")
})

test_that("local listing excludes archives and has a stable empty schema", {
    skip_if_not_installed("arrow")
    directory <- sec_test_dir()
    empty <- sec_index_local(directory)
    expect_identical(names(empty), c("year", "quarter", "path", "last_modified"))
    expect_equal(nrow(empty), 0L)
    expect_type(empty$year, "integer")
    expect_s3_class(empty$last_modified, "POSIXct")
    path <- sec_seed(directory, NULL)
    dir.create(file.path(dirname(path), "archive"))
    file.copy(path, file.path(dirname(path), "archive", basename(path)))
    file.copy(path, file.path(dirname(path), "sec_index_2022q5.parquet"))
    file.copy(path, file.path(dirname(path), "sec_index_2022q2_old.parquet"))
    listed <- sec_index_local(directory)
    expect_equal(nrow(listed), 1L)
    expect_identical(listed$year, 2022L)
    expect_identical(listed$quarter, 2L)
    expect_identical(listed$path, normalizePath(path))
    expect_true(is.na(listed$last_modified))
})

test_that("target generation handles year and quarter transitions", {
    for (pair in list(c("2026-01-01", "2025", "4"), c("2026-04-01", "2026", "1"),
                      c("2026-04-02", "2026", "2"), c("2026-07-01", "2026", "2"))) {
        local_mocked_bindings(sec_today = function() as.Date(pair[1]))
        targets <- sec_index_targets()
        expect_equal(targets[1, ], tibble::tibble(year = 1993L, quarter = 1L))
        expect_equal(tail(targets, 1), tibble::tibble(year = as.integer(pair[2]), quarter = as.integer(pair[3])))
        expect_false(anyDuplicated(targets) > 0L)
    }
})

test_that("batch reports each status and continues after a failed quarter", {
    skip_if_not_installed("arrow")
    directory <- sec_test_dir()
    sec_seed(directory)
    local_mocked_bindings(sec_index_targets = function() tibble::tibble(year = rep(2022L, 3), quarter = 1:3),
                          sec_request = function(url, user_agent) {
        if (grepl("QTR1", url)) stop("Fixture HTTP 404")
        if (endsWith(url, "company.gz")) sec_fixture() else sec_listing()
    })
    result <- sec_index_update_all(directory, user_agent = "test", report = "none")
    expect_identical(result$status, c("failed", "unchanged", "downloaded"))
    expect_match(result$error[1], "404")
    expect_true(all(is.na(result$error[2:3])))
    expect_message(sec_index_update(2022, 2, directory, user_agent = "test"), "unchanged")
    expect_message(sec_index_update(2022, 1, directory, user_agent = "test", report = "update"), "failed")
    expect_message(sec_index_update(2022, 2, directory, user_agent = "test", report = "update"), NA)
})

test_that("invalid inputs and user-agent resolution fail before requests", {
    local_mocked_bindings(sec_request = function(...) stop("Unexpected request"),
                          sec_today = function() as.Date("2026-04-01"))
    expect_error(sec_get_index(1992, 1), "year")
    expect_error(sec_get_index(2026, 3), "quarter")
    expect_error(sec_get_index(2022, 1.5), "quarter")
    expect_error(sec_get_index(2022, NA), "quarter")
    expect_error(sec_get_index(c(2022, 2023), 1), "year")
    expect_error(sec_get_index(2022, 2, overwrite = NA), "overwrite")
    expect_error(sec_get_index(2022, 2, data_dir = ""), "data_dir")
    expect_error(sec_get_index(2022, 2, data_dir = tempdir(), schema = "../escape"), "schema")
    expect_error(sec_get_index(2022, 2, data_dir = tempdir(), schema = "a\\b"), "schema")
    expect_error(sec_expected_vintage("2022-04-01T00:00:00"), "timezone")
    withr::local_envvar(USER_AGENT = "environment contact")
    withr::local_options(HTTPUserAgent = "option contact")
    expect_identical(sec_user_agent("explicit contact"), "explicit contact")
    expect_identical(sec_user_agent(NULL), "option contact")
    withr::local_options(HTTPUserAgent = NULL)
    expect_identical(sec_user_agent(NULL), "environment contact")
    withr::local_options(HTTPUserAgent = "R (4.6.1 generic platform)")
    expect_identical(sec_user_agent(NULL), "environment contact")
    expect_error(sec_user_agent(""), "user_agent")
    withr::local_envvar(USER_AGENT = NA)
    expect_error(sec_user_agent(NULL), "user_agent")
    expect_error(sec_user_agent("bad\r\nheader"), "user_agent")
})

test_that("HTTP failures are retried only when transient and attempts are bounded", {
    skip_if_not_installed("httr2", minimum_version = "1.2.0")
    count <- 0L
    local_mocked_bindings(req_perform1 = function(req, ...) {
        count <<- count + 1L
        expect_identical(req$options$useragent, "test contact")
        httr2::response(503, headers = list(`Retry-After` = "0"))
    }, .package = "httr2")
    expect_error(sec_request("https://www.sec.gov/fixture", "test contact"))
    expect_identical(count, 3L)
    count <- 0L
    local_mocked_bindings(req_perform1 = function(req, ...) {
        count <<- count + 1L
        httr2::response(404)
    }, .package = "httr2")
    expect_error(sec_request("https://www.sec.gov/fixture", "test contact"))
    expect_identical(count, 1L)
})

test_that("Python string and large_string fixtures are readable in R", {
    skip_if_not_installed("arrow")
    for (type in c("string", "large_string")) {
        path <- test_path("fixtures", "sec-index", paste0("python-", type, ".parquet"))
        expected <- sec_parse_vintage("2022-04-03T02:15:30Z")
        expect_equal(sec_parquet_last_modified(path), expected)
        expect_equal(arrow::read_parquet(path), sec_parse_company(sec_fixture()))
        sec_validate_parquet(path, expected, 1L)
        expect_identical(arrow::ParquetFileReader$create(path)$GetSchema()$metadata$fixture_note,
                         "Synthetic café fixture")
    }
})


test_that("a failed initial download leaves no active file or invented vintage", {
    skip_if_not_installed("arrow")
    directory <- sec_test_dir()
    sec_mock_http(content = charToRaw("not a gzip file"))
    result <- sec_get_index(2022, 2, data_dir = directory, user_agent = "test")
    expect_identical(result$status, "failed")
    expect_false(file.exists(result$path))
    expect_true(is.na(result$last_modified))
    expect_false(dir.exists(file.path(directory, "edgar", "archive")))
})

test_that("an archive checksum conflict cannot destroy the active file", {
    skip_if_not_installed("arrow")
    directory <- sec_test_dir()
    path <- sec_seed(directory, "2022-04-01T00:00:00Z")
    checksum <- sec_checksum(path)
    archive_dir <- file.path(dirname(path), "archive")
    dir.create(archive_dir)
    stem <- "sec_index_2022q2_20220401T000000Z"
    primary <- file.path(archive_dir, paste0(stem, ".parquet"))
    collision <- file.path(archive_dir, paste0(stem, "_", checksum, ".parquet"))
    writeLines("different existing archive", primary)
    writeLines("conflicting checksum archive", collision)
    sec_mock_http()
    result <- sec_get_index(2022, 2, overwrite = TRUE, data_dir = directory, user_agent = "test")
    expect_identical(result$status, "failed")
    expect_match(result$error, "checksum mismatch")
    expect_identical(sec_checksum(path), checksum)
    expect_identical(readLines(primary), "different existing archive")
    expect_identical(readLines(collision), "conflicting checksum archive")
})
