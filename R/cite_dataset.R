#' Generate a citation for a dataset
#'
#' Fetches metadata from Insper Dataverse and returns a formatted citation.
#' The citation is printed to the console and returned invisibly as a character
#' string.
#'
#' @param dataset A dataset identifier: alias, bare DOI, or DOI URL
#'   (see [get_dataset()] for details).
#' @param format Citation format. One of `"text"` (default), `"bibtex"`,
#'   or `"ris"`.
#'
#' @return A character string containing the formatted citation (invisible).
#'
#' @export
#' @examplesIf live_examples()
#' # Plain-text citation
#' cite_dataset("pemob_anual")
#'
#' # BibTeX
#' cite_dataset("pemob_anual", format = "bibtex")
#'
#' # RIS (Zotero, Mendeley, EndNote)
#' cite_dataset("pemob_anual", format = "ris")
cite_dataset <- function(dataset, format = c("text", "bibtex", "ris")) {
  format <- match.arg(format)
  doi <- resolve_dataset(dataset)

  cli::cli_inform(c("i" = "Fetching metadata for {.val {doi}}"))
  meta <- dataverse::get_dataset(doi_to_url(doi), server = insper_server())

  fields <- meta$metadataBlocks$citation$fields
  title <- extract_field(fields, "title")
  year <- extract_year(meta)
  authors <- extract_authors(fields)
  doi_url <- paste0("https://doi.org/", doi)

  citation <- switch(
    format,
    text = format_text(authors, year, title, doi_url),
    bibtex = format_bibtex(authors, year, title, doi),
    ris = format_ris(authors, year, title, doi_url)
  )

  cli::cli_verbatim(citation)
  invisible(citation)
}

# ── Formatters ────────────────────────────────────────────────────────────────

format_text <- function(authors, year, title, doi_url) {
  paste0(authors, " (", year, "). ", title, ". Insper Dataverse. ", doi_url)
}

format_bibtex <- function(authors, year, title, doi) {
  key <- paste0(
    gsub("[^A-Za-z]", "", strsplit(authors, "[,;]")[[1]][1]),
    year
  )
  paste0(
    "@dataset{",
    key,
    ",\n",
    "  author    = {",
    authors,
    "},\n",
    "  title     = {",
    title,
    "},\n",
    "  year      = {",
    year,
    "},\n",
    "  publisher = {Insper Dataverse},\n",
    "  doi       = {",
    doi,
    "}\n",
    "}"
  )
}

format_ris <- function(authors, year, title, doi_url) {
  author_lines <- paste0(
    "AU  - ",
    strsplit(authors, "; *")[[1]],
    collapse = "\n"
  )
  paste0(
    "TY  - DATA\n",
    author_lines,
    "\n",
    "TI  - ",
    title,
    "\n",
    "PY  - ",
    year,
    "\n",
    "PB  - Insper Dataverse\n",
    "DO  - ",
    doi_url,
    "\n",
    "ER  -"
  )
}

# ── Metadata extractors ───────────────────────────────────────────────────────

# `fields` is the data frame at `metadataBlocks$citation$fields` returned by
# dataverse::get_dataset(): one row per field, values in a list column.
field_value <- function(fields, type_name) {
  idx <- match(type_name, fields[["typeName"]])
  if (is.na(idx)) {
    return(NULL)
  }
  return(fields[["value"]][[idx]])
}

extract_field <- function(fields, type_name) {
  val <- field_value(fields, type_name)
  if (is.null(val) || length(val) == 0) {
    return(NA_character_)
  }
  return(as.character(val[[1]]))
}

extract_description <- function(fields) {
  val <- field_value(fields, "dsDescription")[["dsDescriptionValue"]][["value"]]
  if (is.null(val) || length(val) == 0) {
    return(NA_character_)
  }
  return(paste(val, collapse = "\n\n"))
}

extract_year <- function(meta) {
  for (date in list(meta[["publicationDate"]], meta[["releaseTime"]])) {
    if (!is.null(date) && nzchar(date)) {
      return(substr(date, 1, 4))
    }
  }
  return(format(Sys.Date(), "%Y"))
}

extract_authors <- function(fields) {
  authors <- field_value(fields, "author")[["authorName"]][["value"]]
  if (is.null(authors) || length(authors) == 0) {
    return("Insper Cidades")
  }
  return(paste(authors, collapse = "; "))
}
