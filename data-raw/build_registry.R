# Build inst/datasets.json and inst/projects.json from the live Google Sheet.
#
# Sources of truth:
#   Google Sheet "Site Cidados" / "Catalogo de dados"  -> dataset metadata
#   data-raw/aliases.csv                               -> DOI + file_pattern -> alias
#   data-raw/projects.csv                              -> project -> repo
#   data-raw/retired.csv                               -> aliases that no longer resolve
#   Dataverse API                                      -> file formats, is_spatial
#
# Run with: Rscript data-raw/build_registry.R

library(googlesheets4)
library(jsonlite)

tryCatch(Sys.setlocale("LC_ALL", "en_US.UTF-8"), error = function(e) NULL)

SHEET_ID <- "1pg85pVZ76XW9P9N8RyoK56nKND7u8304sy2z7QfwYM8"
SHEET_TAB <- "Catálogo de dados"
SERVER <- "https://dataverse.datascience.insper.edu.br"

`%||%` <- function(x, y) if (is.null(x) || length(x) == 0 || all(is.na(x))) y else x

# Helpers ----------------------------------------------------------------

clean_text <- function(x) {
  x <- as.character(x)
  x[x == "NULL"] <- NA_character_
  x <- enc2utf8(x)
  x <- gsub("\r\n|\n|\r", " ", x)
  x <- gsub("\\s{2,}", " ", x)
  x <- trimws(x)
  x[!nzchar(x)] <- NA_character_
  x
}

# Dataverse marks an identifier as permanent but drops the released version when
# a deposit is withdrawn. A missing :latest version is how that shows up.
dv_files <- function(doi) {
  url <- sprintf(
    "%s/api/datasets/:persistentId/versions/:latest/files?persistentId=doi:%s",
    SERVER, utils::URLencode(doi, reserved = TRUE)
  )
  res <- tryCatch(fromJSON(url, simplifyVector = FALSE), error = function(e) NULL)
  if (is.null(res) || !identical(res$status, "OK")) return(NULL)
  vapply(res$data, function(f) f$dataFile$filename, character(1))
}

# Effective extension per file: .csv.gz reports "csv", so a gzipped table is
# not mistaken for an opaque archive.
file_ext_each <- function(files) {
  if (length(files) == 0) return(character(0))
  ext <- tolower(tools::file_ext(files))
  ifelse(ext == "gz", tolower(tools::file_ext(sub("\\.gz$", "", files))), ext)
}

file_exts <- function(files) {
  ext <- file_ext_each(files)
  sort(unique(ext[nzchar(ext)]))
}

DATA_EXTS <- c("rds", "csv", "tab", "tsv", "parquet", "gpkg", "geojson", "xlsx", "xls", "zip")
SPATIAL_EXTS <- c("gpkg", "geojson", "shp")

# Read the catalog -------------------------------------------------------

gs4_auth(email = Sys.getenv("CIDADOS_GS4_EMAIL", unset = NA))

catalogo <- read_sheet(
  SHEET_ID, sheet = SHEET_TAB, skip = 1,
  .name_repair = janitor::make_clean_names
)

cat("Read", nrow(catalogo), "rows from the catalog sheet.\n")

link <- as.character(catalogo$link_da_base_de_dados_data_verse)
catalogo$doi <- ifelse(
  grepl("doi:10[.]60873", link),
  sub(".*doi:(10[.]60873/[^&#]+).*", "\\1", link),
  NA_character_
)

# Access status. Rows without a DOI are still catalog entries; users should be
# able to discover them and learn why they cannot be downloaded.
acesso <- clean_text(catalogo$filtro_acesso)
catalogo$access <- ifelse(
  grepl("^Sala segura", acesso %||% ""), "secure_room",
  ifelse(is.na(catalogo$doi), "unpublished", "download")
)

# Alias assignment -------------------------------------------------------

aliases <- utils::read.csv("data-raw/aliases.csv", stringsAsFactors = FALSE, na.strings = "")
projects <- utils::read.csv("data-raw/projects.csv", stringsAsFactors = FALSE, na.strings = "")
retired <- utils::read.csv("data-raw/retired.csv", stringsAsFactors = FALSE, na.strings = "")

# Once the sheet gains an "alias" column it becomes the primary alias for each
# catalog row. aliases.csv still supplies sub-aliases, because one deposit can
# hold several datasets (PEMOB, Mare) and a single sheet column cannot say that.
if ("alias" %in% names(catalogo)) {
  sheet_alias <- clean_text(catalogo$alias)
  has_sheet <- !is.na(sheet_alias) & !is.na(catalogo$doi)
  cat("Sheet supplies", sum(has_sheet), "aliases.\n")
  for (i in which(has_sheet)) {
    hit <- aliases$doi == catalogo$doi[i] & is.na(aliases$file_pattern)
    if (any(hit)) {
      if (!identical(aliases$alias[which(hit)[1]], sheet_alias[i])) {
        cat(sprintf("  ! sheet alias '%s' overrides csv alias '%s' for %s\n",
                    sheet_alias[i], aliases$alias[which(hit)[1]], catalogo$doi[i]))
      }
      aliases$alias[which(hit)[1]] <- sheet_alias[i]
    } else {
      aliases <- rbind(aliases, data.frame(
        doi = catalogo$doi[i], alias = sheet_alias[i], file_pattern = NA,
        project = NA, notes = NA, stringsAsFactors = FALSE
      ))
    }
  }
} else {
  cat("No 'alias' column in the sheet yet; using data-raw/aliases.csv alone.\n")
}

stopifnot(!anyDuplicated(aliases$alias))

