# Getting started with inspercidados

``` r

library(inspercidados)
```

`inspercidados` gives you direct access to datasets from [Insper
Cidades](https://www.insper.edu.br/pt/pesquisa/centro-de-estudos-das-cidades),
hosted on [Insper’s
Dataverse](https://dataverse.datascience.insper.edu.br). Insper Cidades
is a multidisciplinary research center at Insper, and the datasets come
from publications by its authors. The [Cidados
website](https://cidados.insper.edu.br) features these publications as
data visualization narratives.

## Open science

The package is part of a suite of open science initiatives at Insper. It
supports open and reproducible research in two ways.

- **Findable and accessible open data.** The package ships a registry
  that gives each dataset a stable alias and a DOI, so anyone can find
  and download the same data with one call.
- **Transparency and replication.** Most datasets come from research
  projects whose pipelines are published as repositories.
  [`open_project()`](https://inspercidades.github.io/inspercidados/reference/open_project.md)
  takes you from a dataset to the code that produced it.

## Installation

Install the release from R-universe.

``` r

install.packages(
  "inspercidados",
  repos = c(
    "https://inspercidades.r-universe.dev",
    "https://cloud.r-project.org"
  )
)
```

Or install the development version from GitHub.

``` r

# install.packages("pak")
pak::pak("inspercidades/inspercidados")
```

## Using the package

[`list_datasets()`](https://inspercidades.github.io/inspercidados/reference/list_datasets.md)
reads the registry that ships with the package and makes no network
calls.

``` r

list_datasets()
```

To search by alias, title, theme, region, or keywords, use the `search`
argument of
[`list_datasets()`](https://inspercidades.github.io/inspercidados/reference/list_datasets.md).

``` r

list_datasets(search = "Mobilidade")
```

Each registered dataset has a short alias. Some aliases contain several
logical resources. `qualidade_ar_mare`, for example, ships its
measurements and the coordinates of its measurement points as separate
resources. Each resource may ship in several file formats or be split by
year. Use
[`list_resources()`](https://inspercidades.github.io/inspercidados/reference/list_resources.md)
to inspect the resources of an alias without a network request.

``` r

list_resources("qualidade_ar_mare")
```

Use
[`get_dataset()`](https://inspercidades.github.io/inspercidados/reference/get_dataset.md)
to download a dataset by its alias. The `year`, `resource`, and `format`
arguments narrow the download.

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

## Cite a dataset

[`cite_dataset()`](https://inspercidades.github.io/inspercidados/reference/cite_dataset.md)
fetches metadata from Dataverse and returns a citation in plain text,
BibTeX, or RIS.

``` r

cite_dataset("embarques_mensais")
cite_dataset("embarques_mensais", format = "bibtex")
```

## Explore the study behind a dataset

[`open_project()`](https://inspercidades.github.io/inspercidados/reference/open_project.md)
prints the study, lists its datasets, and opens the repository. Private
repositories are flagged before they open.

``` r

open_project("embarques_mensais")
```

## Next steps

The full function reference is at
<https://inspercidades.github.io/inspercidados>.
[`get_dataverse()`](https://inspercidades.github.io/inspercidados/reference/get_dataverse.md)
downloads any Insper Dataverse deposit, registered or not, from a pasted
DOI or URL.
[`list_projects()`](https://inspercidades.github.io/inspercidados/reference/list_projects.md)
lists the studies behind the datasets and their repositories.
