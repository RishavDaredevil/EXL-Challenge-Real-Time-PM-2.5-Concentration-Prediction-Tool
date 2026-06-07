# Refactoring Plan: Exogenous Variable Model Caching

## The Problem
Currently, the pipeline correctly trains and caches the main PM 2.5 models (`models.rds`). However, the Multivariate DHR model requires future values of exogenous variables (NO, NO2, CO, etc.) to generate its forecasts. 

Right now, both `03_modeling.R` and `04_update_forecasts.R` are recreating and **re-training** Univariate ARIMA models for every single exogenous variable across all 34 cities every time a forecast is generated. This means `04_update_forecasts.R` trains roughly 272 models (8 variables * 34 cities) just to extend the forecast horizon, which is highly inefficient and defeats the purpose of the fast update script.

## The Solution
We need to decouple the **training** of exogenous models from the **forecasting** of exogenous variables. We will train them once in `03`, save them to disk, and only load/forecast them in `04`.

### 1. Changes to `scripts/03_modeling.R`
This script should remain the "heavy lifter". We will update the exogenous loop to store the trained models into a list, save that list to disk, and then generate the forecast.

**Implementation Steps:**
1. Initialize an empty list: `exog_models <- list()`
2. In the `for (var in available_exog)` loop:
   - Train the model and assign it to the list: `exog_models[[var]] <- clean_tsibble %>% model(...)`
   - Generate the forecast from this trained object: `exog_fc <- exog_models[[var]] %>% forecast(...)`
3. At the end of the script, save the new model cache: `saveRDS(exog_models, "data/processed/exog_models.rds")`

### 2. Changes to `scripts/04_update_forecasts.R`
This script should become extremely fast. It will no longer do any training.

**Implementation Steps:**
1. Load the new cache alongside the others: `exog_models <- readRDS("data/processed/exog_models.rds")`
2. In the `for (var in available_exog)` loop:
   - **Remove** the `model(...)` step completely.
   - Simply forecast directly from the loaded cache: `exog_fc <- exog_models[[var]] %>% forecast(h = periods) %>% ...`
3. Keep the `suppressWarnings` block to ensure the script doesn't spook the user if a specific city has all `NA` values for a specific pollutant.

### 3. File Tracking
- The `.gitignore` already ignores `*.rds` files, so `exog_models.rds` will be safely ignored automatically.
- No changes are needed in `app/app.R` because the structure of `forecasts.rds` remains identical.

## Execution
1. Refactor `03_modeling.R` and run it once. This will take a few minutes as it bakes `models.rds` and the new `exog_models.rds`.
2. Refactor `04_update_forecasts.R`.
3. Run `.\update_forecasts.ps1 -Days 30`. It should now complete in seconds rather than minutes.
