with_size_rets_fixture <- function(code) {
  skip_if(Sys.which(Sys.getenv("R_ZIPCMD", "zip")) == "", "zip is unavailable")

  root <- tempfile("size-rets-")
  dir.create(root)
  cwd <- file.path(root, "cwd")
  dir.create(cwd)
  old_wd <- getwd()
  old_buffer <- Sys.getenv("VROOM_CONNECTION_SIZE", unset = NA_character_)
  on.exit({
    setwd(old_wd)
    Sys.chmod(cwd, "0700")
    unlink(root, recursive = TRUE)
    if (is.na(old_buffer)) {
      Sys.unsetenv("VROOM_CONNECTION_SIZE")
    } else {
      Sys.setenv(VROOM_CONNECTION_SIZE = old_buffer)
    }
  }, add = TRUE)

  header <- paste0(",Lo 30,Med 40,Hi 30,Lo 10,",
                   paste0(2:9, "-Dec", collapse = ","), ",Hi 10")
  csv <- file.path(root, "size-returns.csv")
  writeLines(c(
    "Synthetic size portfolio returns", "",
    "  Value Weight Returns -- Monthly", header,
    "202001,999,999,999,1,2,3,4,5,6,7,8,9,10",
    "202002,999,999,999,-1,-2,-3,-4,-5,-6,-7,-8,-9,-99.99",
    "", "",
    "  Equal Weight Returns -- Monthly", header,
    "202001,999,999,999,11,12,13,14,15,16,17,18,19,20",
    "202002,999,999,999,0,-12,-13,-14,-15,-16,-17,-18,-19,-20",
    "", "",
    "  Value Weight Returns -- Annual", header,
    "2020,999,999,999,1,2,3,4,5,6,7,8,9,10"
  ), csv)
  zip <- file.path(root, "fixture.zip")
  stopifnot(utils::zip(zip, csv, flags = "-qj") == 0L)

  sentinel <- file.path(cwd, "Portfolios_Formed_on_ME_CSV.zip")
  bytes <- as.raw(c(0, 1, 127, 128, 255))
  writeBin(bytes, sentinel)
  setwd(cwd)
  code(list(zip = zip, cwd = cwd, sentinel = sentinel, bytes = bytes))
}

expect_size_rets_sentinel <- function(fixture) {
  expect_true(file.exists(fixture$sentinel))
  if (file.exists(fixture$sentinel)) {
    expect_identical(readBin(fixture$sentinel, "raw", n = 100), fixture$bytes)
  }
}

test_that("size returns use distinct temporary downloads and preserve parsed data", {
  with_size_rets_fixture(function(fixture) {
    downloads <- list()
    local_mocked_bindings(download.file = function(url, destfile, quiet, mode = "") {
      downloads[[length(downloads) + 1L]] <<-
        list(url = url, path = destfile, quiet = quiet, mode = mode)
      stopifnot(file.copy(fixture$zip, destfile, overwrite = TRUE))
      0L
    }, .package = "utils")

    first <- get_size_rets_monthly()
    second <- get_size_rets_monthly()
    expected <- tibble::tibble(
      month = rep(as.Date(c("2020-01-01", "2020-02-01")), each = 10),
      decile = rep(1:10, 2),
      ew_ret = c(11:20, 0, -(12:20)) / 100,
      vw_ret = c(1:10, -(1:9), NA_real_) / 100
    )
    expect_identical(first, expected)
    expect_identical(second, expected)
    expect_length(downloads, 2)
    paths <- vapply(downloads, `[[`, "", "path")
    expect_length(unique(paths), 2)
    expect_true(all(
      normalizePath(dirname(paths), winslash = "/", mustWork = TRUE) ==
        normalizePath(tempdir(), winslash = "/", mustWork = TRUE)
    ))
    expect_false(any(file.exists(paths)))
    for (download in downloads) {
      expect_identical(download$url, paste0(
        "https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/",
        "Portfolios_Formed_on_ME_CSV.zip"
      ))
      expect_true(download$quiet)
      expect_identical(download$mode, "wb")
    }
    expect_size_rets_sentinel(fixture)
  })
})

test_that("partial size-return downloads are removed after a download error", {
  with_size_rets_fixture(function(fixture) {
    path <- NULL
    local_mocked_bindings(download.file = function(url, destfile, ...) {
      path <<- destfile
      writeLines("partial download", destfile)
      stop("download failed")
    }, .package = "utils")

    expect_error(get_size_rets_monthly(), "download failed")
    expect_false(file.exists(path))
    expect_size_rets_sentinel(fixture)
  })
})

test_that("size-return downloads are removed when reading the archive fails", {
  with_size_rets_fixture(function(fixture) {
    path <- NULL
    local_mocked_bindings(download.file = function(url, destfile, ...) {
      path <<- destfile
      stopifnot(file.copy(fixture$zip, destfile, overwrite = TRUE))
      0L
    }, .package = "utils")
    local_mocked_bindings(read_lines = function(...) stop("archive read failed"),
                          .package = "readr")

    expect_error(get_size_rets_monthly(), "archive read failed")
    expect_false(file.exists(path))
    expect_size_rets_sentinel(fixture)
  })
})

test_that("size returns work in a read-only working directory", {
  with_size_rets_fixture(function(fixture) {
    Sys.chmod(fixture$cwd, "0555")
    skip_if(file.access(fixture$cwd, 2) == 0L,
            "working-directory permissions are not enforced")
    path <- NULL
    local_mocked_bindings(download.file = function(url, destfile, ...) {
      path <<- destfile
      stopifnot(file.copy(fixture$zip, destfile, overwrite = TRUE))
      0L
    }, .package = "utils")

    expect_equal(nrow(get_size_rets_monthly()), 20L)
    expect_false(file.exists(path))
    expect_size_rets_sentinel(fixture)
  })
})

for (buffer in c(NA_character_, "", "12345")) {
  for (fail_on_read in c(0L, 1L, 2L)) {
    test_that(paste("size returns restore the buffer setting", dQuote(buffer),
                    "after parser call", fail_on_read), {
      with_size_rets_fixture(function(fixture) {
        if (is.na(buffer)) {
          Sys.unsetenv("VROOM_CONNECTION_SIZE")
        } else {
          Sys.setenv(VROOM_CONNECTION_SIZE = buffer)
        }
        initial_buffer <- Sys.getenv("VROOM_CONNECTION_SIZE", unset = NA_character_)
        path <- NULL
        local_mocked_bindings(download.file = function(url, destfile, ...) {
          path <<- destfile
          stopifnot(file.copy(fixture$zip, destfile, overwrite = TRUE))
          0L
        }, .package = "utils")
        original_read_csv <- readr::read_csv
        parser_calls <- 0L
        local_mocked_bindings(read_csv = function(...) {
          parser_calls <<- parser_calls + 1L
          expect_identical(Sys.getenv("VROOM_CONNECTION_SIZE"), "5e+05")
          if (parser_calls == fail_on_read) stop("parse failed")
          original_read_csv(...)
        }, .package = "readr")

        if (fail_on_read == 0L) {
          expect_equal(nrow(get_size_rets_monthly()), 20L)
          expect_identical(parser_calls, 2L)
        } else {
          expect_error(get_size_rets_monthly(), "parse failed")
          expect_identical(parser_calls, fail_on_read)
        }
        expect_identical(Sys.getenv("VROOM_CONNECTION_SIZE", unset = NA_character_),
                         initial_buffer)
        expect_false(file.exists(path))
        expect_size_rets_sentinel(fixture)
      })
    })
  }
}
