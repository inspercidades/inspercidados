# Stage coordinate-free copies of the Alvarás and ITBI deposits for a new DOI.
# Reads the latest deposit files from OneDrive, drops the location columns, and
# writes the files to new folders for upload. The source folders stay untouched.
# Run: Rscript data-raw/stage_restricted.R

library(cli)

datasets_dir <- Sys.getenv(
  "CIDADOS_DATASETS",
  "~/Library/CloudStorage/OneDrive-Insper/insper-cidades/cidados/datasets/dataverse"
)

# Owners may extend this list (SQL, address, CEP) before the deposit.
drop_cols <- c("geom", "geometry", "lat", "lng", "long")

# Helpers -----------------------------------------------------------------

stage_dir <- function(name) {
  path <- file.path(datasets_dir, name)
  dir.create(path, showWarnings = FALSE)
  path
}

drop_location <- function(df) {
  df <- as.data.frame(df)
  df[setdiff(names(df), drop_cols)]
}

check_staged <- function(path) {
  left <- intersect(names(arrow::open_dataset(path)), drop_cols)
  if (length(left) > 0) {
    cli_abort("{.file {path}} still has {.field {left}}.")
  }
  cli_alert_success("{.file {basename(path)}} has no location columns.")
}

# Alvarás -----------------------------------------------------------------

alvaras_src <- file.path(datasets_dir, "sp-alvaras-2")
alvaras_out <- stage_dir("sp-alvaras-3")

alvaras <- drop_location(
  arrow::read_parquet(file.path(alvaras_src, "alvaras.parquet"))
)

arrow::write_parquet(alvaras, file.path(alvaras_out, "alvaras.parquet"))
readr::write_csv(alvaras, file.path(alvaras_out, "alvaras.csv.gz"))
invisible(file.copy(
  file.path(alvaras_src, "Metadados - Alvaras.xlsx"),
  alvaras_out,
  overwrite = TRUE
))
check_staged(file.path(alvaras_out, "alvaras.parquet"))

# ITBI --------------------------------------------------------------------

itbi_src <- file.path(datasets_dir, "sp-itbi")
itbi_out <- stage_dir("sp-itbi-2")

itbi <- tibble::as_tibble(drop_location(
  arrow::read_parquet(file.path(itbi_src, "itbi.parquet"))
))

arrow::write_parquet(itbi, file.path(itbi_out, "itbi.parquet"))
readr::write_csv(itbi, file.path(itbi_out, "itbi.csv.gz"))
saveRDS(itbi, file.path(itbi_out, "itbi.rds"))

dict <- readr::read_csv(
  file.path(itbi_src, "dict_itbi.csv"),
  show_col_types = FALSE
)
dict <- dict[!dict[["Nome da Coluna"]] %in% drop_cols, ]
if (!setequal(dict[["Nome da Coluna"]], names(itbi))) {
  cli_abort("{.file dict_itbi.csv} does not match the staged ITBI columns.")
}
readr::write_csv(dict, file.path(itbi_out, "dict_itbi.csv"))
writexl::write_xlsx(dict, file.path(itbi_out, "dict_itbi.xlsx"))

invisible(file.copy(
  file.path(itbi_src, "Metadados - ITBI.xlsx"),
  itbi_out,
  overwrite = TRUE
))
check_staged(file.path(itbi_out, "itbi.parquet"))

cli_inform(c(
  "v" = "Staged {.path {alvaras_out}} and {.path {itbi_out}}.",
  "!" = "Both {.file Metadados} files still describe a georeferenced base."
))
