# scripts/03_modeling.R
library(tidyverse)
library(tsibble)
library(fable)
library(feasts)

# 1. Load Data
clean_tsibble <- readRDS("data/processed/clean_tsibble.rds")

# 2. Define the exact exogenous variables used in your original competition attempt
# We exclude static variables (Population, Latitude, etc.) to prevent matrix singularity
target_exog_vars <- c("NO", "NO2", "NOx", "NH3", "SO2", "CO", "Benzene", "AT")

# Filter to only include variables that actually exist in the current dataset
available_exog <- intersect(names(clean_tsibble), target_exog_vars)

# Build the multivariate formula dynamically but safely using log1p
if(length(available_exog) > 0) {
  exog_formula_str <- paste0("log1p(`", available_exog, "`)", collapse = " + ")
} else {
  exog_formula_str <- "1" # Fallback if no exogenous variables are found
}

formula_str <- paste("log1p(`PM2.5`) ~ fourier(period = 'day', K = 2) +", 
                     "fourier(period = 'year', K = 5) + PDQ(0,0,0) +", 
                     exog_formula_str)

multivariate_formula <- as.formula(formula_str)

cat("Training models...\n")

# 3. Train the Three Competition Models
models <- clean_tsibble %>%
  model(
    # Model 1: STL decomposition with ARIMA on seasonally adjusted data
    # Removed pdq(d=0) to allow fable to handle non-stationarity
    `STL + ARIMA` = decomposition_model(
      STL(log1p(`PM2.5`) ~ season(period = "day") + season(period = "year"), robust = TRUE),
      ARIMA(season_adjust ~ PDQ(0,0,0)) 
    ),
    
    # Model 2: Univariate Dynamic Harmonic Regression with ARMA errors
    # Reduced daily K to 2 to avoid the Nyquist limit instability
    `DHR + ARMA` = ARIMA(log1p(`PM2.5`) ~ fourier(period = "day", K = 2) + 
                                          fourier(period = "year", K = 5) + 
                                          PDQ(0,0,0)),
    
    # Model 3: Multivariate Dynamic Harmonic Regression with ARMA errors
    `Multivariate DHR` = ARIMA(!!multivariate_formula)
  )

# 4. Prepare Future Data for Forecasting (Next 365 days = 2190 periods of 4-hours)
future_data <- new_data(clean_tsibble, 2190)

if (length(available_exog) > 0) {
  cat("Forecasting exogenous variables using Univariate ARIMA...\n")
  
  future_exog_list <- list()
  exog_models <- list() # Initialize list to cache exogenous models
  
  for (var in available_exog) {
    # Train model for exogenous variable
    mod <- clean_tsibble %>%
      model(mod = ARIMA(log1p(!!sym(var))))
      
    exog_models[[var]] <- mod
    
    # Forecast each exogenous variable smoothly
    exog_fc <- mod %>%
      forecast(h = 2190) %>%
      as_tibble() %>%
      select(State, City, `Time Periods`, .mean)
    
    # fable handles back-transformation of log1p. 
    # We just assign the mean and bound it at 0.
    exog_fc[[var]] <- pmax(0, exog_fc$.mean)
    exog_fc$.mean <- NULL
    
    future_exog_list[[var]] <- exog_fc
  }
  
  # Save the exogenous models for fast updates later
  saveRDS(exog_models, "data/processed/exog_models.rds")
  
  # Join all forecasted exogenous variables back into future_data
  for (var in available_exog) {
    future_data <- future_data %>%
      left_join(future_exog_list[[var]], by = c("State", "City", "Time Periods"))
  }
}

cat("Generating 3-day PM 2.5 forecasts...\n")

# 5. Generate Final Forecasts
forecasts <- models %>%
  forecast(new_data = future_data) %>%
  as_tibble() %>%
  select(State, City, .model, `Time Periods`, .mean) %>%
  rename(
    Model = .model,
    Predicted_PM2.5 = .mean
  ) %>%
  mutate(Predicted_PM2.5 = pmax(0, Predicted_PM2.5)) # Prevent negative PM2.5 predictions

# 6. Save outputs for the UI
saveRDS(models, "data/processed/models.rds")
saveRDS(forecasts, "app/data/forecasts.rds")

cat("Modeling pipeline complete.\n")