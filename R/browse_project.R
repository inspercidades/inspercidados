#' Deprecated alias for open_project()
#'
#' @description
#' `r lifecycle::badge("soft-deprecated")`
#'
#' `browse_project()` was renamed to [open_project()] to avoid the name
#' conflict with `usethis::browse_project()`. It now forwards to
#' [open_project()] and will be removed in a future release.
#'
#' @param x A study, dataset alias.
#' @param open Passed to [open_project()].
#'
#' @return The repository URL, invisibly.
#'
#' @keywords internal
#' @export
#' @examples
#' # Deprecated; use open_project() instead.
#' open_project("sinistros_sp", open = FALSE)
browse_project <- function(x, open = TRUE) {
  cli::cli_warn(c(
    "!" = "{.fn browse_project} is soft-deprecated.",
    "v" = "Use {.fn open_project} instead."
  ))
  open_project(x, open = open)
}
