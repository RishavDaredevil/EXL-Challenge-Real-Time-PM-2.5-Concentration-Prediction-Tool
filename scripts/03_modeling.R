# scripts/03_modeling.R
library(tidyverse)
library(tsibble)
library(fable)
library(feasts)

clean_tsibble <- readRDS("data/processed/clean_tsibble.rds")

# Identify potential exogenous variables available in the dataset (excluding our grouping/index vars)
exog_vars <- setdiff(names(clean_tsibble), c("State", "City", "Time Periods", "PM2.5"))

# We construct the formula dynamically based on available exogenous variables.
# If 'Temp' is available from our mock, or 'NOx', 'CO' etc. from the real data.
if (length(exog_vars) > 0) {
  # Take the first available exogenous variable for the multivariate model to ensure it runs
  # Ideally, we would use all, but for robustness across mock/real data, we use the first valid one.
  # We will use all numeric exogenous variables that have variance.
  num_vars <- clean_tsibble %>% 
    as_tibble() %>% 
    select(all_of(exog_vars)) %>% 
    select(where(is.numeric)) %>% 
    names()
    
  if(length(num_vars) > 0) {
    exog_formula_str <- paste(num_vars[1:min(3, length(num_vars))], collapse = " + ")
  } else {
    exog_formula_str <- "1" # Fallback
  }
} else {
  exog_formula_str <- "1"
}

formula_str <- paste("log(PM2.5 + 1) ~ fourier(period = 'day', K = 2) + pdq(d=0) +", exog_formula_str)

# Train the three models specified in the user's attempt
models <- clean_tsibble %>%
  model(
    # 1. Univariate: STL decomposition with ARIMA on seasonally adjusted data
    `STL + ARIMA` = decomposition_model(
      STL(log(PM2.5 + 1) ~ season(period = "day"), robust = TRUE),
      ARIMA(season_adjust)
    ),
    
    # 2. Univariate: Dynamic Harmonic Regression with ARMA errors
    `DHR + ARMA` = ARIMA(log(PM2.5 + 1) ~ fourier(period = "day", K = 2) + pdq(d=0)),
    
    # 3. Multivariate: Stepwise regression combined with Dynamic Harmonic Regression with ARMA errors
    `Multivariate DHR` = ARIMA(as.formula(formula_str))
  )

# For forecasting the multivariate model, we need future values of the exogenous predictors.
# We will use the naive method (carrying forward the last observed value) for simplicity in this structural pipeline.
future_data <- new_data(clean_tsibble, 18)

if (exog_formula_str != "1") {
  last_obs <- clean_tsibble %>%
    as_tibble() %>%
    group_by(State, City) %>%
    slice_tail(n = 1) %>%
    select(State, City, all_of(num_vars))
    
  future_data <- future_data %>%
    left_join(last_obs, by = c("State", "City")) %>%
    as_tsibble(key = c(State, City), index = `Time Periods`)
}

# Generate 3-day forecast (18 periods of 4 hours)
forecasts <- models %>%
  forecast(new_data = future_data) %>%
  as_tibble() %>%
  select(State, City, .model, `Time Periods`, .mean) %>%
  rename(
    Model = .model,
    Predicted_PM2.5 = .mean
  )

# Save the trained models for offline inspection
saveRDS(models, "data/processed/models.rds")

# Save the forecasts for the Shiny App
saveRDS(forecasts, "app/data/forecasts.rds")
