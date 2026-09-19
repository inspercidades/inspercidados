# Structural checks on inst/datasets.json and inst/projects.json. These run
# offline and catch mistakes made in data-raw/build_registry.R.

reg <- read_registry()
proj <- read_projects()

test_that("every entry has a valid status", {
  status <- vapply(
    reg,
    function(x) x[["status"]] %||% NA_character_,
    character(1)
  )

  expect_true(all(status %in% c("active", "unpublished", "retired")))
})

test_that("active entries carry an Insper DOI and a title", {
  active <- active_registry()
  doi <- vapply(active, function(x) x[["doi"]] %||% "", character(1))
  title <- vapply(active, function(x) x[["title"]] %||% "", character(1))

  expect_true(all(grepl("^10\\.60873/", doi)))
  expect_true(all(nzchar(title)))
})

test_that("every resource pattern is a valid regular expression", {
  patterns <- unlist(lapply(reg, function(x) {
    lapply(x[["resources"]], `[[`, "file_pattern")
  }))

  for (p in patterns) {
    expect_no_error(grepl(p, "x", perl = TRUE))
  }
})

test_that("every active alias has at most one default resource", {
  defaults <- vapply(
    active_registry(),
    function(entry) {
      sum(vapply(
        entry[["resources"]],
        function(resource) isTRUE(resource[["default"]]),
        logical(1)
      ))
    },
    integer(1)
  )

  expect_equal(unname(defaults <= 1L), rep(TRUE, length(defaults)))
})

test_that("retired entries point to an active successor when they name one", {
  retired <- Filter(function(x) identical(x[["status"]], "retired"), reg)
  successors <- unlist(lapply(retired, function(x) x[["superseded_by"]]))

  expect_true(all(successors %in% names(active_registry())))
})

test_that("projects list only registered aliases", {
  members <- unlist(lapply(proj, function(x) x[["datasets"]]))

  expect_true(all(members %in% names(reg)))
})

test_that("every alias with a project names a registered project", {
  project <- unlist(lapply(reg, function(x) x[["project"]]))

  expect_true(all(project %in% names(proj)))
})

test_that("project visibility is public or private", {
  visibility <- unlist(lapply(proj, function(x) x[["visibility"]]))

  expect_true(all(visibility %in% c("public", "private")))
})
