test_that("list_datasets() shows only active entries by default", {
  out <- list_datasets()

  expect_s3_class(out, "tbl_df")
  expect_setequal(out$alias, names(active_registry()))
  expect_true(all(grepl("^10\\.60873/", out$doi)))
})

test_that("list_datasets(include) widens the listing", {
  n_active <- nrow(list_datasets())
  n_catalogued <- nrow(list_datasets(include = "catalogued"))
  n_all <- nrow(list_datasets(include = "all"))

  expect_lte(n_active, n_catalogued)
  expect_lte(n_catalogued, n_all)
  expect_equal(n_all, length(read_registry()))
})

test_that("list_datasets() filters by project and spatial", {
  pemob <- list_datasets(project = "pemob")
  spatial <- list_datasets(spatial = TRUE)

  expect_true(all(c("pemob_anual", "pemob_harmonizada") %in% pemob$alias))
  expect_true(all(spatial$is_spatial))
})

test_that("list_datasets() searches text fields case-insensitively", {
  out <- list_datasets(search = "PEMOB")

  expect_true("pemob_anual" %in% out$alias)
})

test_that("list_datasets() tells the user when nothing matches", {
  expect_message(
    out <- list_datasets(search = "zzz_no_match"),
    "No datasets matched"
  )
  expect_equal(nrow(out), 0)
})

test_that("list_resources() describes logical resources", {
  out <- list_resources("qualidade_ar_mare")

  expect_s3_class(out, "tbl_df")
  expect_equal(out$resource, c("dados", "pontos"))
  expect_equal(out$default, c(TRUE, FALSE))
  expect_equal(out$is_spatial, c(FALSE, TRUE))
})

test_that("list_resources() reports registered years", {
  out <- list_resources("pemob_anual")

  expect_equal(out$years, "2019, 2020, 2021, 2022, 2023, 2024")
})

test_that("list_projects() returns one row per project", {
  out <- list_projects()

  expect_s3_class(out, "tbl_df")
  expect_setequal(out$project, names(read_projects()))
  expect_true(all(out$n_datasets >= 1))
})

test_that("open_project() resolves an alias to its project without opening", {
  proj <- read_projects()
  with_repo <- Filter(function(x) !is.null(x[["repo_url"]]), proj)
  skip_if(length(with_repo) == 0)
  alias <- unlist(with_repo[[1]][["datasets"]])[[1]]

  expect_equal(
    suppressMessages(open_project(alias, open = FALSE)),
    with_repo[[1]][["repo_url"]]
  )
  expect_error(open_project("zzz_no_match", open = FALSE), "neither")
})

test_that("get_script() is deprecated in favour of open_project()", {
  expect_warning(
    suppressMessages(get_script("iptu_sp", open = FALSE)),
    "deprecated"
  )
})
