#' Open or download the R script for a dataset
#'
#' @description
#' `r lifecycle::badge("deprecated")`
#'
#' `get_script()` assumed one R script per dataset. Most datasets come from a
#' study whose pipeline spans many files, and several studies publish more than
#' one dataset, so scripts are now published as repositories.
#' Use [browse_project()] instead.
#'
#' @param dataset A dataset alias.
#' @param type Ignored.
#' @param open Passed to [browse_project()].
#'
#' @return The repository URL, invisibly.
#'
#' @keywords internal
#' @export
#' @examples
#' # Deprecated; use browse_project() instead.
#' browse_project("sinistros_sp", open = FALSE)
get_script <- function(dataset, type = NULL, open = TRUE) {
  cli::cli_warn(c(
    "!" = "{.fn get_script} is deprecated.",
    "i" = "Pipelines are published as repositories, not single scripts.",
    "v" = "Use {.fn browse_project} instead."
  ))
  browse_project(dataset, open = open)
}
