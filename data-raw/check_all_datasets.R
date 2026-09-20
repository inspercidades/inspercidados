# Download every active dataset -----------------------------------------------

# Run before a release to exercise every registered alias against the live
# Dataverse. This is intentionally separate from the regular test suite because
# several datasets are large. Run from the package root:
#
#   Rscript data-raw/check_all_datasets.R
#
# A failing resource is recorded and the run continues, so one broken deposit
# does not hide the status of the rest; the script still errors at the end if
# anything failed. Results are saved to data-raw/check_results.csv after every
# resource, so an interrupted run can be completed by setting `resume` to TRUE:
# resources already recorded as ok there are skipped.

resume <- FALSE
results_csv <- "data-raw/check_results.csv"

options(warn = 1) # surface warnings next to the resource that raised them

devtools::load_all()

registry <- active_registry()
results <- list()

# One row of the results table for a resource that could not be downloaded.
failure_record <- function(alias, resource, year, message) {
  data.frame(
    alias = alias,
    resource = resource,
    year = year %||% NA_character_,
    rows = NA_integer_,
    columns = NA_integer_,
    class = NA_character_,
    ok = FALSE,
    error = message,
    stringsAsFactors = FALSE
  )
}

# With resume = TRUE, reuse the ok rows of a previous (partial) run.
previous <- NULL
previous_keys <- character(0)
if (isTRUE(resume)) {
  if (file.exists(results_csv)) {
    previous <- utils::read.csv(
      results_csv,
      stringsAsFactors = FALSE,
      na.strings = c("NA", "")
    )
    if (!is.null(previous$ok)) {
      previous_keys <- paste(previous$alias, previous$resource, sep = "/")
    }
  } else {
    cli::cli_alert_info(
      "No {.file {results_csv}} found; checking every resource from scratch."
    )
  }
}

for (alias in names(registry)) {
  entry <- registry[[alias]]
  resources <- entry[["resources"]]
  for (resource in names(resources)) {
    years <- unlist(resources[[resource]][["years"]], use.names = FALSE)
    year <- if (length(years) > 0) years[[length(years)]] else NULL

    key <- paste(alias, resource, sep = "/")
    cli::cli_h2("{alias}/{resource}")

    if (key %in% previous_keys && isTRUE(previous$ok[previous_keys == key])) {
      cli::cli_alert_info("Skipping: already ok in {.file {results_csv}}")
      results[[key]] <- previous[previous_keys == key, ]
      next
    }

    result <- tryCatch(
      {
        data <- get_dataset(
          alias,
          resource = resource,
          year = year
        )
        if (!inherits(data, "data.frame") || nrow(data) == 0) {
          cli::cli_abort(
            "{.val {alias}}/{.val {resource}} did not return a non-empty data frame."
          )
        }
        out <- data.frame(
          alias = alias,
          resource = resource,
          year = year %||% NA_character_,
          rows = nrow(data),
          columns = ncol(data),
          class = class(data)[[1]],
          ok = TRUE,
          error = NA_character_,
          stringsAsFactors = FALSE
        )
        rm(data)
        out
      },
      error = function(e) {
        failure_record(alias, resource, year, conditionMessage(e))
      }
    )
    invisible(gc())

    results[[key]] <- result
    utils::write.csv(
      do.call(rbind, results),
      results_csv,
      row.names = FALSE
    )
    if (isTRUE(result$ok)) {
      cli::cli_alert_success(
        "{result$rows} rows x {result$columns} cols ({result$class})"
      )
    } else {
      cli::cli_alert_danger("{result$error}")
    }
  }
}

results <- do.call(rbind, results)
failures <- results[!results$ok, ]

if (nrow(failures) > 0) {
  cli::cli_alert_warning(
    "Failed to download {nrow(failures)} of {nrow(results)} active resources."
  )
  print(failures[, c("alias", "resource", "error")], row.names = FALSE)
} else {
  cli::cli_alert_success("Downloaded all {nrow(results)} active resources.")
}
print(results[, setdiff(names(results), "error")], row.names = FALSE)

if (nrow(failures) > 0) {
  cli::cli_abort(
    "{nrow(failures)} active resource{?s} failed; see {.file {results_csv}}."
  )
}
