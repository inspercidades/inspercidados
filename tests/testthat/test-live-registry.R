# Registry drift: inst/datasets.json is built from Dataverse at a point in
# time. These tests compare it with what the deposits hold today. Each test
# collects the offending aliases so one failure names all of them.

test_that("every active deposit can be listed", {
  skip_if_no_dataverse()
  reg <- active_registry()

  broken <- Filter(
    function(alias) {
      inherits(live_file_names(reg[[alias]][["doi"]]), "live_error")
    },
    names(reg)
  )

  expect_equal(broken, character(0))
})

test_that("every registered resource matches files in its deposit", {
  skip_if_no_dataverse()
  reg <- active_registry()
  broken <- unlist(lapply(names(reg), function(alias) {
    resources <- names(reg[[alias]][["resources"]])
    bad <- resources[vapply(
      resources,
      function(resource) {
        length(live_resource_files(reg[[alias]], resource)) == 0
      },
      logical(1)
    )]
    if (length(bad) == 0) character() else paste(alias, bad, sep = "/")
  }))

  expect_equal(broken, character(0))
})

test_that("get_dataset() can pick a file for every registered resource", {
  skip_if_no_dataverse()
  reg <- active_registry()

  broken <- unlist(lapply(names(reg), function(alias) {
    entry <- reg[[alias]]
    resources <- names(entry[["resources"]])
    bad <- resources[vapply(
      resources,
      function(resource) {
        definition <- entry[["resources"]][[resource]]
        years <- unlist(definition[["years"]])
        pick <- tryCatch(
          select_dv_file(
            live_resource_files(entry, resource),
            year = if (length(years) > 0) years[[1]] else NULL,
            prefer = format_priority(isTRUE(definition[["is_spatial"]])),
            strict = TRUE
          ),
          error = function(e) NULL
        )
        is.null(pick)
      },
      logical(1)
    )]
    if (length(bad) == 0) character() else paste(alias, bad, sep = "/")
  }))

  expect_equal(broken, character(0))
})

test_that("registry formats match each resource's files", {
  skip_if_no_dataverse()
  reg <- active_registry()

  drift <- unlist(lapply(names(reg), function(alias) {
    entry <- reg[[alias]]
    lapply(names(entry[["resources"]]), function(resource) {
      file_names <- live_resource_files(entry, resource)
      observed <- unique(effective_ext(file_names))
      observed <- sort(observed[observed %in% DATA_EXTS])
      registered <- sort(unlist(
        entry[["resources"]][[resource]][["formats"]]
      ))
      if (identical(observed, registered)) {
        return(NULL)
      }
      sprintf(
        "%s/%s: registry has [%s], deposit has [%s]",
        alias,
        resource,
        paste(registered, collapse = ", "),
        paste(observed, collapse = ", ")
      )
    })
  }))

  expect_equal(drift, NULL)
})

test_that("resource spatial flags match the presence of spatial files", {
  skip_if_no_dataverse()
  reg <- active_registry()

  broken <- unlist(lapply(names(reg), function(alias) {
    entry <- reg[[alias]]
    resources <- names(entry[["resources"]])
    bad <- resources[vapply(
      resources,
      function(resource) {
        observed <- any(
          effective_ext(live_resource_files(entry, resource)) %in%
            c("gpkg", "geojson")
        )
        observed != isTRUE(entry[["resources"]][[resource]][["is_spatial"]])
      },
      logical(1)
    )]
    if (length(bad) == 0) character() else paste(alias, bad, sep = "/")
  }))

  expect_equal(broken, character(0))
})
