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
#' @examples
#' \dontrun{
#' # Plain-text citation
#' cite_dataset("iptu_sp")
#'
#' # BibTeX
#' cite_dataset("iptu_sp", format = "bibtex")
#'
#' # RIS (Zotero, Mendeley, EndNote)
#' cite_dataset("iptu_sp", format = "ris")
#' }
cite_dataset <- function(dataset, format = c("text", "bibtex", "ris")) {
  format <- match.arg(format)
  doi <- resolve_dataset(dataset)

  cli::cli_inform(c("i" = "Fetching metadata for {.val {doi}}"))
  meta <- dataverse::get_dataset(doi_to_url(doi), server = insper_server())

  fields <- meta$data$latestVersion$metadataBlocks$citation$fields
  title <- extract_field(fields, "title")
  year <- extract_year(meta)
  authors <- extract_authors(fields)
  doi_url <- paste0("https://doi.org/", doi)

  citation <- switch(format,
    text   = format_text(authors, year, title, doi_url),
    bibtex = format_bibtex(authors, year, title, doi),
    ris    = format_ris(authors, year, title, doi_url)
  )

  cli::cli_inform(citation)
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
    "@dataset{", key, ",\n",
    "  author    = {", authors, "},\n",
    "  title     = {", title, "},\n",
    "  year      = {", year, "},\n",
    "  publisher = {Insper Dataverse},\n",
    "  doi       = {", doi, "}\n",
    "}"
  )
}

format_ris <- function(authors, year, title, doi_url) {
  author_lines <- paste0("AU  - ", strsplit(authors, "; *")[[1]], collapse = "\n")
  paste0(
    "TY  - DATA\n",
    author_lines, "\n",
    "TI  - ", title, "\n",
    "PY  - ", year, "\n",
    "PB  - Insper Dataverse\n",
    "DO  - ", doi_url, "\n",
    "ER  -"
  )
}

# ── Metadata extractors ───────────────────────────────────────────────────────

extract_field <- function(fields, type_name) {
  for (f in fields) {
    if (identical(f$typeName, type_name)) {
      val <- f$value
      if (is.list(val)) val <- val[[1]]
      return(as.character(val))
    }
  }
  NA_character_
}

extract_year <- function(meta) {
  pub_date <- meta$data$publicationDate
  if (!is.null(pub_date) && nzchar(pub_date)) {
    return(substr(pub_date, 1, 4))
  }
  release <- meta$data$latestVersion$releaseTime
  if (!is.null(release) && nzchar(release)) {
    return(substr(release, 1, 4))
  }
  format(Sys.Date(), "%Y")
}

extract_authors <- function(fields) {
  for (f in fields) {
    if (identical(f$typeName, "author")) {
      names <- vapply(f$value, function(a) {
        an <- a$authorName
        if (is.list(an)) an$value else as.character(an)
      }, character(1))
      return(paste(names, collapse = "; "))
    }
  }
  "Insper Cidades"
}
