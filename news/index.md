# Changelog

## inspercidados 0.5.0

- Changed the registry to load from GitHub once per session, so datasets
  added after a release appear without reinstalling. The package falls
  back to its shipped copy when GitHub cannot be reached, and
  `options(inspercidados.registry = "bundled")` forces the shipped copy.

## inspercidados 0.4.0

- Added
  [`list_resources()`](https://inspercidades.github.io/inspercidados/reference/list_resources.md),
  which lists the logical datasets, years, formats, and defaults within
  a registered deposit.
- Added validation for malformed
  [`get_dataverse()`](https://inspercidades.github.io/inspercidados/reference/get_dataverse.md)
  file selectors.
- Changed
  [`get_dataset()`](https://inspercidades.github.io/inspercidados/reference/get_dataset.md)
  to select a logical `resource` before choosing a file `format`. This
  is a breaking change.
- Moved raw `filename` and `file_pattern` selection from
  [`get_dataset()`](https://inspercidades.github.io/inspercidados/reference/get_dataset.md)
  to
  [`get_dataverse()`](https://inspercidades.github.io/inspercidados/reference/get_dataverse.md).
  Unregistered DOIs now go through
  [`get_dataverse()`](https://inspercidades.github.io/inspercidados/reference/get_dataverse.md).
- Renamed
  [`browse_project()`](https://inspercidades.github.io/inspercidados/reference/browse_project.md)
  to
  [`open_project()`](https://inspercidades.github.io/inspercidados/reference/open_project.md)
  to avoid a conflict with `usethis::browse_project()`.
  [`browse_project()`](https://inspercidades.github.io/inspercidados/reference/browse_project.md)
  still works but warns.
- Deprecated
  [`get_script()`](https://inspercidades.github.io/inspercidados/reference/get_script.md)
  in favor of
  [`open_project()`](https://inspercidades.github.io/inspercidados/reference/open_project.md),
  since pipelines are now published as repositories.
