# The registry is fetched from GitHub at runtime and falls back to the copy
# shipped with the package. The fetch is mocked here, so these tests stay
# offline.

local_registry_source <- function(source, env = parent.frame()) {
  withr::local_options(inspercidados.registry = source, .local_envir = env)
  rm(list = ls(.registry_cache, all.names = TRUE), envir = .registry_cache)
  withr::defer(
    rm(list = ls(.registry_cache, all.names = TRUE), envir = .registry_cache),
    envir = env
  )
  return(invisible(NULL))
}

remote_fixture <- function(file, schema_version = 1L) {
  if (identical(file, "datasets.json")) {
    return(list(
      schema_version = schema_version,
      datasets = list(new_alias = list(status = "active"))
    ))
  }
  return(list(
    schema_version = schema_version,
    projects = list(new_project = list(datasets = list("new_alias")))
  ))
}

bundled_aliases <- function() {
  path <- system.file("datasets.json", package = "inspercidados")
  return(names(jsonlite::read_json(path)[["datasets"]]))
}

test_that("a valid remote registry replaces the bundled one", {
  local_registry_source("remote")
  local_mocked_bindings(fetch_registry_file = function(file) {
    remote_fixture(file)
  })

  expect_named(read_registry(), "new_alias")
  expect_named(read_projects(), "new_project")
})

test_that("a failed fetch falls back to the bundled registry", {
  local_registry_source("remote")
  local_mocked_bindings(fetch_registry_file = function(file) NULL)

  expect_named(read_registry(), bundled_aliases())
})

test_that("a newer schema falls back to the bundled registry", {
  local_registry_source("remote")
  local_mocked_bindings(fetch_registry_file = function(file) {
    remote_fixture(file, schema_version = 99L)
  })

  expect_named(read_registry(), bundled_aliases())
})

test_that("a malformed remote file falls back to the bundled registry", {
  local_registry_source("remote")
  local_mocked_bindings(fetch_registry_file = function(file) {
    list(schema_version = 1L)
  })

  expect_named(read_registry(), bundled_aliases())
})

test_that("one failed file makes both files fall back together", {
  local_registry_source("remote")
  local_mocked_bindings(fetch_registry_file = function(file) {
    if (identical(file, "projects.json")) {
      return(NULL)
    }
    return(remote_fixture(file))
  })

  expect_named(read_registry(), bundled_aliases())
  expect_false("new_project" %in% names(read_projects()))
})

test_that("the bundled option never fetches", {
  local_registry_source("bundled")
  local_mocked_bindings(fetch_registry_file = function(file) {
    stop("fetch_registry_file() should not be called")
  })

  expect_named(read_registry(), bundled_aliases())
})

test_that("the registry is fetched once per session", {
  local_registry_source("remote")
  calls <- 0L
  local_mocked_bindings(fetch_registry_file = function(file) {
    calls <<- calls + 1L
    remote_fixture(file)
  })

  read_registry()
  read_projects()
  read_registry()

  expect_equal(calls, 2L)
})

test_that("R CMD check uses the bundled registry by default", {
  withr::local_options(inspercidados.registry = NULL)

  withr::local_envvar(`_R_CHECK_PACKAGE_NAME_` = "inspercidados")
  expect_equal(registry_source(), "bundled")

  withr::local_envvar(`_R_CHECK_PACKAGE_NAME_` = NA)
  expect_equal(registry_source(), "remote")
})

test_that("an unknown registry option is an error", {
  withr::local_options(inspercidados.registry = "github")
  expect_snapshot(error = TRUE, registry_source())
})
