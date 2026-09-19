# Generate a citation for a dataset

Fetches metadata from Insper Dataverse and returns a formatted citation.
The citation is printed to the console and returned invisibly as a
character string.

## Usage

``` r
cite_dataset(dataset, format = c("text", "bibtex", "ris"))
```

## Arguments

- dataset:

  A dataset identifier: alias, bare DOI, or DOI URL (see
  [`get_dataset()`](https://inspercidades.github.io/inspercidados/reference/get_dataset.md)
  for details).

- format:

  Citation format. One of `"text"` (default), `"bibtex"`, or `"ris"`.

## Value

A character string containing the formatted citation (invisible).

## Examples

``` r
if (FALSE) { # live_examples()
# Plain-text citation
cite_dataset("pemob_anual")

# BibTeX
cite_dataset("pemob_anual", format = "bibtex")

# RIS (Zotero, Mendeley, EndNote)
cite_dataset("pemob_anual", format = "ris")
}
```
