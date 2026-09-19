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
