# scripts/03_modeling.R
library(tidyverse)
library(tsibble)
library(fable)
library(feasts)
library(rlang) # Required for the !! formula injection

clean_tsibble <- readRDS("data/processed/clean_tsibble.rds")

# 1. Identify numerical exogenous variables (excluding indices and target)
exog_vars <- setdiff(names(clean_tsibble), c("State", "City", "Time Periods", "PM2.5"))
num_vars <- clean_tsibble %>% 
  as_tibble() %>% 
  select(all_of(exog_vars)) %>% 
  select(where(is.numeric)) %>% 
  names()

# 2. Dynamically build the Multivariate Formula
if(length(num_vars) > 0) {
  # FIX: Wrap num_vars in backticks to handle spaces and special characters safely
  exog_formula_str <- paste0("log(`", num_vars, "` + 1)", collapse = " + ")
} else {
  exog_formula_str <- "1"
}

# FIX: Wrap PM2.5 in backticks as well, just to be safe
formula_str <- paste("log(`PM2.5` + 1) ~ fourier(period = 'day', K = 3) +", 
                     "fourier(period = 'year', K = 5) + pdq(d=0) + PDQ(0,0,0) +", 
                     exog_formula_str)

# Create the actual formula object BEFORE passing it to fable
multivariate_formula <- as.formula(formula_str)

cat("Training models...\n")

# 3. Train the Models
models <- clean_tsibble %>%
  model(
    # Model 1: STL decomposition with ARIMA on seasonally adjusted data
    `STL + ARIMA` = decomposition_model(
      STL(log(`PM2.5` + 1) ~ season(period = "day") + season(period = "year"), robust = TRUE),
      ARIMA(season_adjust ~ pdq(d=0) + PDQ(0,0,0))
    ),
    
    # Model 2: Univariate Dynamic Harmonic Regression with ARMA errors
    `DHR + ARMA` = ARIMA(log(`PM2.5` + 1) ~ fourier(period = "day", K = 3) + 
                                          fourier(period = "year", K = 5) + 
                                          pdq(d=0) + PDQ(0,0,0)),
    
    # Model 3: Multivariate Dynamic Harmonic Regression with ARMA errors
    # Use !! to inject the dynamically built formula
    `Multivariate DHR` = ARIMA(!!multivariate_formula)
  )

# 4. Prepare Future Data for Forecasting
future_data <- new_data(clean_tsibble, 18)

if (length(num_vars) > 0) {
  cat("Forecasting exogenous variables to feed the Multivariate model...\n")
  
  future_exog_list <- list()
  
  for (var in num_vars) {
    # FIX: Dynamically build and inject the formula with backticks
    var_formula <- as.formula(paste0("log(`", var, "` + 1) ~ fourier(period = 'day', K = 3) + pdq(d=0) + PDQ(0,0,0)"))
    
    exog_fc <- clean_tsibble %>%
      model(mod = ARIMA(!!var_formula)) %>%
      forecast(h = 18) %>%
      as_tibble() %>%
      select(State, City, `Time Periods`, .mean)
    
    # FIX: Fable automatically back-transforms log(y+1). .mean is already on the original scale.
    exog_fc[[var]] <- pmax(0, exog_fc$.mean)
    exog_fc$.mean <- NULL
    
    future_exog_list[[var]] <- exog_fc
  }
  
  # Join all forecasted exogenous variables back into our future_data tsibble
  for (var in num_vars) {
    future_data <- future_data %>%
      left_join(future_exog_list[[var]], by = c("State", "City", "Time Periods"))
  }
}

cat("Generating 3-day PM 2.5 forecasts...\n")

# 5. Generate Forecasts
forecasts <- models %>%
  forecast(new_data = future_data) %>%
  as_tibble() %>%
  select(State, City, .model, `Time Periods`, .mean) %>%
  rename(
    Model = .model,
    Predicted_PM2.5 = .mean
  ) %>%
  # FIX: Fable automatically back-transforms the target. Just bound at 0 to prevent negatives.
  mutate(Predicted_PM2.5 = pmax(0, Predicted_PM2.5))

# 6. Save outputs
saveRDS(models, "data/processed/models.rds")
saveRDS(forecasts, "app/data/forecasts.rds")

cat("Modeling pipeline complete.\n")