# Warn about drift in both directions rather than failing the build.
missing_alias <- setdiff(stats::na.omit(catalogo$doi), aliases$doi)
if (length(missing_alias)) {
  cat("! DOIs in the catalog with no alias:\n")
  for (d in missing_alias) {
    cat(sprintf("    %s  %s\n", d, catalogo$titulo_da_base_de_dados[match(d, catalogo$doi)]))
  }
}
stale_alias <- setdiff(aliases$doi, stats::na.omit(catalogo$doi))
if (length(stale_alias)) {
  cat("! aliases pointing at DOIs no longer in the catalog:", paste(unique(stale_alias), collapse = ", "), "\n")
}

# Build the dataset registry ---------------------------------------------

kw_cols <- grep("^palavra_chave_", names(catalogo), value = TRUE)

registry <- list()
files_cache <- list()

for (i in seq_len(nrow(aliases))) {
  alias <- aliases$alias[i]
  doi <- aliases$doi[i]
  row <- match(doi, catalogo$doi)
  if (is.na(row)) {
    cat(sprintf("  skipping %s: DOI %s not in the catalog\n", alias, doi))
    next
  }

  if (is.null(files_cache[[doi]])) {
    files_cache[[doi]] <- dv_files(doi) %||% character(0)
  }
  files <- files_cache[[doi]]

  pattern <- aliases$file_pattern[i]
  own <- if (is.na(pattern)) files else grep(pattern, files, value = TRUE, perl = TRUE)
  own <- own[file_ext_each(own) %in% DATA_EXTS]

  if (length(files) == 0) {
    cat(sprintf("  ! %s (%s): no released version on Dataverse\n", alias, doi))
  } else if (!is.na(pattern) && length(own) == 0) {
    cat(sprintf("  ! %s: pattern '%s' matched no files in %s\n", alias, pattern, doi))
  }

  kws <- unlist(lapply(kw_cols, function(k) clean_text(catalogo[[k]][row])))
  kws <- kws[!is.na(kws)]

  registry[[alias]] <- list(
    doi = doi,
    title = clean_text(catalogo$titulo_da_base_de_dados[row]),
    description = clean_text(catalogo$descricao_da_base_de_dados[row]),
    theme = clean_text(catalogo$filtro_tema[row]),
    region = clean_text(catalogo$filtro_regiao[row]),
    keywords = if (length(kws)) paste(kws, collapse = "; ") else NULL,
    collection = clean_text(catalogo$titulo_da_colecao[row]),
    project = aliases$project[i],
    access = catalogo$access[row],
    file_pattern = if (is.na(pattern)) NULL else pattern,
    formats = file_exts(own),
    is_spatial = any(file_exts(own) %in% SPATIAL_EXTS),
    status = "active"
  )
}

# Catalog rows with no DOI are listed so users can find them and learn that
# access runs through Insper's secure room rather than a download.
for (row in which(is.na(catalogo$doi))) {
  title <- clean_text(catalogo$titulo_da_base_de_dados[row])
  if (is.na(title)) next
  alias <- paste0("_unpublished_", row)
  registry[[alias]] <- list(
    doi = NULL,
    title = title,
    description = clean_text(catalogo$descricao_da_base_de_dados[row]),
    theme = clean_text(catalogo$filtro_tema[row]),
    region = clean_text(catalogo$filtro_regiao[row]),
    collection = clean_text(catalogo$titulo_da_colecao[row]),
    access = catalogo$access[row],
    formats = character(0),
    is_spatial = FALSE,
    status = "unpublished"
  )
}

# Retired aliases keep a tombstone so users who copied an old script get told
# what happened instead of a bare "dataset not found".
for (i in seq_len(nrow(retired))) {
  registry[[retired$alias[i]]] <- list(
    doi = retired$doi[i],
    superseded_by = if (is.na(retired$superseded_by[i])) NULL else retired$superseded_by[i],
    reason = retired$reason[i],
    status = "retired"
  )
}

# Build the project registry ---------------------------------------------

proj <- list()
for (i in seq_len(nrow(projects))) {
  slug <- projects$project[i]
  members <- aliases$alias[!is.na(aliases$project) & aliases$project == slug]
  members <- members[members %in% names(registry)]
  proj[[slug]] <- list(
    title = clean_text(projects$title[i]),
    repo_url = if (is.na(projects$repo_url[i])) NULL else projects$repo_url[i],
    visibility = if (is.na(projects$visibility[i])) NULL else projects$visibility[i],
    datasets = members
  )
}

orphan <- setdiff(stats::na.omit(aliases$project), projects$project)
if (length(orphan)) cat("! aliases reference unknown projects:", paste(orphan, collapse = ", "), "\n")

# Write ------------------------------------------------------------------

writeLines(toJSON(registry, pretty = TRUE, auto_unbox = TRUE, null = "null"), "inst/datasets.json")
writeLines(toJSON(proj, pretty = TRUE, auto_unbox = TRUE, null = "null"), "inst/projects.json")

active <- Filter(function(x) identical(x$status, "active"), registry)
cat(sprintf("\nWrote inst/datasets.json: %d active, %d retired, %d unpublished\n",
            length(active),
            sum(vapply(registry, function(x) identical(x$status, "retired"), logical(1))),
            sum(vapply(registry, function(x) identical(x$status, "unpublished"), logical(1)))))
cat(sprintf("Wrote inst/projects.json: %d projects\n\n", length(proj)))

for (a in names(active)) {
  e <- active[[a]]
  cat(sprintf("  %-24s %-20s %-11s %s%s\n", a, e$doi, e$project %||% "-",
              paste(e$formats, collapse = ","),
              if (isTRUE(e$is_spatial)) "  [spatial]" else ""))
}
