# Download a dataset from Insper Dataverse

Downloads a registered dataset into R as a tibble or `sf` object.
Identify the dataset by its short alias; use
[`get_dataverse()`](https://inspercidades.github.io/inspercidados/reference/get_dataverse.md)
for a DOI or URL.

## Usage

``` r
get_dataset(
  dataset,
  ...,
  resource = NULL,
  year = NULL,
  format = NULL,
  docs = FALSE
)
```

## Arguments

- dataset:

  A dataset identifier. One of: A short alias, e.g. `"iptu_sp"`. See
  [`list_datasets()`](https://inspercidades.github.io/inspercidados/reference/list_datasets.md)
  for all aliases.

- ...:

  Reserved for future selectors. Must be empty.

- resource:

  The name of a logical resource within the registered dataset. When
  `NULL`, the resource marked as the default is used. See
  [`list_resources()`](https://inspercidades.github.io/inspercidados/reference/list_resources.md)
  for the available names.

- year:

  An integer or character year used to filter files when a dataset
  contains multiple annual files (e.g. `year = 2023`).

- format:

  An optional file format, such as `"parquet"`, `"gpkg"`, or `"xlsx"`.
  The format must be available for the selected resource.

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

A Dataverse deposit may contain several logical resources, each
distributed in several formats. Use `resource` to select the logical
dataset and `format` to select its representation. Deposits with one
resource, or a declared default, need neither argument.

When `format` is omitted, spatial resources prefer GeoPackage and
GeoJSON; other resources prefer RDS, Parquet, delimited text, and Excel.
Formats that need an uninstalled suggested package are skipped.

## Examples

``` r
if (FALSE) { # live_examples()
# By alias
embarques <- get_dataset("embarques_mensais")

# Pick one year from a multi-year dataset
pemob_2023 <- get_dataset("pemob_anual", year = 2023)

# Pick a resource and an explicit format
pontos <- get_dataset(
  "qualidade_ar_mare",
  resource = "pontos",
  format = "gpkg"
)

# Return the data with its documentation
result <- get_dataset("embarques_mensais", docs = TRUE)
result$docs
}
if (FALSE) { # live_examples() && requireNamespace("sf", quietly = TRUE)
# Spatial datasets return an sf object
faixa_azul <- get_dataset("faixa_azul_sp")
}
```
