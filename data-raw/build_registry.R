# Build inst/datasets.json and inst/projects.json from the live Google Sheet.
# The catalog is validated before Dataverse is queried or files are written.
# Validate: Rscript data-raw/build_registry.R --validate-only
# Build:    Rscript data-raw/build_registry.R

library(cli)
library(googlesheets4)
library(jsonlite)
library(stringr)

tryCatch(Sys.setlocale("LC_ALL", "en_US.UTF-8"), error = \(e) NULL)

sheet_id <- "1pg85pVZ76XW9P9N8RyoK56nKND7u8304sy2z7QfwYM8"
sheet_tab <- "Catálogo de dados"
server <- "https://dataverse.datascience.insper.edu.br"

allowed_themes <- c(
  "Clima e Meio Ambiente",
  "Educação",
  "Habitação e Mercado Imobiliário",
  "Mobilidade",
  "Multidisciplinar e transversal",
  "Saúde",
  "Trabalho e renda"
)
allowed_access <- c("Disponível para download", "Sala segura do Insper")
required_keyword_columns <- paste0("palavra_chave_", 1:5)
required_catalog_columns <- c(
  "titulo_da_colecao",
  "filtro_tema",
  "filtro_regiao",
  "filtro_acesso",
  required_keyword_columns,
  "titulo_da_base_de_dados",
  "descricao_da_base_de_dados",
  "link_da_base_de_dados_data_verse"
)
data_exts <- c(
  "rds",
  "csv",
  "tab",
  "tsv",
  "parquet",
  "gpkg",
  "geojson",
  "xlsx",
  "xls"
)
spatial_exts <- c("gpkg", "geojson", "shp")

`%||%` <- function(x, y) {
  if (is.null(x) || length(x) == 0 || all(is.na(x))) {
    return(y)
  }
  return(x)
}

# Helpers ---------------------------------------------------------------------

clean_text <- function(x) {
  x <- as.character(x)
  x[x == "NULL"] <- NA_character_
  x <- stringr::str_squish(enc2utf8(x))
  x[!is.na(x) & !nzchar(x)] <- NA_character_
  return(x)
}

extract_doi <- function(x) {
  match <- stringr::str_match(
    clean_text(x),
    "doi:(10[.]60873/[^&#[:space:]]+)"
  )
  return(match[, 2])
}

catalog_keyword_columns <- function(catalog) {
  columns <- grep("^palavra_chave_[0-9]+$", names(catalog), value = TRUE)
  return(columns)
}

file_ext_each <- function(files) {
  if (length(files) == 0) {
    return(character())
  }
  ext <- stringr::str_to_lower(tools::file_ext(files))
  compressed <- ext == "gz"
  ext[compressed] <- files[compressed] |>
    stringr::str_remove("[.]gz$") |>
    tools::file_ext() |>
    stringr::str_to_lower()
  return(ext)
}

file_exts <- function(files) {
  ext <- file_ext_each(files)
  return(sort(unique(ext[nzchar(ext)])))
}

read_csv_input <- function(path) {
  dat <- utils::read.csv(path, stringsAsFactors = FALSE, na.strings = "")
  return(dat)
}

# Catalog validation ----------------------------------------------------------

read_catalog <- function() {
  googlesheets4::gs4_auth(email = Sys.getenv("CIDADOS_GS4_EMAIL", unset = NA))
  catalog <- googlesheets4::read_sheet(
    sheet_id,
    sheet = sheet_tab,
    skip = 1,
    .name_repair = janitor::make_clean_names
  )
  cli::cli_inform("Read {nrow(catalog)} row{?s} from the catalog sheet.")
  return(catalog)
}

drop_blank_catalog_rows <- function(catalog) {
  catalog[] <- lapply(catalog, clean_text)
  blank <- apply(catalog, 1, \(x) all(is.na(x)))
  if (any(blank)) {
    cli::cli_inform("Ignoring {sum(blank)} completely blank catalog row{?s}.")
  }
  catalog <- catalog[!blank, , drop = FALSE]
  catalog$.sheet_row <- which(!blank) + 2L
  return(catalog)
}

