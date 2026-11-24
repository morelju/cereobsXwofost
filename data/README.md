# Data provenance

## raw/cereobs

Cereobs phenology surveys (FranceAgriMer): weekly share of surveyed fields having
reached each stage, by crop and region (NUTS1), since campaign 2015.
Source: https://visionet.franceagrimer.fr (Séries chronologiques > productions
végétales > grandes cultures > états des cultures), linked from
https://cereobs.franceagrimer.fr/cereobs-sp/#/publications

- `SCR-GRC-CEREOBS_CP_depuis_2015-*.xlsx`, `SCR-GRC-CEREOBS_M_depuis_2015-*.xlsx`:
  raw exports (to be added). When present, `01_prepare_cereobs.R` reads them.
- `cereobs_pheno_EC.rds`: interim copy of `01_DATA/cereobsXwofost/cereobs_pheno.rds`
  from the EC repository (exports A25 for cereals, A24 for maize, imported with the
  legacy script). Records from 2014-S36 to 2025-S07. Used only while the xlsx are missing.

## raw/yields

Copied from `EC/01_DATA/cereobs/`. Regional (NUTS1) yields, q/ha, Agreste.

- `agreste_sw_yields.rds`: soft wheat.
- `agreste_gm_yields.rds`: grain maize, two rows per region (`CODE` 14 and 15; meaning to confirm).
- `FR_NUTS1_table.csv`: region names <-> NUTS1 codes (`;`-separated).

**Warning: the year columns of the yield tables appear shifted by one year.**
Soft wheat, Ile-de-France: column `2016` = 88.0 and `2017` = 43.3 q/ha, whereas
Agreste/FranceAgriMer report 88 q/ha for 2015 and 43 q/ha for the 2016 disaster
(and 80 q/ha for 2017, column `2018` = 80.1). Column `y` therefore seems to hold
harvest y-1. To be confirmed at the source before use.

## legacy_EC

Results of the legacy EC scripts (`03_phenology_median_dates.R`,
`04_phenology_logistic.R`, measurements controlled), kept only to check the
migration (`scripts/90_compare_legacy_EC.R`, `notes/migration_EC.md`).
