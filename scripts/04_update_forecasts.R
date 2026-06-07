# scripts/04_update_forecasts.R
library(tidyverse)
library(tsibble)
library(fable)

args <- commandArgs(trailingOnly = TRUE)
if (length(args) == 0) {
  days <- 365 # Default to 1 year if no arg
} else {
  days <- as.numeric(args[1])
}

periods <- days * 6 # 4-hourly data means 6 periods per day

cat(sprintf("Updating forecasts for a horizon of %d days (%d periods)...\n", days, periods))

# 1. Load Data and Pre-trained Models
clean_tsibble <- readRDS("data/processed/clean_tsibble.rds")
models <- readRDS("data/processed/models.rds")
exog_models <- readRDS("data/processed/exog_models.rds")

target_exog_vars <- c("NO", "NO2", "NOx", "NH3", "SO2", "CO", "Benzene", "AT")
available_exog <- intersect(names(clean_tsibble), target_exog_vars)

# 2. Prepare Future Data
future_data <- new_data(clean_tsibble, periods)

if (length(available_exog) > 0) {
  cat("Forecasting exogenous variables...\n")
  future_exog_list <- list()
  
  for (var in available_exog) {
    cat(sprintf("  -> Forecasting %s...\n", var))
    
    exog_fc <- suppressWarnings({
      exog_models[[var]] %>%
        forecast(h = periods) %>%
        as_tibble() %>%
        select(State, City, `Time Periods`, .mean)
    })
    
    # Get the last known non-NA value for this variable per city
    last_vals <- clean_tsibble %>% 
      as_tibble() %>% 
      group_by(City) %>% 
      # Supress warnings if all values are NA
      summarise(last_val = suppressWarnings(last(na.omit(!!sym(var)))), .groups="drop")
    
    exog_fc <- exog_fc %>%
      left_join(last_vals, by = "City") %>%
      # If forecast is NA, use last known value. If that is NA (100% missing data), use 0.
      mutate(.mean = coalesce(.mean, last_val, 0)) %>%
      select(-last_val)
    
    exog_fc[[var]] <- pmax(0, exog_fc$.mean)
    exog_fc$.mean <- NULL
    
    future_exog_list[[var]] <- exog_fc
  }
  
  for (var in available_exog) {
    future_data <- future_data %>%
      left_join(future_exog_list[[var]], by = c("State", "City", "Time Periods"))
  }
}

cat("Generating PM 2.5 forecasts using pre-trained models...\n")

# 3. Generate Final Forecasts
forecasts <- models %>%
  forecast(new_data = future_data) %>%
  as_tibble() %>%
  select(State, City, .model, `Time Periods`, .mean) %>%
  rename(
    Model = .model,
    Predicted_PM2.5 = .mean
  ) %>%
  mutate(Predicted_PM2.5 = pmax(0, Predicted_PM2.5))

# 4. Overwrite forecast object
saveRDS(forecasts, "app/data/forecasts.rds")

cat("Forecast generation complete! Launch the app to see updates.\n")
