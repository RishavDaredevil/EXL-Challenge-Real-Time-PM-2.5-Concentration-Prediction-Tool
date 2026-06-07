# scripts/03_modeling.R
library(tidyverse)
library(tsibble)
library(fable)

clean_tsibble <- readRDS("../data/processed/clean_tsibble.rds")

# We will use a simplified ARIMA model for the structural pipeline
# to ensure it runs quickly for all cities
models <- clean_tsibble %>%
  # Limit data for faster testing/building if needed, or use full
  model(
    ARIMA_PM25 = ARIMA(log(PM2.5 + 1))
  )

# Forecast next 18 periods (3 days * 6 4-hourly periods)
forecasts <- models %>%
  forecast(h = 18) %>%
  as_tibble() %>%
  select(State, City, `Time Periods`, .mean) %>%
  rename(Predicted_PM2.5 = .mean)

saveRDS(forecasts, "../app/data/forecasts.rds")