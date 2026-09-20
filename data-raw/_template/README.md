# Dataset: [DATASET NAME]

## Overview
Brief description of what this dataset contains and its importance for research.

## Dataverse Metadata

Dataverse has a set of metadata fields that are required for proper dataset citation and discovery.

### Obligatory fields
| Field | Description |
|-------|-------------|
| Title | Full descriptive title. |
| Subtitle | Subtitle describing the dataset. |
| Author(s) | Author(s) of the dataset. |
| Contact | A contact person (e.g. e-mail address) for the dataset. |
| Description | A comprehensive description of the dataset. |
| Subject | List of keywords that describe the dataset (minimum 3). |
| Producer | Name of the person or organization that produced the dataset (e.g. source of the original data). |
| Date start and date end | Time coverage of the dataset. |
| Geographic coverage | Geographic coverage of the dataset (e.g. Brazil, Rio Grande do Sul, Porto Alegre). |

### Optional fields
| Field | Description |
|-------|-------------|
| Contribution | Describes additional contributions made by others to the dataset. This field is mostly used to acknowledge and give credit. Examples: "data collector", "data curator", etc. |
| Type | Type of the dataset (what kind of data it contains). |
| Related material | Links to related material (e.g. paper, code, etc.). |
| Language | Language of the dataset (Portuguese by default). |
| Alternative title | Alternative title of the dataset. |
| Alternative URL | Alternative URL of the dataset. |
| Publisher | Publisher of the dataset. |

### Suggestions

As a general suggestion, we recommend using the `utilscidados` package to generate the metadata. As an alternative, you can use Excel and mannually fill the fields. Some general guidelines:

1. Title and subtitle should be descriptive. They should identify: what, when, and where.
2. Description should be a comprehensive description of the dataset. It should describe what the user will find in the dataset.
3. If uncertain about what keywords to use, check for similar datasets in Dataverse.
4. Dataverse allows (and incentivizes) the use of multiple formats. For tabular data prefer to use csv (in the standard US format) or parquet. For shapefiles, prefer to use gpkg (geopackage), geojson, or geoparquet. If appropriate, include specialized formats such as `.rds` or `.dta`.

## Suggested workflow

### Processing Pipeline
---
#### 1. Download (`01_download.R`)
Downloads raw data from [source]. Files are saved to `raw/` subdirectory.

#### 2. Cleaning (`02_clean.R`)
- Standardizes column names
- Handles missing values
- Converts data types

#### 3. Validation (`03_validate.R`)
- Checks for data completeness
- Validates geographic codes
- Ensures temporal consistency
- Produces quality report

#### 4. Export (`04_export.R`)
- Exports to parquet format
- Generates metadata
- Updates documentation

#### Data Quality Notes
- [Any known issues]
- [Limitations]
- [Important considerations for users]

### File Structure
```
dataset_name/
├── renv.lock          # Locked R package versions
├── raw/               # Original downloaded files (git-ignored)
├── processed/         # Intermediate files (git-ignored)
├── output/            # Final parquet files (git-ignored)
├── logs/              # Processing logs
└── scripts/           # All R scripts
```

### Reproducibility

To reproduce this dataset processing:

```r
# Navigate to this dataset folder
setwd("data-raw/[dataset_name]")

# Restore the R environment
renv::restore()

# Run all scripts in order
source("01_download.R")
source("02_clean.R")
source("03_validate.R")
source("04_export.R")
```
