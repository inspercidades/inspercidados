# Metadata extraction is covered by the live test in test-live-download.R,
# which checks the real shape returned by dataverse::get_dataset().

test_that("citation formatters produce stable output", {
  authors <- "Oike, Vinicius; Insper Cidades"
  doi <- "10.60873/FK2/TOXCRF"

  expect_snapshot({
    cat(format_text(authors, "2025", "Base de Teste", doi_to_url(doi)))
    cat(format_bibtex(authors, "2025", "Base de Teste", doi))
    cat(format_ris(authors, "2025", "Base de Teste", doi_to_url(doi)))
  })
})
