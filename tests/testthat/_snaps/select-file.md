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

# select_dv_file() rejects malformed selectors

    Code
      select_dv_file(files, filename = c("a.csv", "b.csv"))
    Condition
      Error in `select_dv_file()`:
      ! `filename` must be a single non-empty string or `NULL`.

---

    Code
      select_dv_file(files, file_pattern = NA_character_)
    Condition
      Error in `select_dv_file()`:
      ! `file_pattern` must be a single non-empty string or `NULL`.

---

    Code
      select_dv_file(files, file_pattern = "[")
    Condition
      Error in `select_dv_file()`:
      ! `file_pattern` must be a valid regular expression.

---

    Code
      select_dv_file(files, year = c(2022, 2023))
    Condition
      Error in `select_dv_file()`:
      ! `year` must be a single value or `NULL`.

