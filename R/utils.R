# Internal helpers — not exported

.ext_map <- c(
  rds = "rds",
  csv = "csv",
  tab = "tab",
  tsv = "tab",
  parquet = "parquet",
  pq = "parquet",
  gpkg = "gpkg",
  geojson = "geojson",
  json = "geojson",
  xlsx = "xlsx",
  xls = "xlsx"
)

# Inner extension (after stripping .gz) -> file type
.gz_ext_map <- c(csv = "csv_gz", tab = "tab_gz", tsv = "tab_gz")

insper_server <- function() {
  "dataverse.datascience.insper.edu.br"
}

# Registry -------------------------------------------------------------------

# The registry is read from GitHub so datasets added after a release reach
# users without reinstalling. The copy shipped in inst/ is the fallback.
# Bump the schema version only when older code would misread the files;
# data-raw/build_registry.R writes the same number.
registry_schema_version <- 1L

# File name -> field that holds its entries.
.registry_fields <- c(
  "datasets.json" = "datasets",
  "projects.json" = "projects"
)

.registry_cache <- new.env(parent = emptyenv())

registry_url <- function(file) {
  paste0(
    "https://raw.githubusercontent.com/inspercidades/inspercidados/main/inst/",
    file
  )
}

# "remote" unless the user opts out or R CMD check is running, so checks,
# tests, and CRAN examples stay offline.
registry_source <- function() {
  source <- getOption("inspercidados.registry")
  if (!is.null(source)) {
    return(rlang::arg_match0(
      source,
      c("remote", "bundled"),
      arg_nm = "inspercidados.registry"
    ))
  }
  if (nzchar(Sys.getenv("_R_CHECK_PACKAGE_NAME_"))) {
    return("bundled")
  }
  return("remote")
}

read_json_asset <- function(file) {
  return(registry_files(registry_source())[[file]])
}

registry_files <- function(source) {
  cached <- .registry_cache[[source]]
  if (!is.null(cached)) {
    return(cached)
  }
  out <- NULL
  if (identical(source, "remote")) {
    out <- read_remote_registry()
  }
  out <- out %||% read_bundled_registry()
  assign(source, out, envir = .registry_cache)
  return(out)
}

# Both files or neither, so projects never point at aliases the datasets file
# lacks.
read_remote_registry <- function() {
  out <- list()
  for (file in names(.registry_fields)) {
    entries <- unwrap_registry(fetch_registry_file(file), file)
    if (is.null(entries)) {
      return(NULL)
    }
    out[[file]] <- entries
  }
  return(out)
}

read_bundled_registry <- function() {
  out <- list()
  for (file in names(.registry_fields)) {
    path <- system.file(file, package = "inspercidados")
    entries <- if (nzchar(path)) {
      unwrap_registry(jsonlite::read_json(path), file)
    }
    if (is.null(entries)) {
      cli::cli_abort(paste0(
        "Package data registry {.file {file}} is missing or unreadable. ",
        "Try reinstalling the package."
      ))
    }
    out[[file]] <- entries
  }
  return(out)
}

fetch_registry_file <- function(file, timeout = 3) {
  if (!requireNamespace("curl", quietly = TRUE)) {
    return(NULL)
  }
  handle <- curl::new_handle(timeout = timeout, connecttimeout = timeout)
  tryCatch(
    {
      res <- curl::curl_fetch_memory(registry_url(file), handle = handle)
      if (res$status_code == 200) {
        jsonlite::parse_json(rawToChar(res$content))
      }
    },
    error = function(e) NULL
  )
}

# Entries of a parsed registry file, or NULL when the file is malformed or
# uses a schema this version does not know.
unwrap_registry <- function(x, file) {
  version <- if (is.list(x)) x[["schema_version"]]
  entries <- if (is.list(x)) x[[.registry_fields[[file]]]]
  valid <- is.numeric(version) &&
    length(version) == 1 &&
    version <= registry_schema_version &&
    is.list(entries)
  if (!valid) {
    return(NULL)
  }
  return(mark_utf8(entries))
}

# jsonlite decodes \uXXXX escapes but leaves strings marked "unknown".
# Tag each string as UTF-8 so R displays it correctly in any locale.
mark_utf8 <- function(x) {
  if (is.character(x)) {
    Encoding(x) <- "UTF-8"
    return(x)
  }
  if (is.list(x)) {
    return(lapply(x, mark_utf8))
  }
  return(x)
}

