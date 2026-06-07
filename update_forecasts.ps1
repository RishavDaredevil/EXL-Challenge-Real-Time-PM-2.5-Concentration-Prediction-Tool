# update_forecasts.ps1
param (
    [int]$Days = 365
)

Write-Host "========================================================"
Write-Host "Updating PM 2.5 Forecasts without re-training main models"
Write-Host "Horizon requested: $Days days"
Write-Host "========================================================"

Rscript scripts/04_update_forecasts.R $Days

if ($LASTEXITCODE -eq 0) {
    Write-Host "Successfully updated forecasts.rds." -ForegroundColor Green
    Write-Host "You can now launch the dashboard with .\run_app.ps1"
} else {
    Write-Host "An error occurred while updating forecasts." -ForegroundColor Red
}