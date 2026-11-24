# Rebuilds every result of the paper from the raw data, in order.
# Run from the repository root (open cereobsXwofost.Rproj, or setwd()).

scripts <- c(
  "scripts/01_prepare_cereobs.R",  # raw Cereobs -> tidy long table with campaigns
  "scripts/02_pheno_dates.R",      # 50 % dates per crop x region x campaign x stage
  "scripts/03_calibration_targets.R" # target dates for the WOFOST calibration
  # next: S2 time series, WOFOST runs (default vs recalibrated), yields
)

testthat::test_dir(here::here("tests", "testthat"), stop_on_failure = TRUE)

for (s in scripts) {
  message("\n==== ", s)
  callr_ok <- requireNamespace("callr", quietly = TRUE)
  # each script runs in a fresh R session, so no hidden state leaks between steps
  if (callr_ok) callr::rscript(here::here(s), show = TRUE) else source(here::here(s), local = new.env())
}
