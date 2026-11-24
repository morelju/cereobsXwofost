# 90 - Migration check: new 50 % dates vs. legacy EC results
# Temporary script, to be removed once the migration is validated.
# in : outputs/tables/pheno_dates.csv, data/legacy_EC/*
# out: notes/legacy_comparison.csv, notes/legacy_comparison.png

source(here::here("R", "_load.R"))

new <- read_csv(file.path(paths$tables, "pheno_dates.csv"), show_col_types = FALSE)

old_lin <- read_csv2(here::here("data", "legacy_EC", "table_median_dates_measurements_control.csv"),
                     show_col_types = FALSE) |>
  transmute(crop_en = crop, region, campaign = year, stage = recode(stage, kernel = "ear_1cm"),
            old_lin = median_date)

# Legacy logistic report: `median_doy` is a day of year relative to the year of
# the first record (`year_stage_report`), wrapped at 365/366, and `year_harvest`
# is the calendar year of the last record (so autumn stages of campaign y are
# labelled y-1). Neither label identifies the campaign reliably, so legacy
# logistic dates are matched to the new curve of the same crop/region/stage
# whose linear date is closest (within 120 days), trying both possible years.
old_log <- readRDS(here::here("data", "legacy_EC", "table_pheno_log_report_measurements_controlled.rds")) |>
  filter(!is.na(median_doy)) |>
  mutate(stage = recode(stage, kernel = "ear_1cm")) |>
  transmute(crop_en, region, stage, legacy_label = year_harvest,
            cand1 = as.Date(paste0(year_stage_report, "-01-01")) + median_doy - 1,
            cand2 = as.Date(paste0(year_stage_report + 1, "-01-01")) + median_doy - 1) |>
  pivot_longer(c(cand1, cand2), values_to = "old_log") |>
  inner_join(new |> select(crop_en, region, stage, campaign, lin_date50),
             by = c("crop_en", "region", "stage"), relationship = "many-to-many") |>
  mutate(gap = abs(as.numeric(old_log - lin_date50))) |>
  filter(gap <= 120) |>
  group_by(crop_en, region, stage, campaign) |>
  slice_min(gap, n = 1, with_ties = FALSE) |>
  ungroup() |>
  select(crop_en, region, stage, campaign, old_log, legacy_label)

cmp <- new |>
  select(crop_en, region, campaign, stage, stage_order, curve_status,
         new_lin = lin_date50, new_log = lgt_date50) |>
  left_join(old_lin, by = c("crop_en", "region", "campaign", "stage")) |>
  left_join(old_log, by = c("crop_en", "region", "campaign", "stage")) |>
  mutate(
    d_lin = as.numeric(new_lin - old_lin),
    d_log = as.numeric(new_log - old_log),
    legacy_label_shift = legacy_label - campaign
  )

write_csv(cmp, here::here("notes", "legacy_comparison.csv"))

summ <- function(x) tibble(n = sum(!is.na(x)), identical = sum(x == 0, na.rm = TRUE),
                           within_3d = sum(abs(x) <= 3, na.rm = TRUE),
                           over_7d = sum(abs(x) > 7, na.rm = TRUE),
                           max_abs = max(abs(x), na.rm = TRUE))
print(cmp |> group_by(crop_en) |> reframe(method = "linear", summ(d_lin)))
print(cmp |> group_by(crop_en) |> reframe(method = "logistic", summ(d_log)))
print(cmp |> filter(abs(d_lin) > 3) |> select(crop_en, region, campaign, stage, new_lin, old_lin, d_lin), n = 100)
print(cmp |> filter(is.na(new_lin) != is.na(old_lin)) |> count(crop_en, campaign, curve_status, has_old = !is.na(old_lin)))

long <- cmp |>
  pivot_longer(c(d_lin, d_log), names_to = "method", values_to = "diff") |>
  mutate(method = recode(method, d_lin = "Linear", d_log = "Logistic"))
p <- ggplot(long, aes(diff, fill = crop_en)) +
  geom_histogram(binwidth = 1) +
  facet_grid(crop_en ~ method) +
  coord_cartesian(xlim = c(-30, 30)) +
  labs(x = "New - legacy 50 % date (days)", y = "Number of curves") +
  theme_bw() + theme(legend.position = "none")
ggsave(here::here("notes", "legacy_comparison.png"), p, width = 7, height = 4.5, dpi = 150)
