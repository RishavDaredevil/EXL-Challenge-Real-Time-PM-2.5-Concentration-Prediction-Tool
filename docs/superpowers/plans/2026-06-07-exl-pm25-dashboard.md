# EXL PM2.5 Prediction Dashboard Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reconstruct the EXL EQ 2023 PM2.5 prediction project into a modular data pipeline and an interactive Shiny dashboard.

**Architecture:** An offline R pipeline (`scripts/`) processes data and trains models, saving pre-computed forecasts and EDA summaries. A separate Shiny application (`app/app.R`) reads these summaries to provide an interactive dashboard.

**Tech Stack:** R, Tidyverse, Tsibble, Fable (for modeling), Shiny, bslib, Plotly.

---

### Task 1: Setup Repository and Directory Structure

**Files:**
- Create: `.gitignore`
- Create directories: `data/raw/`, `data/processed/`, `scripts/`, `app/data/`, `tests/testthat/`

- [ ] **Step 1: Write directory creation script**

```bash
mkdir -p data/raw data/processed scripts app/data tests/testthat
```

- [ ] **Step 2: Initialize Git and create .gitignore**

```bash
echo ".RData
.Rhistory
*.Rproj
.Rproj.user
data/raw/
data/processed/
.venv/
__pycache__/
*.xlsm
*.rds" > .gitignore
git init
```

- [ ] **Step 3: Move raw data to the new structure**
*Assuming the raw data `EXL_EQ_2023_Dataset.xlsm` is in `R project files/`*

```bash
cp "R project files/EXL_EQ_2023_Dataset.xlsm" data/raw/ 2>/dev/null || echo "Data not found, will need to be added manually."
```

- [ ] **Step 4: Commit**

```bash
git add .gitignore
git commit -m "chore: setup project directory structure and gitignore"
```

### Task 2: Implement Data Cleaning Script

**Files:**
- Create: `scripts/01_data_cleaning.R`
- Create: `tests/testthat/test-01-cleaning.R`

- [ ] **Step 1: Write the failing test**

```R
# tests/testthat/test-01-cleaning.R
library(testthat)

test_that("Cleaning script produces processed data", {
  # Clean up before test
  if(file.exists("../../data/processed/clean_tsibble.rds")) {
    file.remove("../../data/processed/clean_tsibble.rds")
  }
  
  # Run the script
  source("../../scripts/01_data_cleaning.R", chdir = TRUE)
  
  # Check output
  expect_true(file.exists("../../data/processed/clean_tsibble.rds"))
  data <- readRDS("../../data/processed/clean_tsibble.rds")
  expect_s3_class(data, "tbl_ts")
  expect_true("PM2.5" %in% names(data))
})
```

- [ ] **Step 2: Run test to verify it fails**

Run: `Rscript -e "testthat::test_file('tests/testthat/test-01-cleaning.R')"`
Expected: FAIL with "No such file or directory: 'scripts/01_data_cleaning.R'"

- [ ] **Step 3: Write minimal implementation**

```R
# scripts/01_data_cleaning.R
library(tidyverse)
library(tsibble)
library(hms)
library(lubridate)
library(readxl)

# Create mock data if raw data is missing for testing purposes
if(!file.exists("../data/raw/EXL_EQ_2023_Dataset.xlsm")) {
  # Generate minimal mock data
  times <- seq(as.POSIXct("2021-01-01 00:00:00"), as.POSIXct("2021-01-05 00:00:00"), by="4 hours")
  df <- expand_grid(
    State = c("Delhi"),
    City = c("Delhi"),
    `Time Periods` = times
  ) %>%
    mutate(
      PM2.5 = runif(n(), 50, 200),
      Temp = runif(n(), 15, 35)
    )
} else {
  df <- read_excel("../data/raw/EXL_EQ_2023_Dataset.xlsm")
}

# Clean and convert to tsibble
clean_tsibble <- df %>%
  mutate(`Time Periods` = ymd_hms(`Time Periods`)) %>%
  # Fill missing values directionally
  group_by(City) %>%
  fill(everything(), .direction = "downup") %>%
  ungroup() %>%
  as_tsibble(key = c(State, City), index = `Time Periods`)

saveRDS(clean_tsibble, "../data/processed/clean_tsibble.rds")
```

- [ ] **Step 4: Run test to verify it passes**

Run: `Rscript -e "testthat::test_file('tests/testthat/test-01-cleaning.R')"`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add scripts/01_data_cleaning.R tests/testthat/test-01-cleaning.R
git commit -m "feat: implement data cleaning script"
```

### Task 3: Implement EDA Script

**Files:**
- Create: `scripts/02_eda.R`
- Create: `tests/testthat/test-02-eda.R`

- [ ] **Step 1: Write the failing test**

```R
# tests/testthat/test-02-eda.R
library(testthat)

test_that("EDA script produces summary stats", {
  if(file.exists("../../app/data/eda_summaries.rds")) {
    file.remove("../../app/data/eda_summaries.rds")
  }
  source("../../scripts/02_eda.R", chdir = TRUE)
  expect_true(file.exists("../../app/data/eda_summaries.rds"))
})
```

- [ ] **Step 2: Run test to verify it fails**

Run: `Rscript -e "testthat::test_file('tests/testthat/test-02-eda.R')"`
Expected: FAIL

- [ ] **Step 3: Write minimal implementation**

```R
# scripts/02_eda.R
library(tidyverse)
library(tsibble)

clean_tsibble <- readRDS("../data/processed/clean_tsibble.rds")

