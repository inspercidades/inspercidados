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
  xls = "xlsx",
  zip = "zip"
)

# Inner extension (after stripping .gz) -> file type
.gz_ext_map <- c(csv = "csv_gz", tab = "tab_gz", tsv = "tab_gz")

insper_server <- function() {
  "dataverse.datascience.insper.edu.br"
}

.registry_cache <- new.env(parent = emptyenv())

read_json_asset <- function(file) {
  cached <- .registry_cache[[file]]
  if (!is.null(cached)) {
    return(cached)
  }
  path <- system.file(file, package = "inspercidados")
  if (!nzchar(path)) {
    cli::cli_abort(paste0(
      "Package data registry {.file {file}} not found. ",
      "Try reinstalling the package."
    ))
  }
  reg <- jsonlite::read_json(path)
  # jsonlite decodes \uXXXX escapes but leaves strings marked "unknown".
  # Tag each string as UTF-8 so R displays it correctly in any locale.
  out <- lapply(reg, function(entry) {
    lapply(entry, function(v) {
      if (is.character(v)) {
        Encoding(v) <- "UTF-8"
        v
      } else {
        v
      }
    })
  })
  assign(file, out, envir = .registry_cache)
  out
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
  vapply(
    filenames,
    function(f) {
      ext <- tolower(tools::file_ext(f))
      if (ext == "gz") {
        return(tolower(tools::file_ext(sub(
          "\\.gz$",
          "",
          f,
          ignore.case = TRUE
        ))))
      }
      ext
    },
    character(1),
    USE.NAMES = FALSE
  )
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
  "xls",
  "zip"
)

# Select a file from those available in the dataset.
# `prefer` is a vector of extensions in priority order; the first extension
# with a matching file wins.
select_dv_file <- function(
  file_names,
  year = NULL,
  filename = NULL,
  file_pattern = NULL,
  prefer = NULL
) {
  if (!is.null(filename)) {
    if (!filename %in% file_names) {
      cli::cli_abort(c(
        "File {.val {filename}} not found in this dataset.",
        "i" = "Available files: {.val {file_names}}"
      ))
    }
    return(filename)
  }

  candidates <- file_names[effective_ext(file_names) %in% DATA_EXTS]

  if (length(candidates) == 0) {
    cli::cli_abort(c(
      "No data files found in this dataset.",
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

  cli::cli_warn(c(
    "No file matched the preferred formats; using {.val {candidates[[1]]}}.",
    "i" = "Available files: {.val {candidates}}"
  ))
  candidates[[1]]
}

.readers <- list(
  rds = function(filename, doi_url, server) {
    raw <- dataverse::get_file_by_name(
      filename,
      dataset = doi_url,
      server = server
    )
    tmp <- tempfile(fileext = ".rds")
    on.exit(unlink(tmp), add = TRUE)
    writeBin(raw, tmp)
    readRDS(tmp)
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
    raw <- dataverse::get_file_by_name(
      filename,
      dataset = doi_url,
      server = server
    )
    tmp <- tempfile(fileext = ".csv.gz")
    on.exit(unlink(tmp), add = TRUE)
    writeBin(raw, tmp)
    readr::read_delim(tmp, delim = ",", show_col_types = FALSE)
  },
  tab_gz = function(filename, doi_url, server) {
    raw <- dataverse::get_file_by_name(
      filename,
      dataset = doi_url,
      server = server
    )
    tmp <- tempfile(fileext = ".tsv.gz")
    on.exit(unlink(tmp), add = TRUE)
    writeBin(raw, tmp)
    readr::read_delim(tmp, delim = "\t", show_col_types = FALSE)
  },
  parquet = function(filename, doi_url, server) {
    rlang::check_installed("arrow", reason = "to read Parquet (.parquet) files")
    raw <- dataverse::get_file_by_name(
      filename,
      dataset = doi_url,
      server = server
    )
    tmp <- tempfile(fileext = ".parquet")
    on.exit(unlink(tmp), add = TRUE)
    writeBin(raw, tmp)
    arrow::read_parquet(tmp)
  },
  geojson = function(filename, doi_url, server) {
    rlang::check_installed("sf", reason = "to read GeoJSON (.geojson) files")
    raw <- dataverse::get_file_by_name(
      filename,
      dataset = doi_url,
      server = server
    )
    tmp <- tempfile(fileext = ".geojson")
    on.exit(unlink(tmp), add = TRUE)
    writeBin(raw, tmp)
    sf::st_read(tmp, quiet = TRUE)
  },
  gpkg = function(filename, doi_url, server) {
    rlang::check_installed("sf", reason = "to read GeoPackage (.gpkg) files")
    raw <- dataverse::get_file_by_name(
      filename,
      dataset = doi_url,
      server = server
    )
    tmp <- tempfile(fileext = ".gpkg")
    on.exit(unlink(tmp), add = TRUE)
    writeBin(raw, tmp)
    sf::st_read(tmp, quiet = TRUE)
  },
  xlsx = function(filename, doi_url, server) {
    rlang::check_installed(
      "readxl",
      reason = "to read Excel (.xlsx/.xls) files"
    )
    raw <- dataverse::get_file_by_name(
      filename,
      dataset = doi_url,
      server = server
    )
    tmp <- tempfile(fileext = ".xlsx")
    on.exit(unlink(tmp), add = TRUE)
    writeBin(raw, tmp)
    readxl::read_excel(tmp)
  },
  xls = function(filename, doi_url, server) {
    rlang::check_installed(
      "readxl",
      reason = "to read Excel (.xlsx/.xls) files"
    )
    raw <- dataverse::get_file_by_name(
      filename,
      dataset = doi_url,
      server = server
    )
    tmp <- tempfile(fileext = ".xls")
    on.exit(unlink(tmp), add = TRUE)
    writeBin(raw, tmp)
    readxl::read_excel(tmp)
  }
)

read_dv_file <- function(filename, doi_url, server, ftype) {
  reader <- .readers[[ftype]]
  if (is.null(reader)) {
    cli::cli_abort(c(
      "Unsupported file type {.val {ftype}} for {.val {filename}}.",
      "i" = "Supported types: rds, csv, tab/tsv, parquet, gpkg, geojson, xlsx."
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
