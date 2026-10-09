fake_files <- function(labels) {
  lapply(seq_along(labels), function(i) {
    list(label = labels[[i]], dataFile = list(id = 100L + i))
  })
}

test_that("parquet_file_urls() builds access URLs from file ids", {
  files <- fake_files(c("itbi.csv.gz", "itbi.parquet", "dict_itbi.xlsx"))

  out <- parquet_file_urls(files, "^itbi[.]", server = "example.org")

  expect_equal(out, "https://example.org/api/access/datafile/102")
})

test_that("parquet_file_urls() keeps every annual file when year is NULL", {
  files <- fake_files(c(
    "pemob_2023.parquet",
    "pemob_2024.parquet",
    "pemob_2024.xlsx",
    "pemob_harmonizada.parquet"
  ))

  out <- parquet_file_urls(files, "^pemob_[0-9]{4}[.]", server = "example.org")

  expect_equal(
    out,
    paste0("https://example.org/api/access/datafile/", c(101, 102))
  )
})

test_that("parquet_file_urls() filters by year", {
  files <- fake_files(c("pemob_2023.parquet", "pemob_2024.parquet"))

  out <- parquet_file_urls(
    files,
    "^pemob_[0-9]{4}[.]",
    year = 2024,
    server = "example.org"
  )

  expect_equal(out, "https://example.org/api/access/datafile/102")
})

test_that("parquet_file_urls() aborts when no parquet file matches", {
  files <- fake_files(c("pemob_2023.parquet", "pemob_2024.xlsx"))

  expect_snapshot(error = TRUE, {
    parquet_file_urls(files, "^pemob_[0-9]{4}[.]", year = 2024)
  })
})

test_that("read_parquet_sql() quotes and unions file URLs", {
  skip_if_not_installed("DBI")

  out <- read_parquet_sql(c("https://a.org/1", "https://a.org/it's"))

  expect_equal(
    out,
    paste0(
      "SELECT * FROM read_parquet(['https://a.org/1', ",
      "'https://a.org/it''s'], union_by_name = true)"
    )
  )
})

test_that("query_dataset() requires a registered alias", {
  skip_if_not_installed("duckdb", "1.5.5")
  skip_if_not_installed("dbplyr")

  expect_snapshot(error = TRUE, {
    query_dataset("10.60873/FK2/AOLEOI")
  })
})

test_that("query_dataset() rejects resources without parquet files", {
  skip_if_not_installed("duckdb", "1.5.5")
  skip_if_not_installed("dbplyr")

  expect_snapshot(error = TRUE, {
    query_dataset("embarques_mensais")
  })
})

test_that("query_dataset() validates year before querying", {
  skip_if_not_installed("duckdb", "1.5.5")
  skip_if_not_installed("dbplyr")

  expect_snapshot(error = TRUE, {
    query_dataset("pemob_anual", year = c(2023, 2024))
  })
})

test_that("duckdb_connection() loads a cached extension first", {
  old <- .duckdb_cache$con
  .duckdb_cache$con <- NULL
  withr::defer(.duckdb_cache$con <- old)

  statements <- character()
  local_mocked_bindings(
    dbConnect = function(...) "connection",
    dbExecute = function(conn, statement) {
      statements <<- c(statements, statement)
      return(0L)
    },
    .package = "DBI"
  )
  local_mocked_bindings(
    duckdb = function(...) "driver",
    .package = "duckdb"
  )

  expect_identical(duckdb_connection(), "connection")
  expect_identical(statements, "LOAD httpfs")
})

test_that("duckdb_connection() closes a failed connection", {
  old <- .duckdb_cache$con
  .duckdb_cache$con <- NULL
  withr::defer(.duckdb_cache$con <- old)

  statements <- character()
  disconnected <- FALSE
  local_mocked_bindings(
    dbConnect = function(...) "connection",
    dbExecute = function(conn, statement) {
      statements <<- c(statements, statement)
      stop("extension unavailable")
    },
    dbDisconnect = function(conn, shutdown) {
      disconnected <<- TRUE
      return(TRUE)
    },
    .package = "DBI"
  )
  local_mocked_bindings(
    duckdb = function(...) "driver",
    .package = "duckdb"
  )

  expect_error(duckdb_connection(), "extension unavailable")
  expect_identical(statements, c("LOAD httpfs", "INSTALL httpfs"))
  expect_true(disconnected)
  expect_null(.duckdb_cache$con)
})
