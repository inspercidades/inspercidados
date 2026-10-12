test_that("get_dataset() requires a registered alias", {
  expect_snapshot(error = TRUE, {
    get_dataset("10.60873/FK2/TOXCRF")
  })
})

test_that("get_dataset() rejects removed file selectors", {
  expect_snapshot(error = TRUE, {
    get_dataset("iptu_sp", filename = "iptu_residencial.gpkg")
  })
})

test_that("get_dataset() validates resource names before downloading", {
  expect_snapshot(error = TRUE, {
    get_dataset("qualidade_ar_mare", resource = "estacoes")
  })
})

test_that("a sole resource does not need a default flag", {
  entry <- list(resources = list(dados = list(default = FALSE)))

  expect_equal(resolve_resource_name(entry, "exemplo"), "dados")
})

test_that("multiple resources without a default require a selection", {
  entry <- list(
    resources = list(
      dados = list(default = FALSE),
      pontos = list(default = FALSE)
    )
  )

  expect_snapshot(error = TRUE, {
    resolve_resource_name(entry, "exemplo")
  })
})

test_that("get_dataset() validates year before downloading", {
  expect_snapshot(error = TRUE, {
    get_dataset("pemob_anual", year = c(2023, 2024))
  })
})

test_that("list_resources() requires a registered alias", {
  expect_snapshot(error = TRUE, {
    list_resources("10.60873/FK2/TOXCRF")
  })
})

test_that("get_dataset() uses a dictionary documentation pattern", {
  skip_if_not_installed("readxl")

  entry <- list(
    resources = list(
      dados = list(
        default = TRUE,
        file_pattern = "^dados[.]",
        formats = "rds",
        is_spatial = FALSE,
        documentation_pattern = "^dict_dados[.]"
      )
    )
  )
  files <- lapply(c("dados.rds", "dict_dados.xlsx"), function(label) {
    list(label = label)
  })
  selected <- NULL
  local_mocked_bindings(
    registry_entry = function(...) entry,
    resolve_dataset = function(...) "10.60873/FK2/TEST",
    read_dv_file = function(...) data.frame(x = 1),
    read_binary_dv_file = function(filename, ...) {
      selected <<- filename
      return(data.frame(term = "value"))
    }
  )
  local_mocked_bindings(
    dataset_files = function(...) files,
    .package = "dataverse"
  )

  out <- suppressMessages(get_dataset("example", docs = TRUE))

  expect_identical(selected, "dict_dados.xlsx")
  expect_named(out, c("data", "docs"))
  expect_equal(out$docs, data.frame(term = "value"))
})