read_registry <- function() {
  read_json_asset("datasets.json")
}

read_projects <- function() {
  read_json_asset("projects.json")
}

# Registry entries that users can actually download.
active_registry <- function() {
  reg <- read_registry()
  Filter(function(x) identical(x[["status"]], "active"), reg)
}

# Full registry entry for an alias, or NULL when the identifier is a DOI/URL.
registry_entry <- function(x) {
  reg <- read_registry()
  if (!is.character(x) || length(x) != 1 || !x %in% names(reg)) {
    return(NULL)
  }
  reg[[x]]
}

resolve_resource_name <- function(
  entry,
  dataset,
  resource = NULL,
  call = rlang::caller_env()
) {
  resources <- entry[["resources"]]
  resource_names <- names(resources)
  if (
    !is.null(resource) &&
      (!is.character(resource) || length(resource) != 1 || is.na(resource))
  ) {
    cli::cli_abort(
      "{.arg resource} must be a single string or {.code NULL}.",
      call = call
    )
  }
  if (is.null(resource) && length(resource_names) == 1) {
    return(resource_names[[1]])
  }
  if (is.null(resource)) {
    defaults <- resource_names[vapply(
      resources,
      function(x) isTRUE(x[["default"]]),
      logical(1)
    )]
    if (length(defaults) != 1) {
      cli::cli_abort(
        c(
          "Dataset {.val {dataset}} contains several resources.",
          "i" = "Choose one with {.arg resource}: {.val {resource_names}}.",
          "i" = "Run {.run list_resources(\"{dataset}\")} for details."
        ),
        call = call
      )
    }
    return(defaults[[1]])
  }
  if (!resource %in% resource_names) {
    cli::cli_abort(
      c(
        "Resource {.val {resource}} is not available for {.val {dataset}}.",
        "i" = "Available resources: {.val {resource_names}}"
      ),
      call = call
    )
  }
  return(resource)
}

# A retired alias means the deposit moved or was withdrawn. Say which, rather
# than letting the user hit a bare "not found".
abort_retired <- function(alias, entry) {
  successor <- entry[["superseded_by"]]
  msg <- c("Dataset {.val {alias}} is no longer available.")
  if (!is.null(entry[["reason"]])) {
    msg <- c(msg, "i" = entry[["reason"]])
  }
  if (!is.null(successor)) {
    msg <- c(msg, "v" = "Use {.val {successor}} instead.")
  } else {
    msg <- c(
      msg,
      "i" = "Run {.run inspercidados::list_datasets()} to see current datasets."
    )
  }
  cli::cli_abort(msg)
}

#' @noRd
resolve_dataset <- function(x) {
  if (!is.character(x) || length(x) != 1 || is.na(x) || !nzchar(x)) {
    cli::cli_abort("{.arg dataset} must be a single non-empty string.")
  }

  # Covers https://doi.org/10.60873/..., the Dataverse landing page
  # (?persistentId=doi:10.60873/...), and a bare doi: prefix.
  if (grepl("^https?://", x) || grepl("^doi:", x, ignore.case = TRUE)) {
    m <- regmatches(x, regexpr("10\\.60873/[A-Za-z0-9._/-]+", x, perl = TRUE))
    if (length(m) == 0 || !nzchar(m)) {
      cli::cli_abort(c(
        "Could not extract an Insper Dataverse DOI from {.url {x}}.",
        "i" = "Expected a DOI under the {.val 10.60873} prefix."
      ))
    }
    return(sub("[/&#?]+$", "", m))
  }
  if (grepl("^10\\.", x)) {
    if (!grepl("^10\\.60873/", x)) {
      cli::cli_abort(c(
        "{.val {x}} is not an Insper Dataverse DOI.",
        "i" = "This package only serves DOIs under the {.val 10.60873} prefix."
      ))
    }
    return(x)
  }

  reg <- read_registry()
  if (!x %in% names(reg)) {
    cli::cli_abort(c(
      "Dataset {.val {x}} not found.",
      "i" = paste0(
        "Run {.run inspercidados::list_datasets()} to see available ",
        "datasets."
      ),
      "i" = "You can also pass a DOI directly, e.g. {.val 10.60873/FK2/TOXCRF}."
    ))
  }

  entry <- reg[[x]]
  if (identical(entry[["status"]], "retired")) {
    abort_retired(x, entry)
  }
  if (identical(entry[["status"]], "unpublished")) {
    cli::cli_abort(c(
      "Dataset {.val {x}} is catalogued but not published for download.",
      "i" = "Access runs through Insper's secure data room.",
      "i" = paste0(
        "See {.url https://www.insper.edu.br/cidades} for how to ",
        "request it."
      )
    ))
  }
  entry[["doi"]]
}

