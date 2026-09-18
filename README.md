
<!-- README.md is generated from README.Rmd. Please edit that file -->

# inspercidados

<!-- badges: start -->

[![R-CMD-check](https://github.com/inspercidades/inspercidados/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/inspercidades/inspercidados/actions/workflows/R-CMD-check.yaml)
[![Codecov test
coverage](https://codecov.io/gh/inspercidades/inspercidados/graph/badge.svg)](https://app.codecov.io/gh/inspercidades/inspercidados)
<!-- badges: end -->

**inspercidados** provides simple, reproducible access to curated
Brazilian urban research datasets hosted on [Insper’s
Dataverse](https://dataverse.datascience.insper.edu.br). It is a
lightweight wrapper around the
[`dataverse`](https://github.com/IQSS/dataverse-client-r) package that
lets researchers discover, download, and cite datasets with a few short
commands.

## Installation

You can install the development version of inspercidados from
[GitHub](https://github.com/portalcidados/inspercidados) with:

``` r
# install.packages("pak")
pak::pak("portalcidados/inspercidados")
```

## Core functions

| Function          | Purpose                                         |
|-------------------|-------------------------------------------------|
| `list_datasets()` | List or search available datasets               |
| `get_dataset()`   | Download a dataset into R                       |
| `cite_dataset()`  | Generate a citation for a dataset               |
| `get_script()`    | Open a companion analysis or replication script |

## Browse available datasets

`list_datasets()` returns a tibble of all datasets in the package
registry. No network call is made.

``` r
library(inspercidados)

list_datasets()
#> # A tibble: 21 × 11
#>    alias        title description theme region project access is_spatial formats
#>    <chr>        <chr> <chr>       <chr> <chr>  <chr>   <chr>  <lgl>      <chr>  
#>  1 itbi_sp      Impo… "Registros… Habi… São P… itbi    downl… FALSE      csv, p…
#>  2 iptu_sp      IPTU… "Informaçõ… Habi… São P… densid… downl… TRUE       geojso…
#>  3 alvaras_sp   Alva… "Informaçõ… Habi… São P… alvaras downl… TRUE       geojso…
#>  4 censo_setor… Popu… "Dados pro… Habi… São P… densid… downl… TRUE       geojso…
#>  5 iptu_vertic… IPTU… "Dados dem… Habi… São P… densid… downl… TRUE       geojso…
#>  6 densidade_i… Dens… "Cruzament… Habi… São P… densid… downl… TRUE       geojso…
#>  7 geoses_sp    Índi… "Índice so… Mult… São P… geoses  downl… TRUE       geojso…
#>  8 mortalidade… Mort… "Medidas d… Saúde São P… mortal… downl… FALSE      tab    
#>  9 ilhas_calor… Medi… "Estatísti… Clim… Rio d… mare    downl… TRUE       geojso…
#> 10 qualidade_a… Medi… "Estatísti… Clim… Rio d… mare    downl… TRUE       geojso…
#> # ℹ 11 more rows
#> # ℹ 2 more variables: keywords <chr>, doi <chr>
```

You can filter by alias, title, theme, region, or keywords:

``` r
list_datasets("Mobilidade")
#> # A tibble: 11 × 11
#>    alias        title description theme region project access is_spatial formats
#>    <chr>        <chr> <chr>       <chr> <chr>  <chr>   <chr>  <lgl>      <chr>  
#>  1 geoses_sp    Índi… Índice soc… Mult… São P… geoses  downl… TRUE       geojso…
#>  2 pemob_anual  Pesq… Base anual… Mobi… Brasil pemob   downl… FALSE      parque…
#>  3 pemob_harmo… Pesq… Base anual… Mobi… Brasil pemob   downl… FALSE      parque…
#>  4 embarques_h… Emba… Embarques … Mobi… Brasil motiva  downl… FALSE      csv, p…
#>  5 embarques_d… Emba… Total de e… Mobi… Brasil motiva  downl… FALSE      parque…
#>  6 embarques_m… Médi… Média de e… Mobi… Brasil motiva  downl… FALSE      rds, t…
#>  7 embarques_i… Emba… Embarques … Mobi… Brasil motiva  downl… FALSE      parque…
#>  8 estacoes_mo… Linh… Tabela de … Mobi… Brasil motiva  downl… FALSE      rds, t…
#>  9 faixa_azul_… Trec… Localizaçã… Mobi… São P… faixa_… downl… TRUE       geojso…
#> 10 sinistros_sp Sini… Sinistros … Mobi… São P… faixa_… downl… FALSE      parque…
#> 11 sinistros_v… Sini… Localizaçã… Mobi… São P… faixa_… downl… TRUE       geojso…
#> # ℹ 2 more variables: keywords <chr>, doi <chr>
```

## Download a dataset

Datasets can be identified by their short alias, a bare DOI, or a full
DOI URL:

``` r
# By alias
embarques <- get_dataset("embarques_mensais")

# By DOI
embarques <- get_dataset("10.60873/FK2/BPYHFB")

# Filter by year for multi-year datasets
pemob_2023 <- get_dataset("pemob_anual", year = 2023)

# Request a specific file or pattern
geo <- get_dataset("iptu_sp", filename = "iptu_2024.gpkg")
```

Pass `docs = TRUE` to return the dataset together with its
documentation:

``` r
result <- get_dataset("iptu_sp", docs = TRUE)
result$data
result$docs
```

## Cite a dataset

`cite_dataset()` fetches metadata from Dataverse and returns a citation
in plain text (default), BibTeX, or RIS:

``` r
cite_dataset("embarques_mensais")
cite_dataset("embarques_mensais", format = "bibtex")
cite_dataset("embarques_mensais", format = "ris")
```

## Companion R scripts

Some datasets ship with a companion script that demonstrates how to load
and explore the data, or documents the production pipeline that
generated it:

``` r
# Open the analysis script in your editor
get_script("embarques_mensais")

# Open the replication pipeline (typically not runnable by external users)
get_script("embarques_mensais", type = "replication")
```

## Learn more

- `vignette("getting-started", package = "inspercidados")`
- Full reference: <https://portalcidados.github.io/inspercidados>
- Data source: <https://dataverse.datascience.insper.edu.br>
