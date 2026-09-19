build_registry_path <- testthat::test_path(
  "..",
  "..",
  "data-raw",
  "build_registry.R"
)
testthat::skip_if_not(
  file.exists(build_registry_path),
  "data-raw scripts are not included in the source package"
)
suppressWarnings(source(build_registry_path))

new_catalog_row <- function() {
  return(data.frame(
    titulo_da_colecao = "Collection [2020-2024]",
    filtro_tema = "Mobilidade",
    filtro_regiao = "Brasil",
    filtro_acesso = "Disponível para download",
    palavra_chave_1 = "Mobilidade Urbana",
    palavra_chave_2 = "Transporte público",
    palavra_chave_3 = "SIMU",
    palavra_chave_4 = NA_character_,
    palavra_chave_5 = NA_character_,
    titulo_da_base_de_dados = "Dataset [2020-2024]",
    descricao_da_base_de_dados = "Dataset description.",
    link_da_base_de_dados_data_verse = paste0(
      "https://example.org/?persistentId=",
      "doi:10.60873/FK2/TEST"
    ),
    stringsAsFactors = FALSE
  ))
}

test_that("valid catalog rows pass validation", {
  catalog <- new_catalog_row()
  expect_no_error(validate_catalog(catalog))
  expect_equal(nrow(catalog_validation_issues(catalog)), 0L)
})

test_that("blank catalog rows are removed before validation", {
  catalog <- new_catalog_row()
  catalog[2, ] <- NA_character_
  expect_equal(nrow(drop_blank_catalog_rows(catalog)), 1L)
})

test_that("catalog schema errors name missing fields", {
  catalog <- new_catalog_row()
  catalog$filtro_tema <- NULL
  expect_snapshot(error = TRUE, validate_catalog_schema(catalog))
})

test_that("catalog validation collects manual input errors", {
  catalog <- new_catalog_row()
  catalog$filtro_tema <- "Transportes"
  catalog$palavra_chave_3 <- catalog$palavra_chave_1
  catalog$palavra_chave_2 <- NA_character_
  catalog$link_da_base_de_dados_data_verse <- NA_character_
  expect_snapshot(error = TRUE, validate_catalog(catalog))
})

test_that("secure-room entries may omit a DOI", {
  catalog <- new_catalog_row()
  catalog$filtro_acesso <- "Sala segura do Insper"
  catalog$link_da_base_de_dados_data_verse <- NA_character_
  expect_no_error(validate_catalog(catalog))
})

test_that("download entries without a DOI become unpublished", {
  catalog <- new_catalog_row()
  catalog$link_da_base_de_dados_data_verse <- NA_character_

  prepared <- prepare_catalog(catalog)

  expect_equal(prepared$access, "unpublished")
})

test_that("additional keyword columns count toward the maximum", {
  catalog <- new_catalog_row()
  catalog$palavra_chave_4 <- "Metrô"
  catalog$palavra_chave_5 <- "Fluxo"
  catalog$palavra_chave_6 <- "Demanda de passageiros"

  issues <- catalog_validation_issues(catalog)

  expect_equal(issues$field, "keywords")
  expect_match(issues$problem, "expected 3 to 5 keywords, found 6")
})

test_that("DOIs are extracted from persistent identifier links", {
  links <- c(
    "https://example.org/?persistentId=doi:10.60873/FK2/ABC123",
    "doi:10.60873/FK2/XYZ789",
    NA_character_
  )
  expect_equal(
    extract_doi(links),
    c("10.60873/FK2/ABC123", "10.60873/FK2/XYZ789", NA_character_)
  )
})

test_that("effective extensions look through gzip compression", {
  expect_equal(
    file_ext_each(c("table.csv.gz", "shape.gpkg", "README")),
    c("csv", "gpkg", "")
  )
})

test_that("sheet aliases carry their resources when renamed", {
  catalog <- data.frame(alias = "novo", doi = "10.60873/FK2/TEST")
  aliases <- data.frame(
    doi = "10.60873/FK2/TEST",
    alias = "antigo",
    primary = TRUE,
    project = NA_character_,
    notes = NA_character_
  )
  resources <- data.frame(alias = "antigo", resource = "dados")

  out <- suppressWarnings(reconcile_aliases(catalog, aliases, resources))

  expect_equal(out$aliases$alias, "novo")
  expect_equal(out$resources$alias, "novo")
})