doi_to_url <- function(doi) {
  paste0("https://doi.org/", doi)
}

detect_file_type <- function(filename) {
  ext <- tolower(tools::file_ext(filename))
  if (ext == "gz") {
    inner <- tolower(tools::file_ext(sub(
      "\\.gz$",
      "",
      filename,
      ignore.case = TRUE
    )))
    if (inner %in% names(.gz_ext_map)) {
      return(.gz_ext_map[[inner]])
    }
    return("gz")
  }
  if (ext %in% names(.ext_map)) {
    return(.ext_map[[ext]])
  }
  return("unknown")
}

# Vectorised: returns the effective (innermost) extension for each filename.
effective_ext <- function(filenames) {
  return(unname(tolower(tools::file_ext(sub(
    "[.]gz$",
    "",
    filenames,
    ignore.case = TRUE
  )))))
}

filter_dv_format <- function(file_names, format = NULL) {
  if (is.null(format)) {
    return(file_names)
  }
  return(file_names[effective_ext(file_names) == format])
}

# Preferred download format, in order. Spatial deposits resolve to gpkg so the
# result is an sf object; everything else favours typed formats over text.
format_priority <- function(is_spatial = FALSE) {
  parquet <- if (rlang::is_installed("arrow")) "parquet" else character(0)
  spatial <- if (rlang::is_installed("sf")) {
    c("gpkg", "geojson")
  } else {
    character(0)
  }
  if (isTRUE(is_spatial)) {
    c(spatial, "rds", parquet, "tab", "csv", "xlsx")
  } else {
    c("rds", parquet, "tab", "csv", spatial, "xlsx")
  }
}

DATA_EXTS <- c(
  "rds",
  "csv",
  "tab",
  "tsv",
  "parquet",
  "pq",
  "gpkg",
  "geojson",
  "xlsx",
  "xls"
)

