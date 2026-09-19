#' Open the study behind a dataset
#'
#' Prints the study a dataset came from, the other datasets it produced, and
#' the repository holding its processing code, then opens that repository in a
#' browser.
#'
#' Pipelines are published as repositories rather than as single scripts,
#' because one study normally produces several datasets across many files.
#' Some repositories are private and open only for Insper Cidades members;
#' [list_projects()] reports which.
#'
#' @param x A dataset alias (see [list_datasets()]) or a project slug (see
#'   [list_projects()]).
#' @param open Logical. If `TRUE` (default), open the repository in a browser
#'   when one is registered and the session is interactive.
#'
#' @return The repository URL, invisibly, or `NULL` when no repository is
#'   registered for the project.
#'
#' @export
#' @examples
#' # By dataset alias
#' open_project("sinistros_sp", open = FALSE)
#'
#' # By project slug
#' open_project("motiva", open = FALSE)
open_project <- function(x, open = TRUE) {
  proj <- read_projects()
  reg <- read_registry()

  slug <- if (x %in% names(proj)) {
    x
  } else if (x %in% names(reg)) {
    reg[[x]][["project"]]
  } else {
    cli::cli_abort(c(
      "{.val {x}} is neither a dataset alias nor a project slug.",
      "i" = paste0(
        "Run {.run inspercidados::list_datasets()} or ",
        "{.run inspercidados::list_projects()}."
      )
    ))
  }

  if (is.null(slug) || is.na(slug) || !slug %in% names(proj)) {
    cli::cli_abort(c(
      "No project is registered for {.val {x}}.",
      "i" = paste0(
        "Run {.run inspercidados::list_projects()} to see the studies ",
        "available."
      )
    ))
  }

  entry <- proj[[slug]]
  datasets <- unlist(entry[["datasets"]])
  repo <- entry[["repo_url"]]

  cli::cli_h1(entry[["title"]] %||% slug)
  cli::cli_text("{.strong Project}: {.val {slug}}")
  if (length(datasets)) {
    cli::cli_text("{.strong Datasets}: {.val {datasets}}")
  }

  if (is.null(repo)) {
    cli::cli_alert_info(
      "The processing code for this study is not published yet."
    )
    return(invisible(NULL))
  }

  cli::cli_text("{.strong Repository}: {.url {repo}}")

  if (identical(entry[["visibility"]], "private")) {
    cli::cli_alert_warning(c(
      paste0(
        "This repository is private. Opening it needs an Insper Cidades ",
        "GitHub account."
      )
    ))
  }

  if (open && interactive()) {
    utils::browseURL(repo)
  }

  invisible(repo)
}
