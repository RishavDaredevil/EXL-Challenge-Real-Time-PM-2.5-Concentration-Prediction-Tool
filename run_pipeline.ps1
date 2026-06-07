# run_pipeline.ps1
# This script runs the data processing and modeling pipeline sequentially.
# Note: The modeling step can take several minutes depending on the dataset size.

Write-Host "Step 1: Cleaning Data..."
Rscript scripts/01_data_cleaning.R

Write-Host "Step 2: Generating EDA Summaries..."
Rscript scripts/02_eda.R

Write-Host "Step 3: Training Time-Series Models (This may take a while)..."
Rscript scripts/03_modeling.R

Write-Host "Pipeline Complete! You can now launch the dashboard using .\run_app.ps1"
