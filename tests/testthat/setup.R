# Tests read the registry shipped with the package, never the copy on GitHub.
withr::local_options(
  inspercidados.registry = "bundled",
  .local_envir = testthat::teardown_env()
)
