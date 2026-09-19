# Open or download the R script for a dataset

**\[deprecated\]**

`get_script()` assumed one R script per dataset. Most datasets come from
a study whose pipeline spans many files, and several studies publish
more than one dataset, so scripts are now published as repositories. Use
[`open_project()`](https://inspercidades.github.io/inspercidados/reference/open_project.md)
instead.

## Usage

``` r
get_script(dataset, type = NULL, open = TRUE)
```

## Arguments

- dataset:

  A dataset alias.

- type:

  Ignored.

- open:

  Passed to
  [`open_project()`](https://inspercidades.github.io/inspercidados/reference/open_project.md).

## Value

The repository URL, invisibly.

## Examples

``` r
# Deprecated; use open_project() instead.
open_project("sinistros_sp", open = FALSE)
#> 
#> ── Faixa Azul e sinistros de trânsito ──────────────────────────────────────────
#> Project: "faixa_azul"
#> Datasets: "faixa_azul_sp", "sinistros_sp", and "sinistros_via_sp"
#> Repository: <https://github.com/inspercidades/faixa-azul>
```
