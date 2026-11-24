# 03 - Observed stage dates used as WOFOST phenology calibration targets
# in : outputs/tables/pheno_dates.csv
# out: outputs/tables/calibration_targets.csv (for the calibration, D. Fumagalli)
#      outputs/numbers.tex (counts)
#
# One row per crop x region x campaign x target stage. Both 50 % date estimates are
# given; `quality` summarises the flags so that doubtful targets can be down-weighted
# or excluded:
#   ok         curve complete, both estimates available and within 7 days,
#              linear bracket <= 14 days
#   uncertain  estimates available but differ by > 7 days or bracket > 14 days
#   missing    no usable estimate

source(here::here("R", "_load.R"))

dates <- read_csv(file.path(paths$tables, "pheno_dates.csv"), show_col_types = FALSE)

targets <- dates |>
  filter(!is.na(wofost)) |>
  transmute(
    crop_en, region, campaign, stage_order, stage, bbch, wofost,
    date_linear = lin_date50,
    date_logistic = lgt_date50,
    spread_scale_days = round(lgt_scale_days, 1),
    diff_days,
    bracket_days = lin_bracket_days,
    quality = case_when(
      is.na(date_linear) & is.na(date_logistic) ~ "missing",
      curve_status != "ok" | is.na(date_linear) | is.na(date_logistic) ~ "uncertain",
      abs(diff_days) > 7 | bracket_days > 14 ~ "uncertain",
      TRUE ~ "ok"
    )
  ) |>
  arrange(crop_en, region, campaign, stage_order) |>
  select(-stage_order)

write_csv(targets, file.path(paths$tables, "calibration_targets.csv"))

print(count(targets, crop_en, stage, quality) |> pivot_wider(names_from = quality, values_from = n, values_fill = 0))

# numbers for the manuscript
n_ok <- targets |> filter(quality == "ok")
set_number("nRegions", n_distinct(targets$region))
set_number("nTargetsWheat", sum(n_ok$crop_en == "soft_wheat"))
set_number("nTargetsMaize", sum(n_ok$crop_en == "grain_maize"))
set_number("firstCampaign", min(targets$campaign))
set_number("lastCampaignWheat", max(n_ok$campaign[n_ok$crop_en == "soft_wheat" & n_ok$stage == "heading"]))
set_number("lastCampaignMaize", max(n_ok$campaign[n_ok$crop_en == "grain_maize"]))
