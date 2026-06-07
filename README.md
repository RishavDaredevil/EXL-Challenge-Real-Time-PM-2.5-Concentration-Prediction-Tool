# EXL Challenge - Real-Time PM 2.5 Concentration Prediction Tool

This repository contains the reconstructed code for the EXL EQ 2023 Challenge. 
It features a modular data pipeline and an interactive Shiny dashboard.

## Project Structure
- `data/`: Raw and processed data
- `scripts/`: Offline R scripts for cleaning, EDA, and modeling
- `app/`: Shiny application with pre-computed data

## How to Run
1. Run `scripts/01_data_cleaning.R`
2. Run `scripts/02_eda.R`
3. Run `scripts/03_modeling.R`
4. Launch the app by running `shiny::runApp("app")`