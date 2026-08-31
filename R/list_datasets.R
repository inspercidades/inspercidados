#' List available datasets
#'
#' Returns a tibble of datasets in the `inspercidados` registry. Data comes
#' from the local registry (`inst/datasets.json`), so no network call is made.
#'
#' @param search A character string to filter results. Matched case-insensitively
#'   against alias, title, description, keywords, theme, and region. Pass `NULL`
#'   (default) to return all datasets.
#' @param theme,region,project Optional filters, matched case-insensitively as
#'   regular expressions against the corresponding column.
#' @param spatial Logical. If `TRUE`, keep only datasets that ship a GeoPackage
#'   or GeoJSON. If `FALSE`, drop them. `NULL` (default) keeps both.
#' @param include Which registry entries to return. `"active"` (default) lists
#'   datasets you can download. `"catalogued"` adds entries held in Insper's
#'   secure data room, which appear with `access = "secure_room"` and cannot be
#'   downloaded. `"all"` also includes retired aliases.
#'
#' @return A [tibble][tibble::tibble] with one row per dataset and columns
#'   `alias`, `title`, `description`, `theme`, `region`, `project`, `access`,
#'   `is_spatial`, `formats`, `keywords`, and `doi`.
#'
#' @seealso [list_projects()] for the studies these datasets come from.
#'
#' @export
#' @examples
#' # List all downloadable datasets
#' list_datasets()
#'
#' # Search by keyword or theme
#' list_datasets("metro")
#' list_datasets("IPTU")
#'
#' # Only spatial datasets
#' list_datasets(spatial = TRUE)
#'
#' # Datasets from one study
#' list_datasets(project = "faixa_azul")
#'
#' # Include datasets that are catalogued but not downloadable
#' list_datasets(include = "catalogued")
list_datasets <- function(search = NULL,
                          theme = NULL,
                          region = NULL,
                          project = NULL,
                          spatial = NULL,
                          include = c("active", "catalogued", "all")) {
  include <- match.arg(include)
  reg <- read_registry()

  keep_status <- switch(include,
    active     = "active",
    catalogued = c("active", "unpublished"),
    all        = c("active", "unpublished", "retired")
  )
  reg <- Filter(function(x) (x[["status"]] %||% "active") %in% keep_status, reg)

  chr <- function(field) {
    vapply(reg, function(x) x[[field]] %||% NA_character_, character(1))
  }

  out <- tibble::tibble(
    alias       = names(reg),
    title       = chr("title"),
    description = chr("description"),
    theme       = chr("theme"),
    region      = chr("region"),
    project     = chr("project"),
    access      = chr("access"),
    is_spatial  = vapply(reg, function(x) isTRUE(x[["is_spatial"]]), logical(1)),
    formats     = vapply(
      reg,
      function(x) paste(unlist(x[["formats"]]), collapse = ", "),
      character(1)
    ),
    keywords    = chr("keywords"),
    doi         = chr("doi")
  )
  out$formats[!nzchar(out$formats)] <- NA_character_

  if (!is.null(search)) {
    cols <- c("alias", "title", "description", "theme", "region", "keywords")
    hits <- lapply(cols, function(col) {
      grepl(search, out[[col]], ignore.case = TRUE) & !is.na(out[[col]])
    })
    out <- out[Reduce(`|`, hits), ]
  }

  out <- filter_col(out, "theme", theme)
  out <- filter_col(out, "region", region)
  out <- filter_col(out, "project", project)

  if (!is.null(spatial)) {
    out <- out[out$is_spatial == isTRUE(spatial), ]
  }

  if (nrow(out) == 0) {
    cli::cli_inform("No datasets matched.")
  }

  out
}

#' @keywords internal
#' @noRd
filter_col <- function(out, column, value) {
  if (is.null(value)) {
    return(out)
  }
  keep <- grepl(value, out[[column]], ignore.case = TRUE) & !is.na(out[[column]])
  out[keep, ]
}
