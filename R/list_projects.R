#' List the studies behind the datasets
#'
#' Each dataset comes from a research project with its own processing pipeline.
#' One project usually produces several datasets, so pipelines are published as
#' whole repositories rather than as a single script per dataset.
#'
#' @param project Optional project slug or regular expression to filter on.
#'
#' @return A [tibble][tibble::tibble] with columns `project`, `title`,
#'   `repo_url`, `visibility`, `n_datasets`, and `datasets`. `repo_url` is `NA`
#'   for projects whose code has not been published yet, and `visibility` is
#'   `"private"` for repositories that only Insper Cidades members can open.
#'
#' @seealso [browse_project()] to open a repository, [list_datasets()] for the
#'   datasets themselves.
#'
#' @export
#' @examples
#' list_projects()
#' list_projects("motiva")
list_projects <- function(project = NULL) {
  proj <- read_projects()

  out <- tibble::tibble(
    project = names(proj),
    title = vapply(
      proj,
      function(x) x[["title"]] %||% NA_character_,
      character(1)
    ),
    repo_url = vapply(
      proj,
      function(x) x[["repo_url"]] %||% NA_character_,
      character(1)
    ),
    visibility = vapply(
      proj,
      function(x) x[["visibility"]] %||% NA_character_,
      character(1)
    ),
    n_datasets = vapply(proj, function(x) length(x[["datasets"]]), integer(1)),
    datasets = vapply(
      proj,
      function(x) paste(unlist(x[["datasets"]]), collapse = ", "),
      character(1)
    )
  )

  if (!is.null(project)) {
    keep <- grepl(project, out$project, ignore.case = TRUE) |
      grepl(project, out$title, ignore.case = TRUE)
    out <- out[keep, ]
    if (nrow(out) == 0) {
      cli::cli_inform("No projects matched {.val {project}}.")
    }
  }

  out
}
