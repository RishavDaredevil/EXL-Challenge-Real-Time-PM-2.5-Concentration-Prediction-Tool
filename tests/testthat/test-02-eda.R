# tests/testthat/test-02-eda.R
library(testthat)

test_that("EDA script produces summary stats and stl components", {
  # Temporarily change working directory to project root
  old_wd <- setwd("../..")
  on.exit(setwd(old_wd))
  
  if(file.exists("app/data/eda_features.rds")) {
    file.remove("app/data/eda_features.rds")
  }
  if(file.exists("app/data/stl_components.rds")) {
    file.remove("app/data/stl_components.rds")
  }
  source("scripts/02_eda.R")
  expect_true(file.exists("app/data/eda_features.rds"))
  expect_true(file.exists("app/data/stl_components.rds"))
})