validate_catalog_schema <- function(catalog) {
  missing <- setdiff(required_catalog_columns, names(catalog))
  if (length(missing) > 0) {
    cli::cli_abort(c(
      "The catalog schema is invalid.",
      "x" = "Missing {length(missing)} column{?s}: {.field {missing}}",
      "i" = paste0(
        "Restore the missing column",
        if (length(missing) == 1) "" else "s",
        " in the Google Sheet and run the script again."
      )
    ))
  }
  return(invisible(catalog))
}

new_issue <- function(row, field, problem) {
  return(data.frame(row, field, problem, stringsAsFactors = FALSE))
}

catalog_validation_issues <- function(catalog) {
  sheet_rows <- if (".sheet_row" %in% names(catalog)) {
    catalog$.sheet_row
  } else {
    seq_len(nrow(catalog)) + 2L
  }
  issues <- list()
  keyword_columns <- catalog_keyword_columns(catalog)
  add_issue <- function(index, field, problem) {
    issues[[length(issues) + 1L]] <<- new_issue(
      sheet_rows[index],
      field,
      problem
    )
    return(invisible(NULL))
  }

  required <- c(
    titulo_da_colecao = "collection title",
    titulo_da_base_de_dados = "dataset title",
    descricao_da_base_de_dados = "dataset description",
    filtro_tema = "theme",
    filtro_regiao = "region",
    filtro_acesso = "access"
  )
  for (field in names(required)) {
    for (index in which(is.na(catalog[[field]]))) {
      add_issue(index, field, paste(required[[field]], "is required"))
    }
  }

  invalid_theme <- which(
    !is.na(catalog$filtro_tema) &
      !catalog$filtro_tema %in% allowed_themes
  )
  for (index in invalid_theme) {
    add_issue(
      index,
      "filtro_tema",
      paste0(
        "unknown theme '",
        catalog$filtro_tema[index],
        "'; use one of: ",
        paste(allowed_themes, collapse = ", ")
      )
    )
  }

  invalid_access <- which(
    !is.na(catalog$filtro_acesso) &
      !catalog$filtro_acesso %in% allowed_access
  )
  for (index in invalid_access) {
    add_issue(
      index,
      "filtro_acesso",
      paste0(
        "unknown access value '",
        catalog$filtro_acesso[index],
        "'; use one of: ",
        paste(allowed_access, collapse = ", ")
      )
    )
  }

  for (index in seq_len(nrow(catalog))) {
    keywords <- unlist(catalog[index, keyword_columns], use.names = FALSE)
    keywords <- keywords[!is.na(keywords)]
    if (length(keywords) < 3 || length(keywords) > 5) {
      add_issue(
        index,
        "keywords",
        paste0(
          "expected 3 to 5 keywords, found ",
          length(keywords)
        )
      )
    }
    duplicate <- unique(keywords[duplicated(stringr::str_to_lower(keywords))])
    if (length(duplicate) > 0) {
      add_issue(
        index,
        "keywords",
        paste0(
          "duplicated keyword(s): ",
          paste(duplicate, collapse = ", ")
        )
      )
    }
  }

  doi <- extract_doi(catalog$link_da_base_de_dados_data_verse)
  link <- clean_text(catalog$link_da_base_de_dados_data_verse)
  claims_dataverse <- grepl("dataverse|doi", link, ignore.case = TRUE)
  claims_dataverse[is.na(claims_dataverse)] <- FALSE
  invalid_doi <- claims_dataverse & is.na(doi)
  for (index in which(invalid_doi)) {
    add_issue(
      index,
      "link_da_base_de_dados_data_verse",
      "links must contain a valid 10.60873 Dataverse DOI"
    )
  }

  if (length(issues) == 0) {
    return(data.frame(
      row = integer(),
      field = character(),
      problem = character()
    ))
  }
  return(do.call(rbind, issues))
}

validate_catalog <- function(catalog) {
  validate_catalog_schema(catalog)
  issues <- catalog_validation_issues(catalog)
  if (nrow(issues) > 0) {
    details <- paste0(
      "Google Sheet row ",
      issues$row,
      " [",
      issues$field,
      "]: ",
      issues$problem
    )
    cli::cli_abort(c(
      "Catalog validation failed with {nrow(issues)} issue{?s}.",
      stats::setNames(details, rep("x", length(details))),
      "i" = paste0(
        "Fix these values in the Google Sheet and run ",
        "`Rscript data-raw/build_registry.R` again. No registry files were written."
      )
    ))
  }
  cli::cli_alert_success("Catalog validation passed.")
  return(invisible(catalog))
}

