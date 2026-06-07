# EXL PM 2.5 Prediction Dashboard - Design Specification

## 1. Project Overview
This project reconstructs an entry for the EXL EQ 2023 Challenge. The goal is to forecast PM 2.5 concentrations across 34 Indian cities for the next 3 days (4-hourly spaced) using real-time historical data. The reconstructed repository will showcase clean software engineering practices, separating offline data processing and modeling from an interactive Shiny dashboard.

## 2. Repository Architecture & Directory Structure
The repository will follow a standard modular structure for R projects:

```text
EXL-PM2.5-Prediction/
├── README.md                # Project overview, methodology, and setup instructions
├── data/
│   ├── raw/                 # Original .xlsm and .rds files (git-ignored)
│   └── processed/           # Cleaned datasets ready for modeling
├── scripts/                 # Offline pipeline scripts
│   ├── 01_data_cleaning.R   # Cleans and formats the raw data
│   ├── 02_eda.R             # Generates pre-computed summaries for the app
│   └── 03_modeling.R        # Trains models and generates forecasts
└── app/                     # The Shiny Dashboard
    ├── app.R                # UI and Server logic
    └── data/                # Pre-computed forecasts and EDA summaries for the app
```

## 3. Data Processing Pipeline (Offline)
The offline pipeline refactors the original messy R scripts into a clean, reproducible sequence:

- **`01_data_cleaning.R`**: Reads the raw dataset, handles missing values (e.g., using `fill_gaps` and LOCF), and converts the time-series into a clean `tsibble` object.
- **`02_eda.R`**: Performs Principal Component Analysis (PCA) and time-series decomposition (STL) to identify daily and annual seasonality patterns. Saves summary statistics and decomposed components for the dashboard.
- **`03_modeling.R`**: 
  - Splits data for the 34 cities.
  - Trains three models:
    1. Univariate STL decomposition + ARIMA.
    2. Univariate Dynamic Harmonic Regression (DHR) with ARMA.
    3. Multivariate Stepwise Regression + DHR with ARMA.
  - Forecasts the next 3 days (4-hourly) for all cities, verifying the ~20-25% MAPE.
  - Saves the final forecast data frames to `app/data/forecasts.rds`.

## 4. Shiny Dashboard (App)
The interactive dashboard provides a responsive, user-friendly interface to explore the models and predictions. It will be built using `Shiny` and `bslib`.

- **Sidebar**: Controls to select the Target City and the Model Forecast to view.
- **Tab 1: Project Overview**: A summary of the EXL EQ 2023 Challenge, problem statement, and methodology.
- **Tab 2: Exploratory Data Analysis**: Visualizations of the pre-computed PCA and STL decomposition (showing daily and annual seasonality).
- **Tab 3: Forecasts**: Interactive time-series plots displaying historical PM 2.5 levels alongside the 3-day (4-hourly) predictions for the selected city and model.

## 5. Deployment and Validation
- The pipeline scripts must run sequentially without errors on the original dataset.
- The Shiny app must load instantly using only the pre-computed `.rds` files, demonstrating a lightweight and deployable architecture.
