# parquet_file_urls() aborts when no parquet file matches

    Code
      parquet_file_urls(files, "^pemob_[0-9]{4}[.]", year = 2024)
    Condition
      Error in `parquet_file_urls()`:
      ! No parquet file matched this resource for `year` 2024.
      i Files present: "pemob_2023.parquet" and "pemob_2024.xlsx"

# query_dataset() requires a registered alias

    Code
      query_dataset("10.60873/FK2/AOLEOI")
    Condition
      Error in `query_dataset()`:
      ! `query_dataset()` requires a registered dataset alias.
      i Run `inspercidados::list_datasets()` to see available aliases.

# query_dataset() rejects resources without parquet files

    Code
      query_dataset("embarques_mensais")
    Condition
      Error in `query_dataset()`:
      ! Resource "dados" of "embarques_mensais" has no parquet file.
      i Use `inspercidados::get_dataset("embarques_mensais")` instead.

# query_dataset() validates year before querying

    Code
      query_dataset("pemob_anual", year = c(2023, 2024))
    Condition
      Error in `query_dataset()`:
      ! `year` must be a single value or `NULL`.

