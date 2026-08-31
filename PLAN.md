# inspercidados — status

**Updated:** 2026-08-31

## Where things stand

The registry is generated from the live Google Sheet rather than from a
checked-in Excel snapshot. `data-raw/build_registry.R` reads the sheet, joins
the alias and project tables in `data-raw/`, queries the Dataverse API for each
deposit's file list, and writes `inst/datasets.json` and `inst/projects.json`.

`R CMD check` passes with 0 errors, 0 warnings, 0 notes.

## Open work

### Add an `alias` column to the catalog sheet

`build_registry.R` already reads a column named `alias` when it exists and
falls back to `data-raw/aliases.csv` otherwise. Backfill the sheet from
`data-raw/aliases.csv` to move alias ownership to the curators.

One deposit can hold several datasets, so the sheet column cannot express the
whole mapping on its own. Sub-aliases with a `file_pattern` stay in
`data-raw/aliases.csv`.

### Missing repositories

Four studies have no repository registered in `data-raw/projects.csv`: `itbi`,
`alvaras`, `mortalidade`, and `mare`. `browse_project()` reports that the code
is unpublished until a URL is added.

`pipeline-motiva` is private, so `browse_project()` warns before opening it.
Making it public would let external users reproduce the embarques datasets.

### Upstream data problems

`mortalidade_sp` (`10.60873/FK2/CDXI9B`) deposits only `Documentacao.tab` and
`README.txt`, so it has no data to download. The `.tab` file is an Excel
workbook that Dataverse ingest renamed.

`iptu_sp` (`10.60873/FK2/TOXCRF`) and `iptu_verticalizacao_sp`
(`10.60873/FK2/4QNTOT`) carry near-identical titles in the catalog, which makes
them hard to tell apart in `list_datasets()`.

The catalog sheet lists `Gastos com UBS por distrito [2019]` with no DOI, and
its former deposit was withdrawn.

### Tests

There is no `tests/` directory. `testthat` is in `Suggests` but unused. Worth
covering identifier resolution, file-type detection, format priority, registry
parsing, and retired-alias errors, none of which need the network.

## Notes for maintainers

`is_spatial` and `formats` come from the file extensions in each deposit, read
from the Dataverse API at build time. Do not hand-edit them, and do not use the
sheet's `is_geoportal` column for this: it marks presence on the GeoPortal, not
file format, and the two disagree.