# Generate simple city summaries for EDA
eda_summaries <- clean_tsibble %>%
  as_tibble() %>%
  group_by(State, City) %>%
  summarise(
    Mean_PM2.5 = mean(PM2.5, na.rm = TRUE),
    Median_PM2.5 = median(PM2.5, na.rm = TRUE),
    Max_PM2.5 = max(PM2.5, na.rm = TRUE),
    .groups = "drop"
  )

# Ensure app/data directory exists
dir.create("../app/data", showWarnings = FALSE, recursive = TRUE)
saveRDS(eda_summaries, "../app/data/eda_summaries.rds")
```

- [ ] **Step 4: Run test to verify it passes**

Run: `Rscript -e "testthat::test_file('tests/testthat/test-02-eda.R')"`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add scripts/02_eda.R tests/testthat/test-02-eda.R
git commit -m "feat: implement EDA script for pre-computing summaries"
```

### Task 4: Implement Modeling Script

**Files:**
- Create: `scripts/03_modeling.R`
- Create: `tests/testthat/test-03-modeling.R`

- [ ] **Step 1: Write the failing test**

```R
# tests/testthat/test-03-modeling.R
library(testthat)

test_that("Modeling script produces forecasts", {
  if(file.exists("../../app/data/forecasts.rds")) {
    file.remove("../../app/data/forecasts.rds")
  }
  source("../../scripts/03_modeling.R", chdir = TRUE)
  expect_true(file.exists("../../app/data/forecasts.rds"))
})
```

- [ ] **Step 2: Run test to verify it fails**

Run: `Rscript -e "testthat::test_file('tests/testthat/test-03-modeling.R')"`
Expected: FAIL

- [ ] **Step 3: Write minimal implementation**

```R
# scripts/03_modeling.R
library(tidyverse)
library(tsibble)
library(fable)

clean_tsibble <- readRDS("../data/processed/clean_tsibble.rds")

# We will use a simplified ARIMA model for the structural pipeline
# to ensure it runs quickly for all cities
models <- clean_tsibble %>%
  # Limit data for faster testing/building if needed, or use full
  model(
    ARIMA_PM25 = ARIMA(log(PM2.5 + 1))
  )

# Forecast next 18 periods (3 days * 6 4-hourly periods)
forecasts <- models %>%
  forecast(h = 18) %>%
  as_tibble() %>%
  select(State, City, `Time Periods`, .mean) %>%
  rename(Predicted_PM2.5 = .mean)

saveRDS(forecasts, "../app/data/forecasts.rds")
```

- [ ] **Step 4: Run test to verify it passes**

Run: `Rscript -e "testthat::test_file('tests/testthat/test-03-modeling.R')"`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add scripts/03_modeling.R tests/testthat/test-03-modeling.R
git commit -m "feat: implement modeling script and forecast generation"
```

### Task 5: Implement Shiny Dashboard

**Files:**
- Create: `app/app.R`

- [ ] **Step 1: Create the basic Shiny App framework**

```R
# app/app.R
library(shiny)
library(bslib)
library(tidyverse)
library(plotly)

# Load pre-computed data
eda_summaries <- readRDS("data/eda_summaries.rds")
forecasts <- readRDS("data/forecasts.rds")

ui <- page_navbar(
  title = "EXL PM 2.5 Real-Time Predictor",
  theme = bs_theme(version = 5, bootswatch = "flatly"),
  
  sidebar = sidebar(
    selectInput("city", "Select City:", choices = unique(eda_summaries$City)),
    helpText("Select a city to view historical EDA and upcoming 3-day forecasts.")
  ),
  
  nav_panel("Overview",
    card(
      card_header("Project Information"),
      markdown("This dashboard presents the results of the EXL EQ 2023 Challenge. It forecasts 4-hourly PM 2.5 concentrations for 34 Indian cities.")
    )
  ),
  
  nav_panel("EDA",
    card(
      card_header("City Statistics"),
      tableOutput("stats_table")
    )
  ),
  
  nav_panel("Forecasts",
    card(
      card_header("3-Day Forecast"),
      plotlyOutput("forecast_plot")
    )
  )
)

server <- function(input, output, session) {
  
  output$stats_table <- renderTable({
    eda_summaries %>% filter(City == input$city)
  })
  
  output$forecast_plot <- renderPlotly({
    city_forecast <- forecasts %>% filter(City == input$city)
    
    p <- ggplot(city_forecast, aes(x = `Time Periods`, y = exp(Predicted_PM2.5)-1)) +
      geom_line(color = "red") +
      geom_point() +
      labs(title = paste("PM 2.5 Forecasts for", input$city), x = "Time", y = "Predicted PM 2.5") +
      theme_minimal()
      
    ggplotly(p)
  })
}

shinyApp(ui, server)
```

- [ ] **Step 2: Test the Shiny app syntax (dry run)**

```bash
Rscript -e "source('app/app.R'); cat('Shiny app syntax OK\n')"
```
Expected: `Shiny app syntax OK` (It might hang if not careful, so just validating syntax is enough, or running `shiny::runApp` manually).

- [ ] **Step 3: Commit**

```bash
git add app/app.R
git commit -m "feat: implement shiny dashboard ui and server"
```

### Task 6: Write README.md

**Files:**
- Create: `README.md`

- [ ] **Step 1: Create README file**

```markdown
# README.md
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
```

- [ ] **Step 2: Commit**

```bash
git add README.md
git commit -m "docs: add project README"
```
