library(dplyr, warn.conflicts = FALSE)

test_that("get_ff_ind(5) works", {
  skip_if_offline("mba.tuck.dartmouth.edu")

  cache_dir <- tempfile()
  dir.create(cache_dir)
  old_options <- options(farr.cache_dir = cache_dir)
  on.exit(options(old_options), add = TRUE)

  expect_equal(get_ff_ind(5) %>%
                   select("ff_ind") %>%
                   distinct() %>%
                   pull() %>%
                   length(), 4)
})

test_that("get_ff_ind uses cached zip by default", {
  cache_dir <- tempfile()
  dir.create(cache_dir)
  old_options <- options(farr.cache_dir = cache_dir)
  on.exit(options(old_options), add = TRUE)

  cache_file <- file.path(cache_dir, "Siccodes5.zip")
  writeLines("cached", cache_file)
  downloads <- 0

  testthat::local_mocked_bindings(
    download_ff_ind_zip = function(url, destfile) {
      downloads <<- downloads + 1
      writeLines("downloaded", destfile)
    },
    read_ff_ind_zip = function(zip_file) zip_file,
    .package = "farr"
  )

  expect_identical(get_ff_ind(5), cache_file)
  expect_identical(downloads, 0)
})

test_that("get_ff_ind can refresh cached zip", {
  cache_dir <- tempfile()
  dir.create(cache_dir)
  old_options <- options(farr.cache_dir = cache_dir)
  on.exit(options(old_options), add = TRUE)

  cache_file <- file.path(cache_dir, "Siccodes5.zip")
  writeLines("cached", cache_file)
  downloads <- 0

  testthat::local_mocked_bindings(
    download_ff_ind_zip = function(url, destfile) {
      downloads <<- downloads + 1
      writeLines("downloaded", destfile)
    },
    read_ff_ind_zip = function(zip_file) zip_file,
    .package = "farr"
  )

  expect_identical(get_ff_ind(5, refresh_cache = TRUE), cache_file)
  expect_identical(downloads, 1)
  expect_identical(readLines(cache_file), "downloaded")
})

test_that("get_ff_ind validates refresh_cache", {
  expect_error(get_ff_ind(5, refresh_cache = NA), "`refresh_cache` must be")
})
