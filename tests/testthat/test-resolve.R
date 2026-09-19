test_that("resolve_dataset() maps an alias to its DOI", {
  expect_equal(resolve_dataset("iptu_sp"), "10.60873/FK2/TOXCRF")
})

test_that("resolve_dataset() passes a bare Insper DOI through", {
  expect_equal(resolve_dataset("10.60873/FK2/TOXCRF"), "10.60873/FK2/TOXCRF")
})

test_that("resolve_dataset() extracts the DOI from URLs and doi: prefixes", {
  inputs <- c(
    "https://doi.org/10.60873/FK2/TOXCRF",
    paste0(
      "https://dataverse.datascience.insper.edu.br/dataset.xhtml?",
      "persistentId=doi:10.60873/FK2/TOXCRF"
    ),
    paste0(
      "https://dataverse.datascience.insper.edu.br/dataset.xhtml?",
      "persistentId=doi:10.60873/FK2/TOXCRF&version=1.0"
    ),
    "doi:10.60873/FK2/TOXCRF"
  )

  for (x in inputs) {
    expect_equal(resolve_dataset(x), "10.60873/FK2/TOXCRF", label = x)
  }
})

test_that("resolve_dataset() rejects DOIs outside the Insper prefix", {
  expect_error(
    resolve_dataset("10.7910/DVN/ABCDEF"),
    "not an Insper Dataverse DOI"
  )
  expect_error(
    resolve_dataset("https://doi.org/10.7910/DVN/ABCDEF"),
    "Could not extract"
  )
})

test_that("resolve_dataset() rejects invalid input", {
  expect_error(resolve_dataset(NA_character_), "single non-empty string")
  expect_error(resolve_dataset(""), "single non-empty string")
  expect_error(resolve_dataset(c("a", "b")), "single non-empty string")
  expect_error(resolve_dataset(1), "single non-empty string")
  expect_error(resolve_dataset("not_a_dataset"), "not found")
})

test_that("resolve_dataset() blocks retired and unpublished aliases", {
  reg <- read_registry()
  status <- vapply(reg, function(x) x[["status"]] %||% "active", character(1))
  retired <- names(status)[status == "retired"]
  unpublished <- names(status)[status == "unpublished"]
  skip_if(length(retired) == 0 || length(unpublished) == 0)

  expect_error(resolve_dataset(retired[[1]]), "no longer available")
  expect_error(resolve_dataset(unpublished[[1]]), "not published")
})

test_that("doi_to_url() builds a doi.org URL", {
  expect_equal(
    doi_to_url("10.60873/FK2/TOXCRF"),
    "https://doi.org/10.60873/FK2/TOXCRF"
  )
})
