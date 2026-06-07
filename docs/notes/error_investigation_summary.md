# Error Investigation Summary

This document serves as a log of the primary errors encountered during the refactoring of the EXL PM 2.5 Prediction Dashboard, explaining their root causes and how they were resolved.

## 1. PowerShell Boolean Evaluation Error
**Error:** `Error: object 'True' not found` during `.\run_app.ps1`
**Why it occurred:** The PowerShell script passed `$true` to the R command line. PowerShell converted this to the string `"True"`. R expects the uppercase keyword `TRUE` for booleans, so it interpreted `"True"` as an undefined variable.
**How to tackle:** Write a dedicated R wrapper script (`run_app.R`) that contains the clean `shiny::runApp()` command, and have PowerShell simply call `Rscript run_app.R`. This completely bypasses command-line string interpolation issues.

## 2. Missing `.rds` Files / Pathing Issues
**Error:** `cannot open compressed file 'data/eda_features.rds', probable reason 'No such file or directory'`
**Why it occurred:** R scripts were running from different working directories depending on how they were launched (e.g., via `testthat` with `chdir = TRUE` vs. from the project root via PowerShell). This caused relative paths like `../data/` or `data/` to resolve incorrectly.
**How to tackle:** Standardize all file paths to be relative to the project root (e.g., `"data/processed/..."`). Ensure that test scripts temporarily set the working directory to the project root before sourcing the main scripts.

## 3. Plotly and `gg_season` Date Formatting Bug
**Error:** `Error in time_identifier: object 'found_format' not found`
**Why it occurred:** When filtering data for the weekly `gg_season` plot, using date arithmetic like `max(time) - months(3)` on strict 4-hourly data created a fractional week boundary. The `feasts` package passed this irregular boundary to `plotly`, which failed to calculate a clean axis format.
**How to tackle:** Instead of arbitrary date math, use row-based slicing. Since the data is perfectly structured (6 observations per day), use `tail(504)` to extract exactly 12 full weeks of data. This ensures clean boundaries that `plotly` can render interactively.

## 4. Fable Formula Injection (Object is not a matrix)
**Error:** `object is not a matrix` during exogenous ARIMA modeling.
**Why it occurred:** Inside a `for` loop, the variable name was pasted into a string and converted to a formula: `as.formula(paste0("log1p(", var, ") ~ ARIMA()"))`. The highly optimized `fable` engine fails to evaluate dynamic string-based formulas correctly during its internal matrix operations.
**How to tackle:** Use Tidyverse/rlang metaprogramming for safe injection. Replace the string parsing with explicit unquoting using `rlang::sym()`: `model(mod = ARIMA(log1p(!!sym(var))))`.

## 5. Missing Data / Zero Variance Warnings
**Error:** `Warning: All observations are missing, a model cannot be estimated without data` and `NaNs produced`.
**Why it occurred:** Some cities in the dataset (like Kota or Srinagar) have 100% missing data (`NA`) for certain exogenous variables (like Ambient Temperature `AT`). When the loop tries to fit an ARIMA model to an empty series, `fable` throws a warning and correctly returns a `NULL` model/forecast for that variable.
**How to tackle:** Since this is expected behavior for messy real-world data and doesn't break the pipeline (the final PM 2.5 model handles the `NA` exogenous inputs gracefully), wrap the exogenous forecasting block in `suppressWarnings()`. This prevents terminal clutter and stops users from panicking over mathematically correct edge cases.
