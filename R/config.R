# Shared settings: paths, crop definitions, stage tables, colour scales.
# Sourced by every script through R/_load.R. Paths are relative to the repo root.

paths <- list(
  raw_cereobs  = here::here("data", "raw", "cereobs"),
  raw_yields   = here::here("data", "raw", "yields"),
  derived      = here::here("data", "derived"),
  figures      = here::here("outputs", "figures"),
  tables       = here::here("outputs", "tables"),
  numbers_tex  = here::here("outputs", "numbers.tex"),
  checks       = here::here("checks") # control plots, not versioned
)

# Crops kept in the paper
crops_paper <- c("soft_wheat", "grain_maize")

# French Cereobs crop names -> English names and sowing season
crop_table <- tibble::tribble(
  ~crop_fr,             ~crop_en,         ~season,
  "Bl\u00e9 dur",            "durum_wheat",    "winter",
  "Bl\u00e9 tendre",         "soft_wheat",     "winter",
  "Orge d'hiver",       "winter_barley",  "winter",
  "Orge de printemps",  "spring_barley",  "spring",
  "Ma\u00efs grain",         "grain_maize",    "spring"
)

# Campaign (= harvest year) boundaries.
# Winter crops: records from 1 September of year y-1 onwards belong to campaign y.
# Spring crops: campaign = calendar year.
campaign_start_month <- c(winter = 9L, spring = 1L)

# Stage definitions per crop (order = phenological order)
# bbch: approximate BBCH code of the Cereobs stage (50 % of fields).
# wofost: how the stage is used for the WOFOST phenology calibration
#   (following A. de Wit / AgMIP wheat calibration: BBCH30 and BBCH55 linked to
#   free DVS values, since flowering - BBCH65, DVS = 1 - is not observed for wheat).
stages <- tibble::tribble(
  ~crop_en,       ~stage,             ~stage_order, ~stage_label,         ~bbch,  ~wofost,
  "soft_wheat",   "sowing",           1L, "Sowing",              "00",   "input (sowing date)",
  "soft_wheat",   "emergence",        2L, "Emergence",           "09",   "DVS = 0 (TSUMEM)",
  "soft_wheat",   "tillering",        3L, "Start of tillering",  "21",   NA,
  "soft_wheat",   "ear_1cm",          4L, "Ear at 1 cm",         "30",   "DVS_BBCH30 (TSUM1)",
  "soft_wheat",   "nodes_2",          5L, "Two nodes",           "32",   NA,
  "soft_wheat",   "heading",          6L, "Heading",             "55",   "DVS_BBCH55 (TSUM1)",
  "soft_wheat",   "harvest",          7L, "Harvest",             "99",   "upper bound for maturity (DVS = 2)",
  "grain_maize",  "sowing",           1L, "Sowing",              "00",   "input (sowing date)",
  "grain_maize",  "emergence",        2L, "Emergence",           "09",   "DVS = 0 (TSUMEM)",
  "grain_maize",  "6_8_leaves",       3L, "6-8 visible leaves",  "16-18", NA,
  "grain_maize",  "female_flowering", 4L, "Female flowering",    "65",   "DVS = 1 (TSUM1)",
  "grain_maize",  "grain_moist_50",   5L, "Grain moisture 50%",  "~85",  "to discuss (DVS between 1 and 2, TSUM2)",
  "grain_maize",  "harvest",          6L, "Harvest",             "99",   "upper bound for maturity (DVS = 2)"
)

# Curve-cleaning parameters (see R/pheno_curves.R)
curve_params <- list(
  min_max_value      = 80,   # a curve must reach at least this % to be usable
  drop_stale_repeats = TRUE  # repeated values strictly between 0 and 100 are treated as not updated
)

# Colour scales
region_colours <- c(
  "Auvergne-Rh\u00f4ne-Alpes" = "#A6CEE3", "Centre-Val de Loire" = "#FF7F00",
  "Nouvelle-Aquitaine" = "#B2DF8A", "Occitanie" = "#33A02C",
  "Pays-de-la-Loire" = "#FB9A99", "Provence-Alpes-C\u00f4te d'Azur" = "#E31A1C",
  "Bourgogne-Franche-Comt\u00e9" = "#1F78B4", "Bretagne" = "#FDBF6F",
  "Grand-Est" = "#CAB2D6", "Hauts-de-France" = "#6A3D9A",
  "Ile-de-France" = "#FFFF99", "Normandie" = "#B15928"
)
