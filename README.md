# cereobsXwofost

Assessing and recalibrating the phenology of WOFOST (as run by JRC MARS / Agri4Cast)
for French **soft winter wheat** and **grain maize**, using the Cereobs field
phenology surveys (FranceAgriMer), and evaluating the recalibration against two
independent datasets: Sentinel-2 time series and regional yields (Agreste).

## Run

Open `cereobsXwofost.Rproj` (or set the working directory to the repo root), then:

```r
source("run_all.R")   # unit tests, then every step in order, each in a fresh R session
```

Every number, table and figure of the paper is produced by this pipeline; nothing
in `outputs/` is edited by hand.

## Layout

| Path | Content |
|---|---|
| `R/` | functions and settings (`config.R`: paths, crops, stages, parameters) |
| `scripts/` | numbered pipeline steps, called by `run_all.R` |
| `tests/testthat/` | unit tests of the functions |
| `data/raw/` | input data, never modified (provenance in `data/README.md`) |
| `data/derived/` | intermediate files, regenerated (not versioned) |
| `outputs/` | tables, figures and `numbers.tex` used in the manuscript (versioned) |
| `notes/` | method notes and checks (e.g. migration from the EC repo) |
| `checks/` | control plots (not versioned) |

## Pipeline

| Step | Script | Output |
|---|---|---|
| 1 | `01_prepare_cereobs.R` | `data/derived/cereobs_long.rds`: one row per crop x region x stage x ISO week, with campaign (harvest year) |
| 2 | `02_pheno_dates.R` | `outputs/tables/pheno_dates.csv`: date at which 50 % of surveyed fields reach each stage (linear and logistic estimates, with quality flags) |
| 3 | `03_calibration_targets.R` | `outputs/tables/calibration_targets.csv`: observed dates of the stages linked to WOFOST development stages (DVS), with a quality flag |
| ... | Sentinel-2, WOFOST default vs recalibrated, yields | to come |

### Key definitions

- **Link to WOFOST** (`stages` in `R/config.R`). Maize: emergence -> DVS 0, female
  flowering -> DVS 1 (anthesis). Wheat: flowering is not observed, so, following the
  AgMIP calibration (A. de Wit), ear at 1 cm (BBCH 30) and heading (BBCH 55) are linked
  to calibrated DVS values (`DVS_BBCH30`, `DVS_BBCH55`) that constrain TSUM1. Maturity
  (DVS 2) is not observed for either crop: harvest is only an upper bound, and maize
  grain moisture 50 % (dough stage) is not used, so maize TSUM2 is not calibrated.

- **Campaign** = harvest year. For winter crops, records from 1 September of y-1 belong to campaign y.
- **Curve** = weekly % of fields at a stage, for one crop x region x campaign.
  It is cleaned (`R/pheno_curves.R`) by keeping the segment from the last 0 % before
  the rise to the first time the maximum is reached; repeated values strictly between
  0 and 100 % are treated as weeks without update.
- **Stage date** = date at which 50 % of surveyed fields have reached the stage
  (`R/pheno_dates.R`): linear interpolation between the two bracketing records, or
  logistic fit (upper asymptote fixed at 100 %) on the whole cleaned curve.

## Requirements

R >= 4.3 with `tidyverse`, `readxl`, `ISOweek`, `here`, `testthat`, `callr`.
Source files are pure ASCII (accents written as `\uXXXX`) to avoid locale issues on Windows.
