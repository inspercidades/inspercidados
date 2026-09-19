test_that("browse_project() is a deprecated alias for open_project()", {
  expect_warning(
    suppressMessages(browse_project("iptu_sp", open = FALSE)),
    "deprecated"
  )
  expect_error(
    suppressWarnings(suppressMessages(
      browse_project("zzz_no_match", open = FALSE)
    )),
    "neither"
  )
})
