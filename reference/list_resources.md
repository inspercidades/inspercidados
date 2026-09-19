# List a dataset's logical resources

Returns the logical resources registered within a dataset. A resource is
one dataset that may be distributed in several file formats or split by
a declared dimension such as year. The information comes from the local
registry, so no network call is made.

## Usage

``` r
list_resources(dataset)
```

## Arguments

- dataset:

  A registered dataset alias. See
  [`list_datasets()`](https://inspercidades.github.io/inspercidados/reference/list_datasets.md).

## Value

A [tibble](https://tibble.tidyverse.org/reference/tibble.html) with one
row per resource and columns `resource`, `title`, `is_spatial`, `years`,
`formats`, and `default`.

## See also

[`get_dataset()`](https://inspercidades.github.io/inspercidados/reference/get_dataset.md)
to download a resource.

## Examples

``` r
list_resources("qualidade_ar_mare")
#> # A tibble: 2 × 6
#>   resource title                                is_spatial years formats default
#>   <chr>    <chr>                                <lgl>      <chr> <chr>   <lgl>  
#> 1 dados    Medições de qualidade do ar          FALSE      NA    parque… TRUE   
#> 2 pontos   Pontos das medições de qualidade do… TRUE       NA    geojso… FALSE  
list_resources("pemob_anual")
#> # A tibble: 1 × 6
#>   resource title                 is_spatial years                formats default
#>   <chr>    <chr>                 <lgl>      <chr>                <chr>   <lgl>  
#> 1 dados    Bases anuais da PEMOB FALSE      2019, 2020, 2021, 2… parque… TRUE   
```
