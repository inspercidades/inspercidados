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

test_that("every registry file_pattern matches files in its deposit", {
  skip_if_no_dataverse()
  reg <- active_registry()
  with_pattern <- Filter(function(x) !is.null(x[["file_pattern"]]), reg)

  broken <- Filter(
    function(alias) length(live_alias_files(with_pattern[[alias]])) == 0,
    names(with_pattern)
  )

  expect_equal(broken, character(0))
})

test_that("get_dataset() can pick a data file for every active alias", {
  skip_if_no_dataverse()
  reg <- active_registry()

  broken <- Filter(
    function(alias) {
      entry <- reg[[alias]]
      pick <- tryCatch(
        suppressWarnings(select_dv_file(
          live_alias_files(entry),
          prefer = format_priority(isTRUE(entry[["is_spatial"]]))
        )),
        error = function(e) NULL
      )
      return(is.null(pick))
    },
    names(reg)
  )

  expect_equal(broken, character(0))
})

test_that("registry formats match the files in each deposit", {
  skip_if_no_dataverse()
  reg <- active_registry()

  drift <- lapply(names(reg), function(alias) {
    file_names <- live_alias_files(reg[[alias]])
    observed <- unique(effective_ext(file_names))
    observed <- sort(observed[observed %in% DATA_EXTS])
    registered <- sort(unlist(reg[[alias]][["formats"]]))
    if (identical(observed, registered)) {
      return(NULL)
    }
    return(sprintf(
      "%s: registry has [%s], deposit has [%s]",
      alias,
      paste(registered, collapse = ", "),
      paste(observed, collapse = ", ")
    ))
  })

  expect_equal(unlist(drift), NULL)
})

test_that("is_spatial matches the presence of spatial files", {
  skip_if_no_dataverse()
  reg <- active_registry()

  broken <- Filter(
    function(alias) {
      observed <- any(
        effective_ext(live_alias_files(reg[[alias]])) %in% c("gpkg", "geojson")
      )
      return(observed != isTRUE(reg[[alias]][["is_spatial"]]))
    },
    names(reg)
  )

  expect_equal(broken, character(0))
})