prepare_catalog <- function(catalog) {
  validate_catalog_schema(catalog)
  catalog <- drop_blank_catalog_rows(catalog)
  validate_catalog(catalog)
  catalog$doi <- extract_doi(catalog$link_da_base_de_dados_data_verse)
  catalog$access <- ifelse(
    catalog$filtro_acesso == "Sala segura do Insper",
    "secure_room",
    ifelse(is.na(catalog$doi), "unpublished", "download")
  )
  return(catalog)
}

# Manual registry inputs ------------------------------------------------------

reconcile_aliases <- function(catalog, aliases, resources) {
  if (!"alias" %in% names(catalog)) {
    cli::cli_inform(
      "No {.field alias} column in the sheet; using {.file data-raw/aliases.csv}."
    )
    return(list(aliases = aliases, resources = resources))
  }
  sheet_alias <- clean_text(catalog$alias)
  supplied <- !is.na(sheet_alias) & !is.na(catalog$doi)
  cli::cli_inform("The sheet supplies {sum(supplied)} alias{?es}.")

  for (index in which(supplied)) {
    hit <- aliases$doi == catalog$doi[index] & aliases$primary
    if (any(hit)) {
      first <- which(hit)[1]
      if (!identical(aliases$alias[first], sheet_alias[index])) {
        cli::cli_warn(
          "Sheet alias {.val {sheet_alias[index]}} overrides {.val {aliases$alias[first]}} for {.val {catalog$doi[index]}}."
        )
      }
      old_alias <- aliases$alias[first]
      aliases$alias[first] <- sheet_alias[index]
      resources$alias[resources$alias == old_alias] <- sheet_alias[index]
    } else {
      aliases <- rbind(
        aliases,
        data.frame(
          doi = catalog$doi[index],
          alias = sheet_alias[index],
          primary = TRUE,
          project = NA_character_,
          notes = NA_character_,
          stringsAsFactors = FALSE
        )
      )
    }
  }
  return(list(aliases = aliases, resources = resources))
}

validate_manual_inputs <- function(catalog, aliases, resources, projects) {
  duplicate <- unique(aliases$alias[duplicated(aliases$alias)])
  unknown_project <- setdiff(stats::na.omit(aliases$project), projects$project)
  missing_resources <- setdiff(aliases$alias, resources$alias)
  unknown_aliases <- setdiff(resources$alias, aliases$alias)
  resource_key <- paste(resources$alias, resources$resource, sep = "/")
  duplicate_resources <- unique(resource_key[duplicated(resource_key)])
  defaults <- tapply(resources$default, resources$alias, sum)
  problems <- character()
  if (length(duplicate) > 0) {
    problems <- c(
      problems,
      paste("Duplicated alias(es):", paste(duplicate, collapse = ", "))
    )
  }
  if (length(unknown_project) > 0) {
    problems <- c(
      problems,
      paste("Unknown project(s):", paste(unknown_project, collapse = ", "))
    )
  }
  if (length(missing_resources) > 0) {
    problems <- c(
      problems,
      paste(
        "Aliases without resources:",
        paste(missing_resources, collapse = ", ")
      )
    )
  }
  if (length(unknown_aliases) > 0) {
    problems <- c(
      problems,
      paste(
        "Resources for unknown aliases:",
        paste(unknown_aliases, collapse = ", ")
      )
    )
  }
  if (length(duplicate_resources) > 0) {
    problems <- c(
      problems,
      paste(
        "Duplicated resources:",
        paste(duplicate_resources, collapse = ", ")
      )
    )
  }
  invalid_defaults <- names(defaults)[is.na(defaults) | defaults > 1]
  if (length(invalid_defaults) > 0) {
    problems <- c(
      problems,
      paste(
        "Aliases with invalid or multiple default resources:",
        paste(invalid_defaults, collapse = ", ")
      )
    )
  }
  if (length(problems) > 0) {
    cli::cli_abort(c(
      "Manual registry inputs are invalid.",
      stats::setNames(problems, rep("x", length(problems)))
    ))
  }

  missing_alias <- setdiff(stats::na.omit(catalog$doi), aliases$doi)
  if (length(missing_alias) > 0) {
    cli::cli_warn("Catalog DOI{?s} without an alias: {.val {missing_alias}}")
  }
  stale_alias <- unique(setdiff(aliases$doi, stats::na.omit(catalog$doi)))
  if (length(stale_alias) > 0) {
    cli::cli_warn("Alias DOI{?s} absent from the catalog: {.val {stale_alias}}")
  }
  return(invisible(aliases))
}

