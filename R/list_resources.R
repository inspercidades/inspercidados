#' List a dataset's logical resources
#'
#' Returns the logical resources registered within a dataset. A resource is one
#' dataset that may be distributed in several file formats or split by a
#' declared dimension such as year. The information comes from the local
#' registry, so no network call is made.
#'
#' @param dataset A registered dataset alias. See [list_datasets()].
#'
#' @return A [tibble][tibble::tibble] with one row per resource and columns
#'   `resource`, `title`, `is_spatial`, `years`, `formats`, and `default`.
#'
#' @seealso [get_dataset()] to download a resource.
#'
#' @export
#' @examples
#' list_resources("qualidade_ar_mare")
#' list_resources("pemob_anual")
list_resources <- function(dataset) {
  entry <- registry_entry(dataset)
  if (is.null(entry)) {
    cli::cli_abort(c(
      "{.fn list_resources} requires a registered dataset alias.",
      "i" = "Run {.run list_datasets()} to see available aliases."
    ))
  }
  resolve_dataset(dataset)
  resources <- entry[["resources"]]

  out <- tibble::tibble(
    resource = names(resources),
    title = unname(vapply(resources, `[[`, character(1), "title")),
    is_spatial = unname(vapply(
      resources,
      function(x) isTRUE(x[["is_spatial"]]),
      logical(1)
    )),
    years = unname(vapply(
      resources,
      function(x) paste(unlist(x[["years"]]), collapse = ", "),
      character(1)
    )),
    formats = unname(vapply(
      resources,
      function(x) paste(unlist(x[["formats"]]), collapse = ", "),
      character(1)
    )),
    default = unname(vapply(
      resources,
      function(x) isTRUE(x[["default"]]),
      logical(1)
    ))
  )
  out$years[!nzchar(out$years)] <- NA_character_
  out
}
