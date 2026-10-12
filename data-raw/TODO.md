# Deposit and catalog TODO

Backlog for the datasets the package serves. The package reads Insper's
Dataverse, but the deposits are uploaded by other people, so some items wait on
a push we do not control. Work through the checklist and delete items as they
land.

## Waiting on a Dataverse deposit

### `mortalidade_sp` (10.60873/FK2/CDXI9B)

Version 5.0 publishes only `distritos_sp.*`, `README.txt`, and
`Documentacao.tab`. The deposit README describes four table families that are
still missing.

- [ ] `serie_temporal_distrito/` (`time_series`, `geral_time_series`)
- [ ] `recorte_2019/` (`2019`, `geral_2019`)
- [ ] `tendencia_risco_relativo/` (`time_trends`, `geral_time_trends`)
- [ ] `mortalidade_materna/` (`indicadores_anuais`, `raca_cor`, `causa_obito`, `faixa_etaria`)
- [ ] Add the `mortalidade_materna` resource to `data-raw/resources.csv` and rebuild the registry

The pkgdown article `vignettes/articles/mortalidade-sp.Rmd` stays broken until
this lands.

## Catalog changes

The Google Sheet drives the registry through `data-raw/build_registry.R`. Make
the edit in the sheet, then rebuild.

- [ ] Add a `titulo_dataverse` column for the deposit title. Keep
      `titulo_da_base_de_dados` as the Portal Cidados title, since the two
      serve different readers and should not be forced to match.

## Repositories to build

These studies have no replication repository, so `open_project()` has nothing
to open. Build the repository, then add its URL and visibility to
`data-raw/projects.csv` and rebuild.

- [ ] `itbi` (Imposto sobre Transmissão de Bens Imóveis)
- [ ] `alvaras` (Alvarás de licenciamento de novas edificações)
- [ ] `mortalidade` (Indicadores de Mortalidade, São Paulo)
- [ ] `mare` (Ilhas de calor e qualidade do ar na Favela da Maré)
