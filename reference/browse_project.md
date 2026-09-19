# Deprecated alias for open_project()

**\[soft-deprecated\]**

`browse_project()` was renamed to
[`open_project()`](https://inspercidades.github.io/inspercidados/reference/open_project.md)
to avoid the name conflict with `usethis::browse_project()`. It now
forwards to
[`open_project()`](https://inspercidades.github.io/inspercidados/reference/open_project.md)
and will be removed in a future release.

## Usage

``` r
browse_project(x, open = TRUE)
```

## Arguments

- x:

  A study, dataset alias.

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
