# Live tests hit the real Insper Dataverse. Run them only when explicitly
# enabled by the scheduled live-test workflow or a local developer.
skip_if_no_dataverse <- function() {
  testthat::skip_on_cran()
  testthat::skip_if(
    !isTRUE(as.logical(Sys.getenv("INSPERCIDADOS_RUN_LIVE", "false"))),
    "INSPERCIDADOS_RUN_LIVE is not set"
  )
  testthat::skip_if_offline(insper_server())
  return(invisible(TRUE))
}

# Several aliases share one deposit, so file listings are cached for the
# whole test run. Errors are cached too, as a character message.
.live_cache <- new.env(parent = emptyenv())

live_file_names <- function(doi) {
  if (!is.null(.live_cache[[doi]])) {
    return(.live_cache[[doi]])
  }
  out <- tryCatch(
    {
      files <- dataverse::dataset_files(
        doi_to_url(doi),
        server = insper_server()
      )
      vapply(files, function(f) f[["label"]], character(1))
    },
    error = function(e) structure(conditionMessage(e), class = "live_error")
  )
  assign(doi, out, envir = .live_cache)
  return(out)
}

# Files that belong to one registered resource.
live_resource_files <- function(entry, resource) {
  file_names <- live_file_names(entry[["doi"]])
  if (inherits(file_names, "live_error")) {
    return(file_names)
  }
  pattern <- entry[["resources"]][[resource]][["file_pattern"]]
  file_names <- file_names[grepl(pattern, file_names, perl = TRUE)]
  return(file_names)
}
