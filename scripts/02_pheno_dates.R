# 02 - Date at which 50 % of fields reach each stage (linear and logistic)
# in : data/derived/cereobs_long.rds
# out: data/derived/pheno_points.rds  (cleaned curves, for figures/checks)
#      outputs/tables/pheno_dates.csv (one row per crop x region x campaign x stage)

source(here::here("R", "_load.R"))

cereobs <- readRDS(file.path(paths$derived, "cereobs_long.rds"))

curves <- cereobs |>
  filter(crop_en %in% crops_paper) |>
  group_by(crop_en, region, campaign, stage) |>
  summarise(
    clean = list(clean_curve(date, value,
                             min_max_value = curve_params$min_max_value,
                             drop_stale_repeats = curve_params$drop_stale_repeats)),
    .groups = "drop"
  ) |>
  mutate(
    curve_status      = map_chr(clean, "status"),
    points            = map(clean, "points"),
    starts_above_zero = map_lgl(clean, ~ .x$flags$starts_above_zero),
    n_decreases       = map_int(clean, ~ .x$flags$n_decreases),
    n_stale_dropped   = map_int(clean, ~ .x$flags$n_stale_dropped)
  ) |>
  select(-clean)

dates <- curves |>
  mutate(
    lin = map(points, date50_linear),
    lgt = map(points, date50_logistic)
  ) |>
  unnest_wider(lin, names_sep = "_") |>
  unnest_wider(lgt, names_sep = "_") |>
  select(-points) |>
  left_join(stages, by = c("crop_en", "stage")) |>
  mutate(diff_days = as.numeric(lgt_date50 - lin_date50)) |>
  arrange(crop_en, region, campaign, stage_order)

saveRDS(curves |> select(crop_en, region, campaign, stage, points) |> unnest(points),
        file.path(paths$derived, "pheno_points.rds"))
write_csv(dates, file.path(paths$tables, "pheno_dates.csv"))

# summary -------------------------------------------------------------------
print(count(dates, crop_en, curve_status))
print(count(dates, crop_en, lin_status, lgt_status))
print(summary(dates$diff_days))
