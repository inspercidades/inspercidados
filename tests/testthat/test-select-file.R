test_that("detect_file_type() maps extensions, including gzipped text", {
  expect_equal(detect_file_type("a.parquet"), "parquet")
  expect_equal(detect_file_type("a.TSV"), "tab")
  expect_equal(detect_file_type("a.xls"), "xlsx")
  expect_equal(detect_file_type("a.csv.gz"), "csv_gz")
  expect_equal(detect_file_type("a.tab.gz"), "tab_gz")
  expect_equal(detect_file_type("a.txt.gz"), "gz")
  expect_equal(detect_file_type("README.txt"), "unknown")
})

test_that("effective_ext() looks through .gz", {
  expect_equal(
    effective_ext(c("a.csv.gz", "b.RDS", "c.gpkg")),
    c("csv", "rds", "gpkg")
  )
})

test_that("format_priority() puts spatial formats first for spatial data", {
  skip_if_not_installed("sf")

  expect_equal(format_priority(TRUE)[[1]], "gpkg")
  expect_equal(format_priority(FALSE)[[1]], "rds")
})

files <- c(
  "README.txt",
  "Documentacao.xlsx",
  "pemob_2022.parquet",
  "pemob_2022.tab",
  "pemob_2023.parquet",
  "pemob_2023.tab",
  "pemob_2023.xlsx"
)

test_that("select_dv_file() returns an exact filename", {
  expect_equal(
    select_dv_file(files, filename = "pemob_2023.tab"),
    "pemob_2023.tab"
  )
  expect_error(select_dv_file(files, filename = "missing.csv"), "not found")
})

test_that("select_dv_file() follows the preferred format order", {
  out <- select_dv_file(files, year = 2023, prefer = c("tab", "parquet"))

  expect_equal(out, "pemob_2023.tab")
})

test_that("select_dv_file() applies file_pattern", {
  out <- select_dv_file(files, file_pattern = "2022\\.tab$")

  expect_equal(out, "pemob_2022.tab")
  expect_error(
    select_dv_file(files, file_pattern = "^zzz"),
    "No files matched pattern"
  )
})

test_that("select_dv_file() errors on a year with no files", {
  expect_error(select_dv_file(files, year = 1999), "No files matched")
})

test_that("select_dv_file() warns for tied winning-format files", {
  expect_warning(
    out <- select_dv_file(files, prefer = "tab"),
    "Multiple"
  )
  expect_equal(out, "pemob_2022.tab")
})

test_that("select_dv_file() rejects ambiguous files in strict mode", {
  expect_snapshot(error = TRUE, {
    select_dv_file(files, prefer = "tab", strict = TRUE)
  })
})

test_that("select_dv_file() never returns a documentation workbook", {
  out <- select_dv_file(c("Documentacao.xlsx", "dados.xlsx"), prefer = "xlsx")

  expect_equal(out, "dados.xlsx")
  expect_error(
    select_dv_file(c("Documentacao.xlsx", "Metadados - X.xlsx")),
    "only documentation"
  )
})

test_that("select_dv_file() errors when no data files exist", {
  expect_error(select_dv_file(c("README.txt", "notes.pdf")), "No data files")
})
