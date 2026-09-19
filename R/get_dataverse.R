#' Download any Insper Dataverse dataset from a DOI or URL
#'
#' Downloads a deposit that has no alias in the package registry. Copy the DOI
#' or the landing-page URL from Insper's Dataverse and paste it straight into R.
#'
#' Registered datasets are better served by [get_dataset()], which knows which
#' file to pick. This function has no such knowledge, so it lists the deposit
#' and applies the same format preference to whatever it finds. Deposits with an
#' unusual file layout may need `filename` or `file_pattern` to resolve, and
#' formats the package cannot read will raise an error naming the file.
#'
#' Only DOIs under the `10.60873` prefix are served, since the package always
#' talks to Insper's Dataverse.
#'
#' @param x A DOI (`"10.60873/FK2/AOLEOI"`), a DOI URL, or a Dataverse
#'   landing-page URL containing `persistentId=doi:...`.
#' @param filename,file_pattern,year Optional selectors passed to the same
#'   file-picking logic used by [get_dataset()].
#' @param files Logical. If `TRUE`, list the deposit's files and return their
#'   names instead of downloading anything. Useful for inspecting an unfamiliar
#'   deposit first.
#'
#' @return A [tibble][tibble::tibble] or `sf` object with the `"doi"` attribute
#'   set. When `files = TRUE`, a character vector of filenames.
#'
#' @seealso [get_dataset()] for registered datasets.
#'
#' @export
#' @examplesIf live_examples()
#' # Inspect a deposit before downloading
#' get_dataverse("10.60873/FK2/YWXLQS", files = TRUE)
#'
#' # Paste a DOI straight from the Dataverse page
#' linhas <- get_dataverse("10.60873/FK2/YWXLQS", filename = "dim_line.rds")
#'
#' # Or the landing-page URL
#' linhas <- get_dataverse(
#'   "https://dataverse.datascience.insper.edu.br/dataset.xhtml?persistentId=doi:10.60873/FK2/YWXLQS",
#'   filename = "dim_line.rds"
#' )
get_dataverse <- function(
  x,
  filename = NULL,
  file_pattern = NULL,
  year = NULL,
  files = FALSE
) {
  doi <- resolve_dataset(x)
  doi_url <- doi_to_url(doi)
  server <- insper_server()

  cli::cli_inform(c("i" = "Fetching file list for {.val {doi}}"))
  listing <- tryCatch(
    dataverse::dataset_files(doi_url, server = server),
    error = function(e) {
      cli::cli_abort(c(
        "Could not read {.val {doi}} from Insper Dataverse.",
        "i" = "The deposit may be restricted, unpublished, or withdrawn.",
        "x" = conditionMessage(e)
      ))
    }
  )
  file_names <- vapply(listing, function(f) f[["label"]], character(1))

  if (files) {
    cli::cli_inform(c("i" = "{length(file_names)} file{?s} in {.val {doi}}"))
    cli::cli_ul(file_names)
    return(invisible(file_names))
  }

  spatial <- any(effective_ext(file_names) %in% c("gpkg", "geojson"))

  target <- select_dv_file(
    file_names,
    year = year,
    filename = filename,
    file_pattern = file_pattern,
    prefer = format_priority(spatial)
  )

  cli::cli_inform(c("i" = "Downloading {.val {target}}"))
  data <- read_dv_file(target, doi_url, server, detect_file_type(target))
  attr(data, "doi") <- doi
  data
}
