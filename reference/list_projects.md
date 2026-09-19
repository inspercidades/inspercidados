# List the studies behind the datasets

Each dataset comes from a research project with its own processing
pipeline. One project usually produces several datasets, so pipelines
are published as whole repositories rather than as a single script per
dataset.

## Usage

``` r
list_projects(project = NULL)
```

## Arguments

- project:

  Optional project slug or regular expression to filter on.

## Value

A [tibble](https://tibble.tidyverse.org/reference/tibble.html) with
columns `project`, `title`, `repo_url`, `visibility`, `n_datasets`, and
`datasets`. `repo_url` is `NA` for projects whose code has not been
published yet, and `visibility` is `"private"` for repositories that
only Insper Cidades members can open.

## See also

[`browse_project()`](https://inspercidades.github.io/inspercidados/reference/browse_project.md)
to open a repository,
[`list_datasets()`](https://inspercidades.github.io/inspercidados/reference/list_datasets.md)
for the datasets themselves.

## Examples

``` r
list_projects()
#> # A tibble: 9 × 6
#>   project     title                      repo_url visibility n_datasets datasets
#>   <chr>       <chr>                      <chr>    <chr>           <int> <chr>   
#> 1 itbi        Imposto sobre Transmissão… NA       NA                  1 itbi_sp 
#> 2 densidade   Densidade Populacional e … https:/… public              4 iptu_sp…
#> 3 alvaras     Alvarás de licenciamento … NA       NA                  1 alvaras…
#> 4 geoses      Índice GeoSES              https:/… public              1 geoses_…
#> 5 mortalidade Mortalidade prematura por… NA       NA                  1 mortali…
#> 6 mare        Ilhas de calor e qualidad… NA       NA                  3 ilhas_c…
#> 7 pemob       Pesquisa Nacional de Mobi… https:/… public              2 pemob_a…
#> 8 motiva      Embarques nas estações op… https:/… private             6 embarqu…
#> 9 faixa_azul  Faixa Azul e sinistros de… https:/… public              3 faixa_a…
list_projects("motiva")
#> # A tibble: 1 × 6
#>   project title                          repo_url visibility n_datasets datasets
#>   <chr>   <chr>                          <chr>    <chr>           <int> <chr>   
#> 1 motiva  Embarques nas estações operad… https:/… private             6 embarqu…
```
