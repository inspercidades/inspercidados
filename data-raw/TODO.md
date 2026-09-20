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

### Dictionary workbooks (optional)

Five deposits ship `dict_*` files that no resource or documentation pattern
matches, so users cannot reach them.

- [ ] Decide whether to expose the dictionaries. If yes, add a
      `documentation_pattern` to each resource in `data-raw/resources.csv`.
  - [ ] `dict_itbi.*` for `itbi_sp`
  - [ ] `dict_geoses.*` for `geoses_sp`
  - [ ] `dict_faixa_azul.*` for `faixa_azul_sp`
  - [ ] `dict_sinistros.*` for `sinistros_sp`
  - [ ] `dict_trechos_agregados_sinistros.*` for `sinistros_via_sp`

## Catalog changes

The Google Sheet drives the registry through `data-raw/build_registry.R`. Make
the edit in the sheet, then rebuild.

- [ ] Delete the "Gastos com UBS por distrito [2019]" row. The study was
      discontinued, so it is neither a secure-room nor a pending deposit.
- [ ] Add a `titulo_dataverse` column for the deposit title. Keep
      `titulo_da_base_de_dados` as the Portal Cidados title, since the two
      serve different readers and should not be forced to match.
- [ ] Confirm every row sets the access column to either
      "Disponível para download" or "Sala segura do Insper".
- [ ] Confirm the secure-room rows (iFood, QuintoAndar, Loft) are marked
      "Sala segura do Insper". They carry no DOI by design and never will.

## Repositories to build

These studies have no replication repository, so `open_project()` has nothing
to open. Build the repository, then add its URL and visibility to
`data-raw/projects.csv` and rebuild.

- [ ] `itbi` (Imposto sobre Transmissão de Bens Imóveis)
- [ ] `alvaras` (Alvarás de licenciamento de novas edificações)
- [ ] `mortalidade` (Indicadores de Mortalidade, São Paulo)
- [ ] `mare` (Ilhas de calor e qualidade do ar na Favela da Maré)
