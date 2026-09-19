# filter_dv_format() treats format as a strict selector

    Code
      select_dv_file(parquet, year = 2023, strict = TRUE)
    Condition
      Error in `select_dv_file()`:
      ! No files matched `year` 2023.
      i Available data files: "dados_2024.parquet"

# select_dv_file() rejects ambiguous files in strict mode

    Code
      select_dv_file(files, prefer = "tab", strict = TRUE)
    Condition
      Error in `select_dv_file()`:
      ! Multiple files remain after applying the dataset selectors.
      i Use `year`, `resource`, or `format` to be more specific.
      i Matched files: "pemob_2022.tab" and "pemob_2023.tab"

