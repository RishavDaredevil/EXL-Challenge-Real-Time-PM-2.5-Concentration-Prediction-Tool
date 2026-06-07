# EXL EQ' 2023 Challenge: Real-Time PM 2.5 Concentration Prediction Tool

This repository contains the reconstructed and optimized codebase for an entry into the EXL EQ' 2023 Challenge. The objective is to provide a highly robust, real-time prediction engine forecasting PM 2.5 concentrations across 34 major Indian cities, 3 days into the future at 4-hour intervals.

## 📖 Research & Methodology

A comprehensive breakdown of the data engineering, multi-seasonal exploratory data analysis, and the mathematical formulation of the forecasting models can be found in the accompanying Quarto document:

**👉 [Read the Full Research Methodology Report Here](https://rishavdaredevil.github.io/EXL-Challenge-Real-Time-PM-2.5-Concentration-Prediction-Tool/reports/research_methodology.html)**

### Modeling Approach
The project utilizes the `fable` (fpp3) ecosystem to test three progressive approaches:
1. **STL + ARIMA:** Univariate modeling on seasonally adjusted data.
2. **DHR + ARMA:** Univariate Dynamic Harmonic Regression utilizing dual Fourier terms (Daily and Annual) to handle complex overlapping seasonalities.
3. **Multivariate DHR:** The final model, which integrates exogenous meteorological and pollutant variables (NO, NO2, CO, etc.) using stepwise regression, achieving a steady-state MAPE of ~20-25%.

## 🏗️ Project Architecture

To ensure high performance in the interactive UI, the heavy mathematical training is completely decoupled from the visualization dashboard.

* `data/`: Contains raw datasets and the processed `tsibble` objects.
* `scripts/`: Offline R scripts for data cleaning, advanced feature extraction, and massive model training.
* `app/`: A lightweight, lightning-fast Shiny dashboard that reads pre-computed forecasts and features.
* `docs/`: Deployment guides, research notes, and the Quarto HTML report.

## 🚀 How to Run Locally

If you are pulling this repository for the first time, you must run the data pipeline to generate the pre-computed models and data files.

### 1. Build the Models (Run Once)
Run the full pipeline to clean the data, generate advanced time-series features, and train the massive `fable` models. This step will take several minutes.
```powershell
.\run_pipeline.ps1
```

### 2. Update Forecasts Dynamically
If you want to change the forecast horizon (e.g., predict 90 days into the future instead of 1 year), you do **not** need to retrain the models. Use the fast-updater script, which uses a model cache to instantly generate new predictions using Last Observation Carried Forward (LOCF) for missing exogenous variables.
```powershell
.\update_forecasts.ps1 -Days 90
```

### 3. Launch the Dashboard
Once the data is generated, launch the interactive Shiny app:
```powershell
.\run_app.ps1
```

## ☁️ Deployment

The project is structured to support flexible cloud deployments. See `docs/notes/deployment_guide.md` for full instructions.

* **Shinyapps.io:** Use the included `deploy_app.R` script to push the bundled `app/` folder to a live R server.
* **WebAssembly (Cloudflare/GitHub Pages):** The app is entirely compatible with `webr`. Use the included `build_shinylive.R` script to compile the R engine and app into a static WebAssembly bundle that runs entirely in the user's browser, requiring zero backend server architecture.