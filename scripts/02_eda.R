# scripts/02_eda.R
library(tidyverse)
library(tsibble)

clean_tsibble <- readRDS("data/processed/clean_tsibble.rds")

# Generate simple city summaries for EDA
eda_summaries <- clean_tsibble %>%
  as_tibble() %>%
  group_by(State, City) %>%
  summarise(
    Mean_PM2.5 = mean(PM2.5, na.rm = TRUE),
    Median_PM2.5 = median(PM2.5, na.rm = TRUE),
    Max_PM2.5 = max(PM2.5, na.rm = TRUE),
    .groups = "drop"
  )

# Ensure app/data directory exists
dir.create("app/data", showWarnings = FALSE, recursive = TRUE)
saveRDS(eda_summaries, "app/data/eda_summaries.rds")