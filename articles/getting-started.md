# Getting started with inspercidados

``` r

library(inspercidados)
```

`inspercidados` gives users direct access to curated datasets hosted on
[Insper’s Dataverse](https://dataverse.datascience.insper.edu.br). These
datasets come from research publications made by authors related to
[Insper
Cidades](https://www.insper.edu.br/pt/pesquisa/centro-de-estudos-das-cidades),
and that are featured as data visualization narratives on the [Cidados
website](https://cidados.insper.edu.br).

## Open science

This package is a core element in a suite of open science initiatives
from Insper. It supports open and reproducible research in two ways:

- **Findable and accessible open data.** The package registers each
  dataset with a stable alias and a DOI, so anyone can find and download
  the same data with one call.
- **Transparency and replication.** Datasets come from research projects
  whose pipelines are published as repositories.
  [`open_project()`](https://inspercidades.github.io/inspercidados/reference/open_project.md)
  takes you from a dataset to the code that produced it.

## Installation

The package is available on R-universe:

``` r

install.packages(
  "inspercidados",
  repos = c(
    "https://inspercidades.r-universe.dev",
    "https://cloud.r-project.org"
  )
)
```

The development version is available on GitHub.

``` r

# install.packages("pak")
pak::pak("inspercidades/inspercidados")
```

## Using the package

[`list_datasets()`](https://inspercidades.github.io/inspercidados/reference/list_datasets.md)
reads the registry that ships with the package; it makes no network
calls.

``` r

list_datasets()
```

To search by title, theme, region, or keywords use the `search` argument
in `list_dataset()`

``` r

list_datasets(search = "Mobilidade")
```

Each registered dataset has a short alias. Use
[`get_dataset()`](https://inspercidades.github.io/inspercidados/reference/get_dataset.md)
to download it.

``` r

# By alias
embarques <- get_dataset("embarques_mensais")

# Filter by year in multi-year datasets
pemob_2023 <- get_dataset("pemob_anual", year = 2023)

# Select one logical resource and file format
pontos <- get_dataset(
  "qualidade_ar_mare",
  resource = "pontos",
  format = "gpkg"
)
```

Some Dataverse deposits contain several logical datasets. Use
[`list_resources()`](https://inspercidades.github.io/inspercidados/reference/list_resources.md)
to inspect them without making a network request.

``` r

list_resources("qualidade_ar_mare")
```

## Cite a dataset

``` r

cite_dataset("embarques_mensais")
```

## Next steps

The full reference is at
<https://inspercidades.github.io/inspercidados>.