# Dataverse and builders ------------------------------------------------------

dataverse_files <- function(doi) {
  url <- sprintf(
    "%s/api/datasets/:persistentId/versions/:latest/files?persistentId=doi:%s",
    server,
    utils::URLencode(doi, reserved = TRUE)
  )
  response <- tryCatch(
    jsonlite::fromJSON(url, simplifyVector = FALSE),
    error = \(e) NULL
  )
  if (is.null(response) || !identical(response$status, "OK")) {
    return(NULL)
  }
  files <- vapply(response$data, \(x) x$dataFile$filename, character(1))
  return(files)
}

build_dataset_registry <- function(catalog, aliases, resources, retired) {
  registry <- list()
  files_cache <- list()
  keyword_columns <- catalog_keyword_columns(catalog)
  for (index in seq_len(nrow(aliases))) {
    alias <- aliases$alias[index]
    doi <- aliases$doi[index]
    row <- match(doi, catalog$doi)
    if (is.na(row)) {
      cli::cli_inform(
        "Skipping {.val {alias}}: DOI {.val {doi}} is absent from the catalog."
      )
      next
    }
    if (is.null(files_cache[[doi]])) {
      files_cache[[doi]] <- dataverse_files(doi) %||% character()
    }
    files <- files_cache[[doi]]
    definitions <- resources[resources$alias == alias, , drop = FALSE]
    resource_list <- list()
    matched_files <- character()
    for (resource_index in seq_len(nrow(definitions))) {
      resource <- definitions$resource[resource_index]
      pattern <- definitions$file_pattern[resource_index]
      own <- grep(pattern, files, value = TRUE, perl = TRUE)
      own <- own[file_ext_each(own) %in% data_exts]
      overlap <- intersect(own, matched_files)
      if (length(overlap) > 0) {
        cli::cli_abort(
          "Resource {.val {resource}} for {.val {alias}} overlaps another resource: {.val {overlap}}."
        )
      }
      if (length(files) > 0 && length(own) == 0) {
        cli::cli_abort(
          "Resource {.val {resource}} for {.val {alias}} matched no files in {.val {doi}}."
        )
      }
      matched_files <- c(matched_files, own)
      resource_formats <- file_exts(own)
      documentation_pattern <- definitions$documentation_pattern[
        resource_index
      ] %||%
        NULL
      if (
        !is.null(documentation_pattern) &&
          !any(grepl(documentation_pattern, files, perl = TRUE))
      ) {
        cli::cli_abort(
          "Documentation pattern for {.val {alias}}/{.val {resource}} matched no files in {.val {doi}}."
        )
      }
      years <- unique(unlist(stringr::str_extract_all(
        own,
        "(?<![0-9])[12][0-9]{3}(?![0-9])"
      )))
      years <- sort(years[!is.na(years)])
      resource_list[[resource]] <- list(
        title = definitions$title[resource_index],
        file_pattern = pattern,
        documentation_pattern = documentation_pattern,
        formats = resource_formats,
        is_spatial = any(resource_formats %in% spatial_exts),
        years = years,
        default = isTRUE(definitions$default[resource_index])
      )
    }
    if (length(files) == 0) {
      cli::cli_warn(
        "{.val {alias}} ({.val {doi}}) has no released Dataverse version."
      )
    }
    keywords <- unlist(catalog[row, keyword_columns], use.names = FALSE)
    keywords <- keywords[!is.na(keywords)]
    formats <- sort(unique(unlist(lapply(resource_list, `[[`, "formats"))))
    registry[[alias]] <- list(
      doi = doi,
      title = catalog$titulo_da_base_de_dados[row],
      description = catalog$descricao_da_base_de_dados[row],
      theme = catalog$filtro_tema[row],
      region = catalog$filtro_regiao[row],
      keywords = paste(keywords, collapse = "; "),
      collection = catalog$titulo_da_colecao[row],
      project = aliases$project[index],
      access = catalog$access[row],
      resources = resource_list,
      formats = formats,
      is_spatial = any(formats %in% spatial_exts),
      status = "active"
    )
  }

  for (row in which(is.na(catalog$doi))) {
    alias <- paste0("_unpublished_", row)
    registry[[alias]] <- list(
      doi = NULL,
      title = catalog$titulo_da_base_de_dados[row],
      description = catalog$descricao_da_base_de_dados[row],
      theme = catalog$filtro_tema[row],
      region = catalog$filtro_regiao[row],
      collection = catalog$titulo_da_colecao[row],
      access = catalog$access[row],
      formats = character(),
      is_spatial = FALSE,
      status = "unpublished"
    )
  }
  for (index in seq_len(nrow(retired))) {
    registry[[retired$alias[index]]] <- list(
      doi = retired$doi[index],
      superseded_by = retired$superseded_by[index] %||% NULL,
      reason = retired$reason[index],
      status = "retired"
    )
  }
  return(registry)
}

