# Changelog

## inspercidados 0.4.0

- [`get_dataset()`](https://inspercidades.github.io/inspercidados/reference/get_dataset.md)
  now selects a logical `resource` before choosing a file `format`; raw
  `filename` and `file_pattern` selection moved to
  [`get_dataverse()`](https://inspercidades.github.io/inspercidados/reference/get_dataverse.md),
  and unregistered DOIs must now use that lower-level function. This is
  a breaking change.
- [`list_resources()`](https://inspercidades.github.io/inspercidados/reference/list_resources.md)
  lists the logical datasets, years, formats, and defaults available
  within a registered Dataverse deposit.
