# Reading and tidying Cereobs (FranceAgriMer) phenology surveys.
#
# Cereobs reports, each ISO week, the share (%) of surveyed fields in a region that
# have reached a given stage. One "curve" = crop x region x campaign x stage.

# Column renaming for the raw FranceAgriMer xlsx exports (sheet 3, 5 header rows)
cereobs_xlsx_columns <- list(
  cereals = c(
    crop = "Culture", region = "R\u00e9gion", year_week = "Semaine",
    sowing = "Semis", emergence = "Lev\u00e9e", tillering = "D\u00e9but tallage",
    ear_1cm = "\u00c9pi 1 cm", nodes_2 = "2 noeuds", heading = "\u00c9piaison",
    harvest = "R\u00e9colte"
  ),
  maize = c(
    crop = "Culture", region = "R\u00e9gion", year_week = "Semaine",
    sowing = "Semis", emergence = "Lev\u00e9e", `6_8_leaves` = "6/8 feuilles visibles",
    female_flowering = "Floraison femelle", grain_moist_50 = "Humidit\u00e9 du grain 50%",
    harvest = "R\u00e9colte"
  )
)

#' Read one raw Cereobs xlsx export into long format
read_cereobs_xlsx <- function(path, type = c("cereals", "maize")) {
  type <- match.arg(type)
  cols <- cereobs_xlsx_columns[[type]]
  readxl::read_xlsx(path, sheet = 3, skip = 5) |>
    dplyr::select(dplyr::all_of(cols)) |>
    tidyr::pivot_longer(-c(crop, region, year_week),
                        names_to = "stage", values_to = "value")
}

#' Add English crop names, season, ISO-week dates and campaign (harvest year)
#'
#' The date of a weekly record is the Thursday (middle) of its ISO week.
tidy_cereobs <- function(raw, crop_table, campaign_start_month) {
  raw |>
    dplyr::rename(crop_fr = crop) |>
    dplyr::inner_join(crop_table, by = "crop_fr") |>
    dplyr::mutate(
      iso_year = as.integer(substr(year_week, 1, 4)),
      iso_week = as.integer(substr(year_week, 7, 8)),
      date = ISOweek::ISOweek2date(sprintf("%d-W%02d-4", iso_year, iso_week)),
      campaign = assign_campaign(date, season, campaign_start_month)
    ) |>
    dplyr::select(crop_en, season, region, campaign, stage, date, value) |>
    dplyr::arrange(crop_en, region, stage, date)
}

#' Campaign = harvest year
assign_campaign <- function(date, season, campaign_start_month) {
  y <- lubridate::year(date)
  m <- lubridate::month(date)
  start <- campaign_start_month[season]
  as.integer(ifelse(season == "winter" & m >= start, y + 1L, y))
}
