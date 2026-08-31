# AGENTS.md

This file provides guidance to Codex when working with this repository.

## Project Overview

**inspercidados** is an R package that provides simple, reproducible access to curated Brazilian urban research datasets hosted on Insper's Dataverse. It is aimed at researchers who want clean data in R with minimal friction.

The package is a thin wrapper around the `dataverse` R package. Insper's Dataverse is the single source of truth for data and metadata — the package does not duplicate metadata locally.

The package website is built with **pkgdown**.

## Core Functions (Public API)

| Function | Purpose |
|---|---|
| `list_datasets()` | List datasets; filters on theme, region, project, spatial, access |
| `list_projects()` | List the studies behind the datasets, with their repos |
| `get_dataset()` | Download a registered dataset into R |
| `get_dataverse()` | Download any Insper Dataverse deposit from a pasted DOI/URL |
| `browse_project()` | Print a study, its datasets, and open its repository |
| `cite_dataset()` | Generate a citation for a dataset |
| `get_script()` | Deprecated shim that forwards to `browse_project()` |

## Package Architecture

```
inst/datasets.json          <- alias -> DOI, metadata, file_pattern, formats, status
inst/projects.json          <- project slug -> repo, visibility, member datasets
data-raw/build_registry.R   <- Google Sheet + Dataverse API -> both JSON files
data-raw/aliases.csv        <- DOI (+ file_pattern) -> alias, project
data-raw/projects.csv       <- project -> repo URL, visibility
data-raw/retired.csv        <- aliases that no longer resolve
R/list_datasets.R           <- list_datasets()
R/list_projects.R           <- list_projects()
R/get_dataset.R             <- get_dataset()
R/get_dataverse.R           <- get_dataverse()
R/browse_project.R          <- browse_project()
R/cite_dataset.R            <- cite_dataset()
R/get_script.R              <- deprecated shim
R/utils.R                   <- internal helpers (server, resolve ID, readers)
```

**Registry generation.** The Google Sheet "Site Cidados" / "Catálogo de dados"
is the source of truth for dataset metadata. `data-raw/build_registry.R` reads
it with `googlesheets4`, joins the alias and project tables from `data-raw/`,
queries the Dataverse API for each deposit's file list, and writes both JSON
files. `is_spatial` and `formats` are derived from the deposited file
extensions, never from the sheet's `is_geoportal` column, which means something
else. Auth uses `CIDADOS_GS4_EMAIL` from `.Renviron`.

**An alias is a DOI plus an optional file pattern.** Several aliases can share
one deposit. `pemob_anual` and `pemob_harmonizada` both point at
`10.60873/FK2/5XUNNW` and separate by `file_pattern`. `get_dataset()` applies
that pattern before any user selector.

**Entries carry a `status`.** `active` is downloadable. `unpublished` is
catalogued but held in Insper's secure data room. `retired` is a tombstone for
an alias whose deposit was withdrawn or merged, carrying `superseded_by` so the
error names the replacement. `list_datasets()` shows only `active` by default.

Example registry entry:
```json
{
  "pemob_anual": {
    "doi": "10.60873/FK2/5XUNNW",
    "title": "Pesquisa Nacional de Mobilidade Urbana (PEMOB) [2019-2024]",
    "project": "pemob",
    "access": "download",
    "file_pattern": "^pemob_[0-9]{4}",
    "formats": ["parquet", "tab", "xlsx"],
    "is_spatial": false,
    "status": "active"
  }
}
```

**Server** is always `dataverse.datascience.insper.edu.br` — never ask the user to configure it.

**Identifier resolution** (in order):
1. Alias (e.g. `"iptu_sp"`) -> look up DOI in `inst/datasets.json`
2. DOI (e.g. `"10.60873/FK2/7IXFPX"`) -> use directly
3. Full URL (`https://doi.org/...` or a Dataverse `?persistentId=doi:...`
   landing page) -> extract DOI

Only the `10.60873` prefix is served. Other DOIs abort with an explicit
message rather than being passed through.

## Dataverse Integration

All downloads go through the `dataverse` package (>= 0.3.15):

```r
dataverse::get_dataframe_by_name(
  filename   = "emb_diarios.tab",
  dataset    = "https://doi.org/10.60873/FK2/9MZGJL",
  .f         = \(x) readr::read_delim(x, delim = "\t"),
  server     = "dataverse.datascience.insper.edu.br"
)
```

File listing uses `dataverse::dataset_files()`. Metadata fetching uses `dataverse::get_dataset()`.

## Discoverability

Pipelines are published as whole repositories, not as one script per dataset,
because a study normally produces several datasets across many files. The
mapping lives in `inst/projects.json` and is many-to-many: `faixa-azul`
produces three datasets, and some studies have no repository yet.
`browse_project()` prints the study and opens its repo; repos marked `private`
are flagged before opening.

`replication_scripts/` is a stale local copy of code that now lives in the org
repos. It is in `.Rbuildignore` and should not be extended.

## get_dataset() Flexible Parameters

Users can identify a dataset in several ways:

```r
get_dataset("iptu_sp")                          # by alias
get_dataset("10.60873/FK2/TOXCRF")              # by DOI
get_dataset("pemob_anual", year = 2023)         # filter by year in filename
get_dataset("iptu_sp", filename = "iptu.gpkg")  # exact filename
get_dataset("iptu_sp", file_pattern = "\\.gpkg$") # regex pattern

# Any deposit, registered or not
get_dataverse("10.60873/FK2/AOLEOI", files = TRUE)
```

## Messaging Conventions

- Use `cli` for all user-facing messages (`cli_inform`, `cli_warn`, `cli_abort`)
- Progress for downloads via `cli_progress_step()`
- No `message()`, `warning()`, or `stop()` calls in user-facing code

## CRAN Compliance

- No `\dontrun{}` unless the example truly cannot run (e.g. requires network)
- All exported functions have `@examples`
- `DESCRIPTION` has complete `Title`, `Description`, proper `Authors@R`
- No internet calls in tests — use `testthat::skip_if_offline()` or mock
- `R CMD check` passes with 0 errors, 0 warnings, 0 notes (except maintainer note)

## Development Commands

```r
devtools::load_all()      # load package
devtools::document()      # regenerate docs
devtools::check()         # full R CMD check
devtools::test()          # run tests
pkgdown::build_site()     # build website
```

## Key Dependencies

**Imports** (always available):
- `dataverse` (>= 0.3.15) — Dataverse API client
- `cli` — user messaging
- `jsonlite` — read inst/datasets.json

**Suggests** (loaded conditionally with `rlang::check_installed()`):
- `arrow` — Parquet file support
- `sf` — spatial GeoPackage and GeoJSON support
- `readxl` — Excel file support
- `googlesheets4`, `janitor` — used only by `data-raw/build_registry.R`

Format preference in `get_dataset()` skips any format whose package is
missing, so the package stays usable with none of the Suggests installed.

## File Conventions

- Snake_case for all function and variable names
- One exported function per `.R` file, named after the function
- Internal helpers in `R/utils.R`
- `@keywords internal` + `@noRd` on all non-exported functions
