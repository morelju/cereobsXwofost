# Loads packages, settings and functions. Every script starts with:
#   source(here::here("R", "_load.R"))

suppressPackageStartupMessages({
  library(tidyverse)
})

for (f in list.files(here::here("R"), pattern = "\\.R$", full.names = TRUE)) {
  if (basename(f) != "_load.R") source(f, encoding = "UTF-8")
}
rm(f)

for (p in paths) if (!grepl("\\.", basename(p))) dir.create(p, showWarnings = FALSE, recursive = TRUE)
