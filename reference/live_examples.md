# Decide whether examples that download data should run

Used in `@examplesIf` so examples hit Insper Dataverse only when that is
safe. They run during `devtools::check()`, `devtools::run_examples()`,
and pkgdown builds, and are skipped on CRAN, offline, or when the server
is down.

## Usage

``` r
live_examples(timeout = 5)
```

## Arguments

- timeout:

  Seconds to wait for the server to answer.

## Value

`TRUE` when the `NOT_CRAN` or `IN_PKGDOWN` environment variable is
`"true"` and the Dataverse API answers, `FALSE` otherwise. Always
`FALSE` when the curl package is not installed.

## Examples

``` r
live_examples()
#> [1] FALSE
```
