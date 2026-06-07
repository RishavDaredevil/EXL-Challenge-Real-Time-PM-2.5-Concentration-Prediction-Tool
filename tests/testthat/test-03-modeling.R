# tests/testthat/test-03-modeling.R
library(testthat)

test_that("Modeling script produces forecasts", {
  if(file.exists("../../app/data/forecasts.rds")) {
    file.remove("../../app/data/forecasts.rds")
  }
  source("../../scripts/03_modeling.R", chdir = TRUE)
  expect_true(file.exists("../../app/data/forecasts.rds"))
})