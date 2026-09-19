# get_dataset() requires a registered alias

    Code
      get_dataset("10.60873/FK2/TOXCRF")
    Condition
      Error in `get_dataset()`:
      ! `get_dataset()` requires a registered dataset alias.
      i Use `get_dataverse()` to download a DOI or Dataverse URL.

# get_dataset() rejects removed file selectors

    Code
      get_dataset("iptu_sp", filename = "iptu_residencial.gpkg")
    Condition
      Error in `get_dataset()`:
      ! `...` must be empty.
      x Problematic argument:
      * filename = "iptu_residencial.gpkg"

# get_dataset() validates resource names before downloading

    Code
      get_dataset("qualidade_ar_mare", resource = "estacoes")
    Condition
      Error in `get_dataset()`:
      ! Resource "estacoes" is not available for "qualidade_ar_mare".
      i Available resources: "dados" and "pontos"

# get_dataset() validates year before downloading

    Code
      get_dataset("pemob_anual", year = c(2023, 2024))
    Condition
      Error in `get_dataset()`:
      ! `year` must be a single value or `NULL`.

# list_resources() requires a registered alias

    Code
      list_resources("10.60873/FK2/TOXCRF")
    Condition
      Error in `list_resources()`:
      ! `list_resources()` requires a registered dataset alias.
      i Run `list_datasets()` to see available aliases.
