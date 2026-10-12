## First submission

This is the first CRAN submission of inspercidados. Version 0.5.0 adds lazy
parquet queries with `query_dataset()`, refreshes the dataset registry from
GitHub, and exposes curated data and documentation.

## Test environments

- Local: macOS Tahoe 26.6.2, R 4.5.1

## R CMD check results

0 errors | 0 warnings | 0 notes

## Additional checks

- A live `query_dataset("itbi_sp")` query read from Insper Dataverse.
- The live registry tests passed for the shipped datasets and resources.
- A live download of the 2004–2021 Alvarás parquet file passed.

There are no downstream dependencies.
