# 01 - Cereobs raw exports -> tidy long table with campaign
# in : data/raw/cereobs/*.xlsx (FranceAgriMer exports, sheet 'Donnees regions')
# out: data/derived/cereobs_long.rds

source(here::here("R", "_load.R"))

xlsx_cereals <- list.files(paths$raw_cereobs, pattern = "CEREOBS_CP.*\\.xlsx$", full.names = TRUE)
xlsx_maize   <- list.files(paths$raw_cereobs, pattern = "CEREOBS_M.*\\.xlsx$", full.names = TRUE)

stopifnot("exactly one cereals and one maize export expected in data/raw/cereobs" =
            length(xlsx_cereals) == 1 && length(xlsx_maize) == 1)
message("Reading ", basename(xlsx_cereals), ", ", basename(xlsx_maize))
raw <- bind_rows(
  read_cereobs_xlsx(xlsx_cereals, "cereals"),
  read_cereobs_xlsx(xlsx_maize, "maize")
)

cereobs <- tidy_cereobs(raw, crop_table, campaign_start_month)

# sanity checks
stopifnot(
  !anyNA(cereobs$date),
  nrow(count(cereobs, crop_en, region, stage, date) |> filter(n > 1)) == 0,
  all(cereobs$value >= 0 & cereobs$value <= 100, na.rm = TRUE)
)

saveRDS(cereobs, file.path(paths$derived, "cereobs_long.rds"))
message("cereobs_long: ", nrow(cereobs), " rows, campaigns ",
        paste(range(cereobs$campaign), collapse = "-"))
