# Download any Insper Dataverse dataset from a DOI or URL

Downloads a deposit that has no alias in the package registry. Copy the
DOI or the landing-page URL from Insper's Dataverse and paste it
straight into R.

## Usage

``` r
get_dataverse(
  x,
  filename = NULL,
  file_pattern = NULL,
  year = NULL,
  files = FALSE
)
```

## Arguments

- x:

  A DOI (`"10.60873/FK2/AOLEOI"`), a DOI URL, or a Dataverse
  landing-page URL containing `persistentId=doi:...`.

- filename, file_pattern, year:

  Optional selectors passed to the same file-picking logic used by
  [`get_dataset()`](https://inspercidades.github.io/inspercidados/reference/get_dataset.md).

- files:

  Logical. If `TRUE`, list the deposit's files and return their names
  instead of downloading anything. Useful for inspecting an unfamiliar
  deposit first.

## Value

A [tibble](https://tibble.tidyverse.org/reference/tibble.html) or `sf`
object with the `"doi"` attribute set. When `files = TRUE`, a character
vector of filenames.

## Details

Registered datasets are better served by
[`get_dataset()`](https://inspercidades.github.io/inspercidados/reference/get_dataset.md),
which knows which file to pick. This function has no such knowledge, so
it lists the deposit and applies the same format preference to whatever
it finds. Deposits with an unusual file layout may need `filename` or
`file_pattern` to resolve, and formats the package cannot read will
raise an error naming the file.

Only DOIs under the `10.60873` prefix are served, since the package
always talks to Insper's Dataverse.

## See also

[`get_dataset()`](https://inspercidades.github.io/inspercidados/reference/get_dataset.md)
for registered datasets.

## Examples

``` r
if (FALSE) { # live_examples()
# Inspect a deposit before downloading
get_dataverse("10.60873/FK2/YWXLQS", files = TRUE)

# Paste a DOI straight from the Dataverse page
linhas <- get_dataverse("10.60873/FK2/YWXLQS", filename = "dim_line.rds")

# Or the landing-page URL
linhas <- get_dataverse(
  paste0(
    "https://dataverse.datascience.insper.edu.br/dataset.xhtml?",
    "persistentId=doi:10.60873/FK2/YWXLQS"
  ),
  filename = "dim_line.rds"
)
}
```
