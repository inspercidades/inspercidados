# Open the study behind a dataset

Prints the study a dataset came from, the other datasets it produced,
and the repository holding its processing code, then opens that
repository in a browser.

## Usage

``` r
open_project(x, open = TRUE)
```

## Arguments

- x:

  A dataset alias (see
  [`list_datasets()`](https://inspercidades.github.io/inspercidados/reference/list_datasets.md))
  or a project slug (see
  [`list_projects()`](https://inspercidades.github.io/inspercidados/reference/list_projects.md)).

- open:

  Logical. If `TRUE` (default), open the repository in a browser when
  one is registered and the session is interactive.

## Value

The repository URL, invisibly, or `NULL` when no repository is
registered for the project.

## Details

Pipelines are published as repositories rather than as single scripts,
because one study normally produces several datasets across many files.
Some repositories are private and open only for Insper Cidades members;
[`list_projects()`](https://inspercidades.github.io/inspercidados/reference/list_projects.md)
reports which.

## Examples

``` r
# By dataset alias
open_project("sinistros_sp", open = FALSE)
#> 
#> ── Faixa Azul e sinistros de trânsito ──────────────────────────────────────────
#> Project: "faixa_azul"
#> Datasets: "faixa_azul_sp", "sinistros_sp", and "sinistros_via_sp"
#> Repository: <https://github.com/inspercidades/faixa-azul>

# By project slug
open_project("motiva", open = FALSE)
#> 
#> ── Embarques nas estações operadas pela Motiva ─────────────────────────────────
#> Project: "motiva"
#> Datasets: "embarques_hora", "embarques_diarios", "embarques_mensais",
#> "embarques_integracao", "linhas_motiva", and "estacoes_motiva"
#> Repository: <https://github.com/inspercidades/pipeline-motiva>
#> ! This repository is private. Opening it needs an Insper Cidades GitHub account.
```
