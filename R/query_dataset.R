#' Query a large dataset without downloading it
#'
#' Opens a registered parquet dataset as a lazy table backed by DuckDB.
#' DuckDB reads the file directly from Insper Dataverse and fetches only the
#' columns and row groups a query needs, so large datasets such as
#' `"itbi_sp"` can be filtered and summarised without loading them into
#' memory. Use dplyr verbs to build the query and [dplyr::collect()] to bring
#' the result into R.
#'
#' Only resources distributed as parquet can be queried; use [get_dataset()]
#' for the others. When a resource is split into annual files and `year` is
#' `NULL`, all years are combined into one table.
#'
#' DuckDB loads `httpfs` from its shared extension cache or installs it on the
#' first call. The cache is stored under `~/.duckdb`.
#'
#' @inheritParams get_dataset
#' @param year An integer or character year used to keep a single annual file.
#'   When `NULL`, every annual file is included.
#'
#' @return A lazy [dbplyr][dbplyr::dbplyr] table (`tbl_duckdb_connection`)
#'   with the `"doi"` attribute set.
#'
#' @seealso [get_dataset()] to download a dataset into memory.
#'
#' @export
#' @examplesIf live_examples() && requireNamespace("dbplyr", quietly = TRUE) && requireNamespace("duckdb", quietly = TRUE)
#' itbi <- query_dataset("itbi_sp")
#'
#' # Transactions per year, computed by DuckDB
#' itbi |>
#'   dplyr::count(ano = dplyr::sql("year(data_de_transacao)")) |>
#'   dplyr::arrange(ano) |>
#'   dplyr::collect()
query_dataset <- function(dataset, ..., resource = NULL, year = NULL) {
  rlang::check_dots_empty()
  rlang::check_installed(
    c("duckdb (>= 1.5.5)", "DBI", "dbplyr", "dplyr"),
    reason = "to query datasets lazily"
  )
  entry <- registry_entry(dataset)
  if (is.null(entry)) {
    cli::cli_abort(c(
      "{.fn query_dataset} requires a registered dataset alias.",
      "i" = "Run {.run inspercidados::list_datasets()} to see available aliases."
    ))
  }
  doi <- resolve_dataset(dataset)
  resource <- resolve_resource_name(entry, dataset, resource)
  definition <- entry[["resources"]][[resource]]
  if (
    !is.null(year) &&
      (!is.atomic(year) || length(year) != 1 || is.na(year))
  ) {
    cli::cli_abort("{.arg year} must be a single value or {.code NULL}.")
  }
  if (!"parquet" %in% unlist(definition[["formats"]])) {
    cli::cli_abort(c(
      "Resource {.val {resource}} of {.val {dataset}} has no parquet file.",
      "i" = "Use {.run inspercidados::get_dataset(\"{dataset}\")} instead."
    ))
  }

  cli::cli_inform(c("i" = "Fetching file list for {.val {doi}}"))
  files <- dataverse::dataset_files(doi_to_url(doi), server = insper_server())
  urls <- parquet_file_urls(files, definition[["file_pattern"]], year = year)

  con <- duckdb_connection()
  data <- dplyr::tbl(con, dplyr::sql(read_parquet_sql(urls)))
  attr(data, "doi") <- doi
  return(data)
}
