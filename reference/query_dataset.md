# Query a large dataset without downloading it

Opens a registered parquet dataset as a lazy table backed by DuckDB.
DuckDB reads the file directly from Insper Dataverse and fetches only
the columns and row groups a query needs, so large datasets such as
`"itbi_sp"` can be filtered and summarised without loading them into
memory. Use dplyr verbs to build the query and
[`dplyr::collect()`](https://dplyr.tidyverse.org/reference/compute.html)
to bring the result into R.

## Usage

``` r
query_dataset(dataset, ..., resource = NULL, year = NULL)
```

## Arguments

- dataset:

  A registered dataset alias, e.g. `"iptu_sp"`. See
  [`list_datasets()`](https://inspercidades.github.io/inspercidados/reference/list_datasets.md)
  for all aliases.

- ...:

  Must be empty. Arguments after `...` must be named.

- resource:

  The name of a logical resource within the registered dataset. When
  `NULL`, the resource marked as the default is used. See
  [`list_resources()`](https://inspercidades.github.io/inspercidados/reference/list_resources.md)
  for the available names.

- year:

  An integer or character year used to keep a single annual file. When
  `NULL`, every annual file is included.

## Value

A lazy
[dbplyr](https://dbplyr.tidyverse.org/reference/dbplyr-package.html)
table (`tbl_duckdb_connection`) with the `"doi"` attribute set.

## Details

Only resources distributed as parquet can be queried; use
[`get_dataset()`](https://inspercidades.github.io/inspercidados/reference/get_dataset.md)
for the others. When a resource is split into annual files and `year` is
`NULL`, all years are combined into one table.

DuckDB loads `httpfs` from its shared extension cache or installs it on
the first call. The cache is stored under `~/.duckdb`.

## See also

[`get_dataset()`](https://inspercidades.github.io/inspercidados/reference/get_dataset.md)
to download a dataset into memory.

## Examples

``` r
if (FALSE) { # live_examples() && rlang::is_installed(c("dbplyr", "duckdb"))
itbi <- query_dataset("itbi_sp")

# Transactions per year, computed by DuckDB
itbi |>
  dplyr::count(ano = dplyr::sql("year(data_de_transacao)")) |>
  dplyr::arrange(ano) |>
  dplyr::collect()
}
```
