# inspercidados 0.5.0

- Added `query_dataset()`, which opens a parquet dataset as a lazy DuckDB table that reads from Dataverse without downloading the whole file.
- Changed the registry to load from GitHub once per session, so datasets added after a release appear without reinstalling. The package falls back to its shipped copy when GitHub cannot be reached, and `options(inspercidados.registry = "bundled")` forces the shipped copy.

# inspercidados 0.4.0

- Added `list_resources()`, which lists the logical datasets, years, formats, and defaults within a registered deposit.
- Added validation for malformed `get_dataverse()` file selectors.
- Changed `get_dataset()` to select a logical `resource` before choosing a file `format`. This is a breaking change.
- Moved raw `filename` and `file_pattern` selection from `get_dataset()` to `get_dataverse()`. Unregistered DOIs now go through `get_dataverse()`.
- Renamed `browse_project()` to `open_project()` to avoid a conflict with `usethis::browse_project()`. `browse_project()` still works but warns.
- Deprecated `get_script()` in favor of `open_project()`, since pipelines are now published as repositories.
