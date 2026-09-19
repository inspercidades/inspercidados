# Download a dataset from Insper Dataverse

Downloads a dataset into R as a tibble or `sf` object. The dataset can
be identified by its short alias, bare DOI, or full DOI URL.

## Usage

``` r
get_dataset(
  dataset,
  year = NULL,
  filename = NULL,
  file_pattern = NULL,
  docs = FALSE
)
```

## Arguments

- dataset:

  A dataset identifier. One of:

  - A short alias, e.g. `"iptu_sp"` (see
    [`list_datasets()`](https://inspercidades.github.io/inspercidados/reference/list_datasets.md)
    for all aliases).

  - A bare DOI, e.g. `"10.60873/FK2/TOXCRF"`.

  - A full DOI URL, e.g. `"https://doi.org/10.60873/FK2/TOXCRF"`.

- year:

  An integer or character year used to filter files when a dataset
  contains multiple annual files (e.g. `year = 2023`).

- filename:

  The exact filename to download from the dataset. Overrides `year` and
  `file_pattern`.

- file_pattern:

  A regex pattern matched against filenames. Applied after `year`
  filtering.

- docs:

  Logical. If `TRUE`, returns a named list with two elements: `data`
  (the downloaded tibble/sf object) and `docs`. When the dataset
  contains a file whose name starts with `"documentacao"` (e.g.
  `"documentacao_iptu.xlsx"`), that file is downloaded and returned as a
  tibble. Otherwise `docs` is a named list of metadata fetched from
  Dataverse (title, description, authors, DOI, URL, year). Default is
  `FALSE`.

## Value

When `docs = FALSE` (default): a
[tibble](https://tibble.tidyverse.org/reference/tibble.html) or `sf`
object with the `"doi"` attribute set. When `docs = TRUE`: a named list
with elements `data` and `docs`.

## Details

When a deposit contains multiple files, the function picks one by
format. Spatial datasets resolve to GeoPackage so the result is an `sf`
object; other datasets favour RDS, then Parquet, then delimited text,
then Excel. Formats needing a suggested package are skipped when it is
not installed. Use `year`, `filename`, or `file_pattern` to override the
choice.

Some aliases share a single Dataverse deposit. `"pemob_anual"` and
`"pemob_harmonizada"` both point at the PEMOB deposit and are separated
by a file pattern stored in the registry.

## Examples

``` r
if (FALSE) { # live_examples()
# By alias
embarques <- get_dataset("embarques_mensais")

# By DOI, or by the DOI URL
embarques <- get_dataset("10.60873/FK2/BPYHFB")
embarques <- get_dataset("https://doi.org/10.60873/FK2/BPYHFB")

# Pick one year from a multi-year dataset
pemob_2023 <- get_dataset("pemob_anual", year = 2023)

# Request a file by exact name, or by regex
linhas <- get_dataset("estacoes_motiva", filename = "dim_line.rds")
estacoes <- get_dataset("estacoes_motiva", file_pattern = "^dim_station")

# Return the data with its documentation
result <- get_dataset("embarques_mensais", docs = TRUE)
result$docs
}
if (FALSE) { # live_examples() && requireNamespace("sf", quietly = TRUE)
# Spatial datasets return an sf object
faixa_azul <- get_dataset("faixa_azul_sp")
}
```
