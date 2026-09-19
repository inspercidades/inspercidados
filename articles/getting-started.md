# Getting started with inspercidados

``` r

library(inspercidados)
```

inspercidados gives R users direct access to curated Brazilian urban
research datasets hosted on [Insper’s
Dataverse](https://dataverse.datascience.insper.edu.br). It is a thin
wrapper around the
[`dataverse`](https://github.com/IQSS/dataverse-client-r) package.

## Open science

The package supports open and reproducible research in three ways:

- **Findable and accessible data.** Urban research data for Brazil is
  scattered across portals and formats. The package registers each
  dataset with a stable alias and a DOI, so anyone can find and download
  the same data with one call.
- **Proper attribution.** Published research often overlooks the
  datasets behind its results.
  [`cite_dataset()`](https://inspercidades.github.io/inspercidados/reference/cite_dataset.md)
  makes citing the data as easy as citing a paper.
- **Transparency of methods.** Datasets come from research projects
  whose pipelines are published as repositories.
  [`browse_project()`](https://inspercidades.github.io/inspercidados/reference/browse_project.md)
  takes you from a dataset to the code that produced it.

## Installation

``` r

# install.packages("pak")
pak::pak("inspercidades/inspercidados")
```

## List datasets

[`list_datasets()`](https://inspercidades.github.io/inspercidados/reference/list_datasets.md)
reads the registry that ships with the package; it makes no network
calls:

``` r

list_datasets()
#> # A tibble: 22 × 11
#>    alias        title description theme region project access is_spatial formats
#>    <chr>        <chr> <chr>       <chr> <chr>  <chr>   <chr>  <lgl>      <chr>  
#>  1 itbi_sp      Impo… "Registros… Habi… São P… itbi    downl… FALSE      csv, p…
#>  2 iptu_sp      IPTU… "Informaçõ… Habi… São P… densid… downl… TRUE       geojso…
#>  3 alvaras_sp   Alva… "Informaçõ… Habi… São P… alvaras downl… TRUE       geojso…
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

Search by title, theme, region, or keywords:

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

Identify a dataset by its short alias, a bare DOI, or a full DOI URL:

``` r

# By alias
embarques <- get_dataset("embarques_mensais")

# Filter by year in multi-year datasets
pemob_2023 <- get_dataset("pemob_anual", year = 2023)
```

## Cite a dataset

``` r

cite_dataset("embarques_mensais")
```

## Next steps

The full reference is at
<https://inspercidades.github.io/inspercidados>.