# Select a file from those available in the dataset.
# `prefer` is a vector of extensions in priority order; the first extension
# with a matching file wins.
select_dv_file <- function(
  file_names,
  year = NULL,
  filename = NULL,
  file_pattern = NULL,
  prefer = NULL,
  strict = FALSE
) {
  if (!is.character(file_names) || anyNA(file_names)) {
    cli::cli_abort(
      "{.arg file_names} must be a character vector without missing values."
    )
  }
  if (
    !is.null(filename) &&
      (!is.character(filename) ||
        length(filename) != 1 ||
        is.na(filename) ||
        !nzchar(filename))
  ) {
    cli::cli_abort(
      "{.arg filename} must be a single non-empty string or {.code NULL}."
    )
  }
  if (
    !is.null(file_pattern) &&
      (!is.character(file_pattern) ||
        length(file_pattern) != 1 ||
        is.na(file_pattern) ||
        !nzchar(file_pattern))
  ) {
    cli::cli_abort(
      "{.arg file_pattern} must be a single non-empty string or {.code NULL}."
    )
  }
  if (!is.null(file_pattern)) {
    valid_pattern <- tryCatch(
      {
        suppressWarnings(grepl(file_pattern, "", perl = TRUE))
        TRUE
      },
      error = function(e) FALSE
    )
    if (!valid_pattern) {
      cli::cli_abort("{.arg file_pattern} must be a valid regular expression.")
    }
  }
  if (
    !is.null(year) &&
      (!is.atomic(year) || length(year) != 1 || is.na(year))
  ) {
    cli::cli_abort("{.arg year} must be a single value or {.code NULL}.")
  }

  if (!is.null(filename)) {
    if (!filename %in% file_names) {
      cli::cli_abort(c(
        "File {.val {filename}} not found in this deposit.",
        "i" = "Available files: {.val {file_names}}"
      ))
    }
    return(filename)
  }

  candidates <- file_names[effective_ext(file_names) %in% DATA_EXTS]

  if (length(candidates) == 0) {
    cli::cli_abort(c(
      "No data files found in this deposit.",
      "i" = "All files: {.val {file_names}}"
    ))
  }

  # Documentation workbooks share the deposit with the data and must never be
  # returned as the dataset itself. A deposit holding nothing else has no data
  # to return, so say that instead of handing back a documentation sheet.
  is_doc <- grepl(
    "^(documenta|metadados|readme|metodologia)",
    candidates,
    ignore.case = TRUE
  )
  if (all(is_doc)) {
    cli::cli_abort(c(
      "This deposit contains only documentation files, no data.",
      "i" = "Files present: {.val {candidates}}",
      "i" = "Pass {.arg filename} to download one of them anyway."
    ))
  }
  candidates <- candidates[!is_doc]

  if (!is.null(file_pattern)) {
    m <- grepl(file_pattern, candidates, perl = TRUE)
    if (!any(m)) {
      cli::cli_abort(c(
        "No files matched pattern {.val {file_pattern}}.",
        "i" = "Available data files: {.val {candidates}}"
      ))
    }
    candidates <- candidates[m]
  }

  if (!is.null(year)) {
    m <- grepl(as.character(year), candidates, fixed = TRUE)
    if (!any(m)) {
      cli::cli_abort(c(
        "No files matched {.arg year} {.val {year}}.",
        "i" = "Available data files: {.val {candidates}}"
      ))
    }
    candidates <- candidates[m]
  }

  if (length(candidates) == 1) {
    return(candidates)
  }

  prefer <- prefer %||% format_priority(FALSE)
  exts <- effective_ext(candidates)
  for (ext in prefer) {
    hit <- candidates[exts == ext]
    if (length(hit) == 0) {
      next
    }
    if (length(hit) > 1) {
      if (strict) {
        cli::cli_abort(c(
          "Multiple files remain after applying the dataset selectors.",
          "i" = paste0(
            "Use {.arg year}, {.arg resource}, or {.arg format} to be ",
            "more specific."
          ),
          "i" = "Matched files: {.val {hit}}"
        ))
      }
      cli::cli_warn(c(
        "Multiple {.val {ext}} files found; using {.val {hit[[1]]}}.",
        "i" = paste0(
          "Use {.arg filename}, {.arg year}, or {.arg file_pattern} to be ",
          "specific."
        ),
        "i" = "Matched files: {.val {hit}}"
      ))
    }
    return(hit[[1]])
  }

  if (strict) {
    cli::cli_abort(c(
      "No file matched the requested or readable formats.",
      "i" = "Available files: {.val {candidates}}"
    ))
  }

  cli::cli_warn(c(
    "No file matched the preferred formats; using {.val {candidates[[1]]}}.",
    "i" = "Available files: {.val {candidates}}"
  ))
  candidates[[1]]
}

read_binary_dv_file <- function(filename, doi_url, server, reader) {
  raw <- dataverse::get_file_by_name(
    filename,
    dataset = doi_url,
    server = server
  )
  tmp <- tempfile(fileext = paste0(".", tools::file_ext(filename)))
  on.exit(unlink(tmp), add = TRUE)
  writeBin(raw, tmp)
  return(reader(tmp))
}

