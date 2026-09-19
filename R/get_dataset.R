#' Download a dataset from Insper Dataverse
#'
#' Downloads a dataset into R as a tibble or `sf` object. The dataset can be
#' identified by its short alias, bare DOI, or full DOI URL.
#'
#' When a deposit contains multiple files, the function picks one by format.
#' Spatial datasets resolve to GeoPackage so the result is an `sf` object;
#' other datasets favour RDS, then Parquet, then delimited text, then Excel.
#' Formats needing a suggested package are skipped when it is not installed.
#' Use `year`, `filename`, or `file_pattern` to override the choice.
#'
#' Some aliases share a single Dataverse deposit. `"pemob_anual"` and
#' `"pemob_harmonizada"` both point at the PEMOB deposit and are separated by a
#' file pattern stored in the registry.
#'
#' @param dataset A dataset identifier. One of:
#'   - A short alias, e.g. `"iptu_sp"` (see [list_datasets()] for all aliases).
#'   - A bare DOI, e.g. `"10.60873/FK2/TOXCRF"`.
#'   - A full DOI URL, e.g. `"https://doi.org/10.60873/FK2/TOXCRF"`.
#' @param year An integer or character year used to filter files when a dataset
#'   contains multiple annual files (e.g. `year = 2023`).
#' @param filename The exact filename to download from the dataset. Overrides
#'   `year` and `file_pattern`.
#' @param file_pattern A regex pattern matched against filenames. Applied after
#'   `year` filtering.
#' @param docs Logical. If `TRUE`, returns a named list with two elements:
#'   `data` (the downloaded tibble/sf object) and `docs`. When the dataset
#'   contains a file whose name starts with `"documentacao"` (e.g.
#'   `"documentacao_iptu.xlsx"`), that file is downloaded and returned as a
#'   tibble. Otherwise `docs` is a named list of metadata fetched from
#'   Dataverse (title, description, authors, DOI, URL, year). Default is
#'   `FALSE`.
#'
#' @return When `docs = FALSE` (default): a [tibble][tibble::tibble] or `sf`
#'   object with the `"doi"` attribute set. When `docs = TRUE`: a named list
#'   with elements `data` and `docs`.
#'
#' @export
#' @examplesIf live_examples()
#' # By alias
#' embarques <- get_dataset("embarques_mensais")
#'
#' # By DOI, or by the DOI URL
#' embarques <- get_dataset("10.60873/FK2/BPYHFB")
#' embarques <- get_dataset("https://doi.org/10.60873/FK2/BPYHFB")
#'
#' # Pick one year from a multi-year dataset
#' pemob_2023 <- get_dataset("pemob_anual", year = 2023)
#'
#' # Request a file by exact name, or by regex
#' linhas <- get_dataset("estacoes_motiva", filename = "dim_line.rds")
#' estacoes <- get_dataset("estacoes_motiva", file_pattern = "^dim_station")
#'
#' # Return the data with its documentation
#' result <- get_dataset("embarques_mensais", docs = TRUE)
#' result$docs
#'
#' @examplesIf live_examples() && requireNamespace("sf", quietly = TRUE)
#' # Spatial datasets return an sf object
#' faixa_azul <- get_dataset("faixa_azul_sp")
get_dataset <- function(
  dataset,
  year = NULL,
  filename = NULL,
  file_pattern = NULL,
  docs = FALSE
) {
  doi <- resolve_dataset(dataset)
  doi_url <- doi_to_url(doi)
  server <- insper_server()
  entry <- registry_entry(dataset)

  spatial <- isTRUE(entry[["is_spatial"]])
  if (spatial && !rlang::is_installed("sf")) {
    cli::cli_warn(c(
      "Dataset {.val {dataset}} contains spatial data.",
      "i" = "Install {.pkg sf} to read it as an {.cls sf} object.",
      "i" = "Falling back to a non-spatial format."
    ))
  }

  cli::cli_inform(c("i" = "Fetching file list for {.val {doi}}"))
  files <- dataverse::dataset_files(doi_url, server = server)
  file_names <- vapply(files, function(f) f[["label"]], character(1))

  # Several aliases can share one deposit (PEMOB, Maré). The registry pattern
  # narrows the deposit to the files that belong to this alias before any
  # user-supplied selector is applied.
  own_pattern <- entry[["file_pattern"]]
  if (!is.null(own_pattern) && is.null(filename)) {
    keep <- grepl(own_pattern, file_names, perl = TRUE)
    if (!any(keep)) {
      cli::cli_abort(c(
        paste0(
          "No files in {.val {doi}} matched the registry pattern for ",
          "{.val {dataset}}."
        ),
        "i" = "The deposit may have been restructured; please report this.",
        "i" = "Files present: {.val {file_names}}"
      ))
    }
    file_names <- file_names[keep]
  }

  target <- select_dv_file(
    file_names,
    year = year,
    filename = filename,
    file_pattern = file_pattern,
    prefer = format_priority(spatial)
  )
  ftype <- detect_file_type(target)

  cli::cli_inform(c("i" = "Downloading {.val {target}}"))
  data <- read_dv_file(target, doi_url, server, ftype)
  attr(data, "doi") <- doi

  if (!docs) {
    return(data)
  }

  # Prefer a "documentacao*.xlsx" file in the dataset over Dataverse metadata.
  all_names <- vapply(files, function(f) f[["label"]], character(1))
  doc_file <- all_names[
    grepl("^documenta", all_names, ignore.case = TRUE) &
      tools::file_ext(tolower(all_names)) %in% c("xlsx", "xls")
  ]

  if (length(doc_file) > 0) {
    cli::cli_inform(c(
      "i" = "Loading documentation from {.val {doc_file[[1]]}}"
    ))
    rlang::check_installed("readxl", reason = "to read documentation files")
    raw <- dataverse::get_file_by_name(
      doc_file[[1]],
      dataset = doi_url,
      server = server
    )
    ext <- tools::file_ext(tolower(doc_file[[1]]))
    tmp <- tempfile(fileext = paste0(".", ext))
    on.exit(unlink(tmp), add = TRUE)
    writeBin(raw, tmp)
    docs_out <- readxl::read_excel(tmp)
  } else {
    cli::cli_inform(c("i" = "Fetching documentation from Dataverse metadata"))
    meta <- dataverse::get_dataset(doi_url, server = server)
    fields <- meta$metadataBlocks$citation$fields
    docs_out <- list(
      title = extract_field(fields, "title"),
      description = extract_description(fields),
      authors = extract_authors(fields),
      doi = doi,
      url = paste0("https://doi.org/", doi),
      year = extract_year(meta)
    )
  }

  list(data = data, docs = docs_out)
}
