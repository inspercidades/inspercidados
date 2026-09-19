# Resource API mockup -----------------------------------------------------

# This script illustrates the proposed user API. It is intentionally not an
# implementation and is not run as part of the package tests.

library(inspercidados)


# Simple deposit ----------------------------------------------------------

# Nothing changes when a deposit contains one logical resource in several
# formats. The package selects the resource and its preferred readable format.
iptu <- get_dataset("iptu_sp")

# Users may request a format when reproducibility or object type matters.
iptu_parquet <- get_dataset("iptu_sp", format = "parquet")


# Discovering resources --------------------------------------------------

# Resource metadata comes from the package registry, so discovery is fast and
# works offline. One row represents one logical dataset, not one physical file.
list_resources("qualidade_ar_mare")

#> # A tibble: 2 x 6
#>   resource title                              is_spatial years formats       default
#>   <chr>    <chr>                              <lgl>      <chr> <chr>         <lgl>
#> 1 dados    Medições de qualidade do ar        FALSE      <NA>  parquet, tab  TRUE
#> 2 pontos   Pontos das medições de qualidade…  TRUE       <NA>  geojson, gpkg FALSE

# Deposit with multiple resources ---------------------------------------

# A declared default keeps the common call concise.
qualidade_ar <- get_dataset("qualidade_ar_mare")

# Use a stable resource name to select another logical dataset. Naming this
# argument is clearer than relying on its position.
pontos <- get_dataset(
  "qualidade_ar_mare",
  resource = "pontos"
)

# Format selection happens only after resource selection.
distritos <- get_dataset(
  "mortalidade_sp",
  resource = "distritos",
  format = "gpkg"
)

# If no default exists, the package must not guess.
# get_dataset("a_deposit_without_a_default")
#> Error:
#> ! `a_deposit_without_a_default` contains multiple resources.
#> i Choose one with `resource`: "households", "people", or "places".
#> i Run `list_resources("a_deposit_without_a_default")` for details.

# Resources with dimensions ---------------------------------------------

# `year` remains a semantic selector and is applied within the resource.
pemob_2023 <- get_dataset("pemob_anual", year = 2023)

# The annual and harmonized datasets retain their existing aliases.
list_resources("pemob_anual")

#> # A tibble: 1 x 6
#>   resource title                   is_spatial years     formats            default
#>   <chr>    <chr>                   <lgl>      <chr>     <chr>              <lgl>
#> 1 dados    Bases anuais da PEMOB   FALSE      2019, …   parquet, tab, xlsx TRUE

# Documentation ----------------------------------------------------------

# Documentation follows the selected resource. Deposit-level metadata is used
# when no resource-specific documentation exists.
result <- get_dataset(
  "qualidade_ar_mare",
  resource = "dados",
  docs = TRUE
)

result$data
result$docs


# Low-level escape hatch -------------------------------------------------

# Physical filenames and regular expressions belong to the low-level API.
raw_file <- get_dataverse(
  "10.60873/FK2/CDXI9B",
  filename = "distritos_sp.gpkg"
)

# `get_dataset()` should not allow a filename to escape the selected resource.
# Advanced access remains possible through `get_dataverse()`.

# Proposed signature -----------------------------------------------------

# get_dataset <- function(
#   dataset,
#   ...,
#   resource = NULL,
#   year = NULL,
#   format = NULL,
#   docs = FALSE
# )

# Placing `...` after `dataset` makes all selectors explicitly named. During a
# this breaking release, positional selector arguments are rejected.
