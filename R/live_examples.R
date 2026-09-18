#' Decide whether examples that download data should run
#'
#' Used in `@examplesIf` so examples hit Insper Dataverse only when that is
#' safe. They run during `devtools::check()`, `devtools::run_examples()`, and
#' pkgdown builds, and are skipped on CRAN, offline, or when the server is
#' down.
#'
#' @param timeout Seconds to wait for the server to answer.
#'
#' @return `TRUE` when the `NOT_CRAN` or `IN_PKGDOWN` environment variable is
#'   `"true"` and the Dataverse API answers, `FALSE` otherwise. Always `FALSE`
#'   when the curl package is not installed.
#'
#' @keywords internal
#' @export
#' @examples
#' live_examples()
live_examples <- function(timeout = 5) {
  not_cran <- identical(Sys.getenv("NOT_CRAN"), "true") ||
    identical(Sys.getenv("IN_PKGDOWN"), "true")
  if (!not_cran || !requireNamespace("curl", quietly = TRUE)) {
    return(FALSE)
  }
  url <- paste0("https://", insper_server(), "/api/info/version")
  handle <- curl::new_handle(timeout = timeout, connecttimeout = timeout)
  res <- tryCatch(
    curl::curl_fetch_memory(url, handle = handle),
    error = function(e) NULL
  )
  return(!is.null(res) && res$status_code == 200)
}
