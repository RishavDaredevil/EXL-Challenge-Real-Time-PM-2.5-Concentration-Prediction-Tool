# EXL Challenge - Real-Time PM 2.5 Concentration Prediction Tool

This repository contains the reconstructed code for the EXL EQ 2023 Challenge. 
It features a modular data pipeline and an interactive Shiny dashboard.

## Project Structure
- `data/`: Raw and processed data
- `scripts/`: Offline R scripts for cleaning, EDA, and modeling
- `app/`: Shiny application with pre-computed data

## How to Run
1. Execute the scripts in `scripts/` in order (01, 02, 03) to process the data and generate models.
2. Launch the Shiny app by running the provided launcher script for your platform:
   - On Windows (Command Prompt): Double-click `run_app.bat` or run `.\run_app.bat`
   - On Windows (PowerShell): Run `.\run_app.ps1`
   - Or, manually via Rscript: `Rscript -e "shiny::runApp('app', port=8080)"`