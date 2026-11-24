# Data provenance

## raw/cereobs

Cereobs phenology surveys (FranceAgriMer): weekly share of surveyed fields having
reached each stage, by crop and region (NUTS1), since campaign 2015.
Source: https://visionet.franceagrimer.fr (Séries chronologiques > productions
végétales > grandes cultures > états des cultures), linked from
https://cereobs.franceagrimer.fr/cereobs-sp/#/publications

- `SCR-GRC-CEREOBS_CP_depuis_2015-A25.xlsx`: cereals (durum and soft wheat, winter and
  spring barley), 2014-S36 to 2025-S07.
- `SCR-GRC-CEREOBS_M_depuis_2015-A24.xlsx`: grain maize, 2015-S02 to 2024-S49.

Read from sheet 3 (« Données régions »), 5 header rows. The crop condition columns
(Très mauvaises ... Très bonnes) are not used yet.

Choice among the available exports (checked on 2026-11-24):
- CP A24 (to 2024-S09) is contained in A25. The only 70 values that differ are all in
  the last week of A24 (2024-S09), later revised: **the last week of an export is
  provisional**.
- M `A24_2` (to 2024-S09) is a strict subset of M A24, with identical values.
- CP A25 + M A24 are identical, value for value, to `EC/01_DATA/cereobsXwofost/cereobs_pheno.rds`.

## raw/yields

Copied from `EC/01_DATA/cereobs/`. Regional (NUTS1) yields, q/ha, Agreste.

- `agreste_sw_yields.rds`: soft wheat.
- `agreste_gm_yields.rds`: grain maize, two rows per region (`CODE` 14 and 15: irrigated / non-irrigated, which is which to confirm).
- `FR_NUTS1_table.csv`: region names <-> NUTS1 codes (`;`-separated).

**Warning: the year columns of the yield tables appear shifted by one year.**
Soft wheat, Ile-de-France: column `2016` = 88.0 and `2017` = 43.3 q/ha, whereas
Agreste/FranceAgriMer report 88 q/ha for 2015 and 43 q/ha for the 2016 disaster
(and 80 q/ha for 2017, column `2018` = 80.1). Column `y` therefore seems to hold
harvest y-1. Obtained from a colleague; to be checked at the source before use.

## legacy_EC

Results of the legacy EC scripts (`03_phenology_median_dates.R`,
`04_phenology_logistic.R`, measurements controlled), kept only to check the
migration (`scripts/90_compare_legacy_EC.R`, `notes/migration_EC.md`).
