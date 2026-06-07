# scripts/02_eda.R
library(fpp3)

clean_tsibble <- readRDS("data/processed/clean_tsibble.rds")

# Calculate advanced time series features using the features() function
eda_features <- clean_tsibble %>%
  features(PM2.5, feature_set(pkgs = "feasts", tags = c("stl", "acf"))) %>%
  # Combine with simple statistics
  left_join(
    clean_tsibble %>%
      as_tibble() %>%
      group_by(State, City) %>%
      summarise(
        Mean_PM2.5 = mean(PM2.5, na.rm = TRUE),
        Median_PM2.5 = median(PM2.5, na.rm = TRUE),
        Max_PM2.5 = max(PM2.5, na.rm = TRUE),
        .groups = "drop"
      ),
    by = c("State", "City")
  )

# Perform an STL decomposition on the PM 2.5 data for all cities
stl_components <- clean_tsibble %>%
  model(
    STL(PM2.5 ~ season(period = "day") + season(period = "year"), robust = TRUE)
  ) %>%
  components()

# Ensure app/data directory exists
dir.create("app/data", showWarnings = FALSE, recursive = TRUE)

saveRDS(eda_features, "app/data/eda_features.rds")
saveRDS(stl_components, "app/data/stl_components.rds")