test_that("load_parquet checks the data directory before querying a connection", {
    withr::local_envvar(DATA_DIR = NA)
    expect_error(load_parquet(NULL, "example", schema = "glms"), "Set DATA_DIR")
    withr::local_envvar(DATA_DIR = tempdir())
    expect_error(load_parquet(NULL, "example", data_dir = ""), "nonempty `data_dir`")
    expect_error(load_parquet(NULL, "example", data_dir = "  "), "nonempty `data_dir`")
})

test_that("load_parquet reads from DATA_DIR or an explicitly supplied repository", {
    skip_if_not_installed("duckdb")
    directory <- withr::local_tempdir()
    dir.create(file.path(directory, "glms"))
    driver_args <- if ("shared_home" %in% names(formals(duckdb::duckdb))) {
        list(shared_home = FALSE)
    } else list(config = list(home_directory = tempdir()))
    conn <- DBI::dbConnect(do.call(duckdb::duckdb, driver_args))
    withr::defer(DBI::dbDisconnect(conn, shutdown = TRUE))
    expected <- tibble::tibble(value = 1:3)
    DBI::dbWriteTable(conn, "example", expected)
    path <- file.path(directory, "glms", "example.parquet")
    DBI::dbExecute(conn, paste0("COPY example TO ", DBI::dbQuoteString(conn, path), " (FORMAT PARQUET)"))

    withr::local_envvar(DATA_DIR = NA)
    explicit <- load_parquet(conn, "example", schema = "glms", data_dir = directory)
    expect_s3_class(explicit, "tbl_lazy")
    expect_equal(dplyr::collect(explicit), expected)

    withr::local_envvar(DATA_DIR = directory)
    expect_equal(dplyr::collect(load_parquet(conn, "example", schema = "glms")), expected)
})
