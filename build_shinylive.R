# build_shinylive.R
# This script compiles the Shiny app into a static WebAssembly bundle using shinylive.

# 1. Install shinylive if it's not already installed
if (!require("shinylive")) {
  install.packages("shinylive", repos = "https://cran.rstudio.com/")
}
library(shinylive)

cat("Starting Shinylive WebAssembly Export...\n")
cat("This may take a few minutes as it packages the R engine and dependencies.\n")

# Ensure the output directory exists and is clean
out_dir <- "docs/shinylive_app"
if (dir.exists(out_dir)) {
  unlink(out_dir, recursive = TRUE)
}
dir.create(out_dir, recursive = TRUE)

# 2. Export the app to WebAssembly
# This analyzes app.R, finds dependencies (bslib, fpp3, plotly, DT), 
# and builds a static bundle in docs/shinylive_app
tryCatch({
  shinylive::export(appdir = "app", destdir = out_dir)
  cat("\nSuccess! The WebAssembly app has been built in:", out_dir, "\n")
  cat("You can now deploy the contents of this folder to Cloudflare Pages or GitHub Pages.\n")
}, error = function(e) {
  cat("\nAn error occurred during Shinylive export:\n", e$message, "\n")
})
