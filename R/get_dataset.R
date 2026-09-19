#' Download a dataset from Insper Dataverse
#'
#' Downloads a registered dataset into R as a tibble or `sf` object. Identify
#' the dataset by its short alias; use [get_dataverse()] for a DOI or URL.
#'
#' A Dataverse deposit may contain several logical resources, each distributed
#' in several formats. Use `resource` to select the logical dataset and
#' `format` to select its representation. Deposits with one resource, or a
#' declared default, need neither argument.
#'
#' When `format` is omitted, spatial resources prefer GeoPackage and GeoJSON;
#' other resources prefer RDS, Parquet, delimited text, and Excel. Formats that
#' need an uninstalled suggested package are skipped.
#'
#' @param dataset A dataset identifier. One of:
#'   A short alias, e.g. `"iptu_sp"`. See [list_datasets()] for all aliases.
#' @param ... Reserved for future selectors. Must be empty.
#' @param resource The name of a logical resource within the registered
#'   dataset. When `NULL`, the resource marked as the default is used. See
#'   [list_resources()] for the available names.
#' @param year An integer or character year used to filter files when a dataset
#'   contains multiple annual files (e.g. `year = 2023`).
#' @param format An optional file format, such as `"parquet"`, `"gpkg"`, or
#'   `"xlsx"`. The format must be available for the selected resource.
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
#' # Pick one year from a multi-year dataset
#' pemob_2023 <- get_dataset("pemob_anual", year = 2023)
#'
#' # Pick a resource and an explicit format
#' pontos <- get_dataset(
#'   "qualidade_ar_mare",
#'   resource = "pontos",
#'   format = "gpkg"
#' )
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
  ...,
  resource = NULL,
  year = NULL,
  format = NULL,
  docs = FALSE
) {
  rlang::check_dots_empty()
  entry <- registry_entry(dataset)
  if (is.null(entry)) {
    cli::cli_abort(c(
      "{.fn get_dataset} requires a registered dataset alias.",
      "i" = "Use {.fn get_dataverse} to download a DOI or Dataverse URL."
    ))
  }
  doi <- resolve_dataset(dataset)
  doi_url <- doi_to_url(doi)
  server <- insper_server()
  resources <- entry[["resources"]]
  resource <- resolve_resource_name(entry, dataset, resource)
  definition <- resources[[resource]]
  if (
    !is.null(year) &&
      (!is.atomic(year) || length(year) != 1 || is.na(year))
  ) {
    cli::cli_abort("{.arg year} must be a single value or {.code NULL}.")
  }

  spatial <- isTRUE(definition[["is_spatial"]])
  if (spatial && is.null(format) && !rlang::is_installed("sf")) {
    cli::cli_warn(c(
      "Dataset {.val {dataset}} contains spatial data.",
      "i" = "Install {.pkg sf} to read it as an {.cls sf} object.",
      "i" = "Falling back to a non-spatial format."
    ))
  }

  cli::cli_inform(c("i" = "Fetching file list for {.val {doi}}"))
  files <- dataverse::dataset_files(doi_url, server = server)
  file_names <- vapply(files, function(f) f[["label"]], character(1))

  own_pattern <- definition[["file_pattern"]]
  keep <- grepl(own_pattern, file_names, perl = TRUE)
  if (!any(keep)) {
    cli::cli_abort(c(
      "No files in {.val {doi}} matched resource {.val {resource}}.",
      "i" = "The deposit may have been restructured; please report this.",
      "i" = "Files present: {.val {file_names}}"
    ))
  }
  file_names <- file_names[keep]

  resource_formats <- unlist(definition[["formats"]], use.names = FALSE)
  if (!is.null(format)) {
    if (!is.character(format) || length(format) != 1 || is.na(format)) {
      cli::cli_abort("{.arg format} must be a single string or {.code NULL}.")
    }
    format <- tolower(format)
    if (!format %in% resource_formats) {
      cli::cli_abort(c(
        paste0(
          "Format {.val {format}} is not available for resource ",
          "{.val {resource}}."
        ),
        "i" = "Available formats: {.val {resource_formats}}"
      ))
    }
  }
  file_names <- filter_dv_format(file_names, format)

  target <- select_dv_file(
    file_names,
    year = year,
    prefer = format %||% format_priority(spatial),
    strict = TRUE
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
  documentation_pattern <- definition[["documentation_pattern"]]
  if (!is.null(documentation_pattern)) {
    doc_file <- doc_file[grepl(documentation_pattern, doc_file, perl = TRUE)]
  }

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

  return(list(data = data, docs = docs_out))
}
