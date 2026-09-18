# End-to-end downloads. Each test uses a small file (under 1 MB) so the suite
# stays fast; together they exercise every reader the registry relies on.

test_that("get_dataset() reads an rds file by alias", {
  skip_if_no_dataverse()

  out <- suppressMessages(get_dataset("embarques_integracao"))

  expect_s3_class(out, "data.frame")
  expect_gt(nrow(out), 0)
  expect_equal(attr(out, "doi"), "10.60873/FK2/UOKFMF")
})

test_that("get_dataset() reads a tab file by filename", {
  skip_if_no_dataverse()

  out <- suppressMessages(get_dataset(
    "estacoes_motiva",
    filename = "dim_line.tab"
  ))

  expect_s3_class(out, "data.frame")
  expect_gt(nrow(out), 0)
})

test_that("get_dataset() reads xlsx and filters by year", {
  skip_if_no_dataverse()
  skip_if_not_installed("readxl")

  out <- suppressMessages(get_dataset(
    "pemob_anual",
    year = 2023,
    file_pattern = "\\.xlsx$"
  ))

  expect_s3_class(out, "data.frame")
  expect_gt(nrow(out), 0)
})

test_that("get_dataset() reads parquet", {
  skip_if_no_dataverse()
  skip_if_not_installed("arrow")

  out <- suppressMessages(get_dataset(
    "iptu_verticalizacao_sp",
    filename = "densidade_populacional.parquet"
  ))

  expect_s3_class(out, "data.frame")
  expect_gt(nrow(out), 0)
})

test_that("get_dataset() returns sf for a spatial alias", {
  skip_if_no_dataverse()
  skip_if_not_installed("sf")

  out <- suppressMessages(get_dataset("qualidade_ar_mare"))

  expect_s3_class(out, "sf")
  expect_gt(nrow(out), 0)
})

test_that("get_dataset() reads geojson", {
  skip_if_no_dataverse()
  skip_if_not_installed("sf")

  out <- suppressMessages(get_dataset(
    "qualidade_ar_mare",
    filename = "qualidade_do_ar_pontos.geojson"
  ))

  expect_s3_class(out, "sf")
})

test_that("get_dataset(docs = TRUE) returns data and documentation", {
  skip_if_no_dataverse()
  skip_if_not_installed("readxl")

  out <- suppressMessages(get_dataset("embarques_integracao", docs = TRUE))

  expect_named(out, c("data", "docs"))
  expect_s3_class(out$data, "data.frame")
  expect_s3_class(out$docs, "data.frame")
})

test_that("get_dataverse() lists files from a DOI and a landing page URL", {
  skip_if_no_dataverse()
  url <- "https://dataverse.datascience.insper.edu.br/dataset.xhtml?persistentId=doi:10.60873/FK2/UOKFMF"

  by_doi <- suppressMessages(get_dataverse("10.60873/FK2/UOKFMF", files = TRUE))
  by_url <- suppressMessages(get_dataverse(url, files = TRUE))

  expect_type(by_doi, "character")
  expect_true("emb_modo.rds" %in% by_doi)
  expect_equal(by_url, by_doi)
})

test_that("get_dataverse() explains an unknown deposit", {
  skip_if_no_dataverse()

  expect_error(
    suppressMessages(get_dataverse("10.60873/FK2/NOTREAL", files = TRUE)),
    "Could not read"
  )
})

test_that("cite_dataset() reads title and year from live metadata", {
  skip_if_no_dataverse()

  text <- suppressMessages(cite_dataset("geoses_sp"))

  expect_match(text, "https://doi.org/10.60873/FK2/7IXFPX", fixed = TRUE)
  expect_match(text, "(2025)", fixed = TRUE)
  expect_no_match(text, ". NA.", fixed = TRUE)
})

test_that("cite_dataset() returns BibTeX and RIS", {
  skip_if_no_dataverse()

  bibtex <- suppressMessages(cite_dataset("geoses_sp", format = "bibtex"))
  ris <- suppressMessages(cite_dataset("geoses_sp", format = "ris"))

  expect_match(bibtex, "^@dataset\\{")
  expect_match(bibtex, "doi       = {10.60873/FK2/7IXFPX}", fixed = TRUE)
  expect_match(ris, "^TY  - DATA")
  expect_match(ris, "ER  -$")
})
