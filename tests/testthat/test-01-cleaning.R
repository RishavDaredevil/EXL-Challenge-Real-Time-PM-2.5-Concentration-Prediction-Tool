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
