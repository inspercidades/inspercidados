# inspercidados 0.4.0

- `get_dataset()` now selects a logical `resource` before choosing a file `format`; raw `filename` and `file_pattern` selection moved to `get_dataverse()`, and unregistered DOIs must now use that lower-level function. This is a breaking change.
- `list_resources()` lists the logical datasets, years, formats, and defaults available within a registered Dataverse deposit.