build_project_registry <- function(projects, aliases, registry) {
  result <- list()
  for (index in seq_len(nrow(projects))) {
    slug <- projects$project[index]
    members <- aliases$alias[!is.na(aliases$project) & aliases$project == slug]
    members <- members[members %in% names(registry)]
    result[[slug]] <- list(
      title = clean_text(projects$title[index]),
      repo_url = projects$repo_url[index] %||% NULL,
      visibility = projects$visibility[index] %||% NULL,
      datasets = members
    )
  }
  return(result)
}

# Output and entry point ------------------------------------------------------

write_registry <- function(registry, projects) {
  writeLines(
    jsonlite::toJSON(registry, pretty = TRUE, auto_unbox = TRUE, null = "null"),
    "inst/datasets.json"
  )
  writeLines(
    jsonlite::toJSON(projects, pretty = TRUE, auto_unbox = TRUE, null = "null"),
    "inst/projects.json"
  )
  return(invisible(NULL))
}

report_registry <- function(registry, projects) {
  status <- vapply(registry, \(x) x$status, character(1))
  cli::cli_alert_success(paste0(
    "Wrote {.file inst/datasets.json}: {sum(status == 'active')} active, ",
    "{sum(status == 'retired')} retired, and ",
    "{sum(status == 'unpublished')} unpublished."
  ))
  cli::cli_alert_success(
    "Wrote {.file inst/projects.json}: {length(projects)} projects."
  )
  return(invisible(NULL))
}

main <- function(validate_only = FALSE) {
  catalog <- prepare_catalog(read_catalog())

  if (validate_only) {
    cli::cli_alert_success(
      "Validation complete. No registry files were written."
    )
    return(invisible(NULL))
  }

  aliases <- read_csv_input("data-raw/aliases.csv")
  resources <- read_csv_input("data-raw/resources.csv")
  projects <- read_csv_input("data-raw/projects.csv")
  retired <- read_csv_input("data-raw/retired.csv")
  aliases$primary <- tolower(aliases$primary) == "true"
  resources$default <- tolower(resources$default) == "true"
  reconciled <- reconcile_aliases(catalog, aliases, resources)
  aliases <- reconciled$aliases
  resources <- reconciled$resources
  validate_manual_inputs(catalog, aliases, resources, projects)

  cli::cli_h1("Building registries")
  registry <- build_dataset_registry(catalog, aliases, resources, retired)
  project_registry <- build_project_registry(projects, aliases, registry)
  write_registry(registry, project_registry)
  report_registry(registry, project_registry)
  return(invisible(NULL))
}

if (sys.nframe() == 0) {
  main(validate_only = "--validate-only" %in% commandArgs(trailingOnly = TRUE))
}
