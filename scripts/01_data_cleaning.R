# scripts/01_data_cleaning.R
library(tidyverse)
library(tsibble)
library(hms)
library(lubridate)
library(readxl)

# Create mock data if raw data is missing for testing purposes
if(!file.exists("data/raw/EXL_EQ_2023_Dataset.xlsm")) {
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
  df <- read_excel("data/raw/EXL_EQ_2023_Dataset.xlsm")
}

# Clean and convert to tsibble
clean_tsibble <- df %>%
  mutate(`Time Periods` = as.POSIXct(`Time Periods`)) %>%
  # Fill missing values directionally
  group_by(City) %>%
  fill(everything(), .direction = "downup") %>%
  ungroup() %>%
  as_tsibble(key = c(State, City), index = `Time Periods`)

saveRDS(clean_tsibble, "data/processed/clean_tsibble.rds")
