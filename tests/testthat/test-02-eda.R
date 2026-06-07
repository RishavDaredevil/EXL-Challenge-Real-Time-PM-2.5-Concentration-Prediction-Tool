# tests/testthat/test-02-eda.R
library(testthat)

test_that("EDA script produces summary stats", {
  if(file.exists("../../app/data/eda_summaries.rds")) {
    file.remove("../../app/data/eda_summaries.rds")
  }
  source("../../scripts/02_eda.R", chdir = TRUE)
  expect_true(file.exists("../../app/data/eda_summaries.rds"))
})