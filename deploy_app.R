# deploy_app.R
# This script deploys the Shiny dashboard to shinyapps.io

if (!require("rsconnect")) install.packages("rsconnect")
library(rsconnect)

cat("Checking for required data files...\n")
if (!file.exists("app/data/forecasts.rds") || !file.exists("app/data/eda_features.rds")) {
  stop("Data files are missing! You must run the data pipeline (.\\run_pipeline.ps1) locally before deploying to ensure the app has data to display.")
}

cat("Deploying Shiny App to shinyapps.io...\n")
# Make sure you have set up your account using rsconnect::setAccountInfo() first!
rsconnect::deployApp(appDir = "app", appName = "EXL-PM25-Predictor")