.readers <- list(
  rds = function(filename, doi_url, server) {
    read_binary_dv_file(filename, doi_url, server, readRDS)
  },
  csv = function(filename, doi_url, server) {
    dataverse::get_dataframe_by_name(
      filename,
      dataset = doi_url,
      server = server,
      original = TRUE,
      .f = function(x) readr::read_delim(x, delim = ",", show_col_types = FALSE)
    )
  },
  tab = function(filename, doi_url, server) {
    dataverse::get_dataframe_by_name(
      filename,
      dataset = doi_url,
      server = server,
      original = TRUE,
      .f = function(x) {
        readr::read_delim(x, delim = "\t", show_col_types = FALSE)
      }
    )
  },
  csv_gz = function(filename, doi_url, server) {
    read_binary_dv_file(
      filename,
      doi_url,
      server,
      function(path) {
        readr::read_delim(path, delim = ",", show_col_types = FALSE)
      }
    )
  },
  tab_gz = function(filename, doi_url, server) {
    read_binary_dv_file(
      filename,
      doi_url,
      server,
      function(path) {
        readr::read_delim(path, delim = "\t", show_col_types = FALSE)
      }
    )
  },
  parquet = function(filename, doi_url, server) {
    rlang::check_installed("arrow", reason = "to read Parquet (.parquet) files")
    read_binary_dv_file(filename, doi_url, server, arrow::read_parquet)
  },
  geojson = function(filename, doi_url, server) {
    rlang::check_installed("sf", reason = "to read GeoJSON (.geojson) files")
    read_binary_dv_file(
      filename,
      doi_url,
      server,
      function(path) sf::st_read(path, quiet = TRUE)
    )
  },
  gpkg = function(filename, doi_url, server) {
    rlang::check_installed("sf", reason = "to read GeoPackage (.gpkg) files")
    read_binary_dv_file(
      filename,
      doi_url,
      server,
      function(path) sf::st_read(path, quiet = TRUE)
    )
  },
  xlsx = function(filename, doi_url, server) {
    rlang::check_installed(
      "readxl",
      reason = "to read Excel (.xlsx/.xls) files"
    )
    read_binary_dv_file(filename, doi_url, server, readxl::read_excel)
  }
)

read_dv_file <- function(filename, doi_url, server, ftype) {
  reader <- .readers[[ftype]]
  if (is.null(reader)) {
    cli::cli_abort(c(
      "Unsupported file type {.val {ftype}} for {.val {filename}}.",
      "i" = "Supported types: {.val {names(.readers)}}."
    ))
  }
  reader(filename, doi_url, server)
}

# Null-coalescing operator
`%||%` <- function(x, y) if (is.null(x)) y else x

# readr is called only from the reader list above, which codetools does not
# traverse, so declare the import explicitly.
#' @importFrom readr read_delim
NULL

# DuckDB ---------------------------------------------------------------------

# Dataverse access URLs for the parquet files of one resource. Dataverse
# redirects each URL to a signed S3 link that DuckDB can range-read.
parquet_file_urls <- function(
  files,
  file_pattern,
  year = NULL,
  server = insper_server()
) {
  labels <- vapply(files, function(f) f[["label"]], character(1))
  keep <- grepl(file_pattern, labels, perl = TRUE) &
    effective_ext(labels) %in% c("parquet", "pq")
  if (!is.null(year)) {
    keep <- keep & grepl(as.character(year), labels, fixed = TRUE)
  }
  if (!any(keep)) {
    msg <- if (is.null(year)) {
      "No parquet file matched this resource."
    } else {
      "No parquet file matched this resource for {.arg year} {.val {year}}."
    }
    cli::cli_abort(c(msg, "i" = "Files present: {.val {labels}}"))
  }
  ids <- vapply(files[keep], function(f) f[["dataFile"]][["id"]], numeric(1))
  return(paste0("https://", server, "/api/access/datafile/", ids))
}

read_parquet_sql <- function(urls) {
  quoted <- DBI::dbQuoteString(DBI::ANSI(), urls)
  return(paste0(
    "SELECT * FROM read_parquet([",
    paste(quoted, collapse = ", "),
    "], union_by_name = true)"
  ))
}

.duckdb_cache <- new.env(parent = emptyenv())

# One in-memory DuckDB connection per session. The shared extension cache
# lets httpfs load when its download server is unavailable.
duckdb_connection <- function() {
  con <- .duckdb_cache$con
  if (!is.null(con) && DBI::dbIsValid(con)) {
    return(con)
  }
  con <- DBI::dbConnect(duckdb::duckdb(shared_home = TRUE))
  ready <- FALSE
  on.exit(if (!ready) DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)
  tryCatch(
    DBI::dbExecute(con, "LOAD httpfs"),
    error = function(e) {
      DBI::dbExecute(con, "INSTALL httpfs")
      DBI::dbExecute(con, "LOAD httpfs")
    }
  )
  .duckdb_cache$con <- con
  reg.finalizer(
    .duckdb_cache,
    function(e) {
      if (!is.null(e$con) && DBI::dbIsValid(e$con)) {
        DBI::dbDisconnect(e$con, shutdown = TRUE)
      }
    },
    onexit = TRUE
  )
  ready <- TRUE
  return(con)
}
