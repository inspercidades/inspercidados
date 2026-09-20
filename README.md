
<!-- README.md is generated from README.Rmd. Please edit that file -->

# inspercidados

<!-- badges: start -->

[![R-CMD-check](https://github.com/inspercidades/inspercidados/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/inspercidades/inspercidados/actions/workflows/R-CMD-check.yaml)
[![Codecov test
coverage](https://codecov.io/gh/inspercidades/inspercidados/graph/badge.svg)](https://app.codecov.io/gh/inspercidades/inspercidados)
<!-- badges: end -->

**inspercidados** gives R users direct access to curated Brazilian urban
research datasets hosted on [Insper’s
Dataverse](https://dataverse.datascience.insper.edu.br). It wraps
[`dataverse`](https://github.com/IQSS/dataverse-client-r) so you can
find, download, and cite datasets in a few short commands.

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

Or the development version from
[GitHub](https://github.com/inspercidades/inspercidados).

``` r
# install.packages("pak")
pak::pak("inspercidades/inspercidados")
```

## Core functions

| Function           | Purpose                                          |
|--------------------|--------------------------------------------------|
| `list_datasets()`  | List or search available datasets                |
| `list_resources()` | List logical resources within a dataset          |
| `get_dataset()`    | Download a dataset into R                        |
| `get_dataverse()`  | Inspect or download any Insper Dataverse deposit |
| `cite_dataset()`   | Generate a citation for a dataset                |
| `open_project()`   | Open the study repository behind a dataset       |

## Browse available datasets

`list_datasets()` returns a tibble of every dataset in the registry. The
registry ships with the package, so no network call is needed.

``` r
library(inspercidados)

list_datasets()
#> # A tibble: 22 × 11
#>    alias        title description theme region project access is_spatial formats
#>    <chr>        <chr> <chr>       <chr> <chr>  <chr>   <chr>  <lgl>      <chr>  
#>  1 itbi_sp      Impo… "Registros… Habi… São P… itbi    downl… FALSE      csv, p…
#>  2 iptu_sp      IPTU… "Informaçõ… Habi… São P… densid… downl… TRUE       geojso…
#>  3 alvaras_sp   Alva… "Agregação… Habi… São P… alvaras downl… TRUE       geojso…
#>  4 censo_setor… Popu… "Dados pro… Habi… São P… densid… downl… TRUE       geojso…
#>  5 iptu_vertic… IPTU… "Dados dem… Habi… São P… densid… downl… TRUE       geojso…
#>  6 densidade_i… Dens… "Cruzament… Habi… São P… densid… downl… TRUE       geojso…
#>  7 geoses_sp    Índi… "Índice so… Mult… São P… geoses  downl… TRUE       geojso…
#>  8 mortalidade… Mort… "Medidas d… Saúde São P… mortal… downl… TRUE       geojso…
#>  9 ilhas_calor… Medi… "Estatísti… Clim… Rio d… mare    downl… TRUE       geojso…
#> 10 qualidade_a… Medi… "Estatísti… Clim… Rio d… mare    downl… TRUE       geojso…
#> # ℹ 12 more rows
#> # ℹ 2 more variables: keywords <chr>, doi <chr>
```

Search by alias, title, theme, region, or keywords.

``` r
list_datasets("Mobilidade")
#> # A tibble: 12 × 11
#>    alias        title description theme region project access is_spatial formats
#>    <chr>        <chr> <chr>       <chr> <chr>  <chr>   <chr>  <lgl>      <chr>  
#>  1 geoses_sp    Índi… Índice soc… Mult… São P… geoses  downl… TRUE       geojso…
#>  2 pemob_anual  Pesq… Base anual… Mobi… Brasil pemob   downl… FALSE      parque…
#>  3 pemob_harmo… Pesq… Base anual… Mobi… Brasil pemob   downl… FALSE      parque…
#>  4 embarques_h… Emba… Embarques … Mobi… Brasil motiva  downl… FALSE      csv, p…
#>  5 embarques_d… Emba… Total de e… Mobi… Brasil motiva  downl… FALSE      parque…
#>  6 embarques_m… Médi… Média de e… Mobi… Brasil motiva  downl… FALSE      rds, t…
#>  7 embarques_i… Emba… Embarques … Mobi… Brasil motiva  downl… FALSE      parque…
#>  8 linhas_moti… Linh… Tabela de … Mobi… Brasil motiva  downl… FALSE      rds, t…
#>  9 estacoes_mo… Linh… Tabela de … Mobi… Brasil motiva  downl… FALSE      rds, t…
#> 10 faixa_azul_… Trec… Localizaçã… Mobi… São P… faixa_… downl… TRUE       geojso…
#> 11 sinistros_sp Sini… Sinistros … Mobi… São P… faixa_… downl… FALSE      parque…
#> 12 sinistros_v… Sini… Localizaçã… Mobi… São P… faixa_… downl… TRUE       geojso…
#> # ℹ 2 more variables: keywords <chr>, doi <chr>
```

## Download a dataset

Pass a short alias to download a registered dataset.

``` r
# By alias
embarques <- get_dataset("embarques_mensais")

# Filter by year in multi-year datasets
pemob_2023 <- get_dataset("pemob_anual", year = 2023)

# Select a logical resource and format
pontos <- get_dataset(
  "qualidade_ar_mare",
  resource = "pontos",
  format = "gpkg"
)
```

`list_resources()` shows the logical datasets and formats inside a
registered deposit.

``` r
list_resources("qualidade_ar_mare")
#> # A tibble: 2 × 6
#>   resource title                                is_spatial years formats default
#>   <chr>    <chr>                                <lgl>      <chr> <chr>   <lgl>  
#> 1 dados    Medições de qualidade do ar          FALSE      <NA>  parque… TRUE   
#> 2 pontos   Pontos das medições de qualidade do… TRUE       <NA>  geojso… FALSE
```

For an unregistered DOI or a physical filename, use `get_dataverse()`.

Set `docs = TRUE` to return the data alongside its documentation.

``` r
result <- get_dataset("iptu_sp", docs = TRUE)
result$data
result$docs
```

## Cite a dataset

`cite_dataset()` fetches metadata from Dataverse and returns a citation
in plain text, BibTeX, or RIS.

``` r
cite_dataset("embarques_mensais")
cite_dataset("embarques_mensais", format = "bibtex")
cite_dataset("embarques_mensais", format = "ris")
```

## Explore the study behind a dataset

Most datasets come from a research study whose pipeline lives in its own
repository. `open_project()` prints the study, lists its datasets, and
opens the repository.

``` r
open_project("embarques_mensais")
```

## Learn more

- Full reference: <https://inspercidades.github.io/inspercidados>
- Data source: <https://dataverse.datascience.insper.edu.br>
