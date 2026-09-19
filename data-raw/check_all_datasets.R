# Download every active dataset -----------------------------------------------

# Run before a release to exercise every registered alias against the live
# Dataverse. This is intentionally separate from the regular test suite because
# several datasets are large.

devtools::load_all()

registry <- active_registry()
results <- list()

for (alias in names(registry)) {
  entry <- registry[[alias]]
  resources <- entry[["resources"]]
  for (resource in names(resources)) {
    years <- unlist(resources[[resource]][["years"]], use.names = FALSE)
    year <- if (length(years) > 0) years[[length(years)]] else NULL

    cli::cli_h2("{alias}/{resource}")
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
    key <- paste(alias, resource, sep = "/")
    results[[key]] <- data.frame(
      alias = alias,
      resource = resource,
      year = year %||% NA_character_,
      rows = nrow(data),
      columns = ncol(data),
      class = class(data)[[1]],
      stringsAsFactors = FALSE
    )
    rm(data)
    invisible(gc())
  }
}

results <- do.call(rbind, results)
cli::cli_alert_success("Downloaded all {nrow(results)} active resources.")
print(results, row.names = FALSE)
