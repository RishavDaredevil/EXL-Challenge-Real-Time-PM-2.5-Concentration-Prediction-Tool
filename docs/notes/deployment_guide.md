# Deployment Guide

Because this project consists of two different types of outputs (a static report and an interactive application), they must be deployed differently.

## 1. The Quarto Research Report (GitHub Pages)
GitHub Pages is a static file host. It is perfect for hosting your `research_methodology.html` report.

Because your raw data (`.xlsm`) and processed data (`.rds`) are too large for Git and are listed in `.gitignore`, GitHub's servers cannot run the R code to generate the report automatically. 

**How to deploy:**
1. Open `docs/reports/research_methodology.qmd` in RStudio.
2. Click the **Render** button. This will generate a `research_methodology.html` file in the same folder.
3. Commit that `.html` file to your repository and push to GitHub.
4. Go to your GitHub Repository Settings -> Pages.
5. Set the Source to **Deploy from a branch**. Select the `master` branch and set the folder to `/docs`.
6. Your report will now be live at `https://[your-username].github.io/[repo-name]/reports/research_methodology.html`!

## 2. The Shiny Dashboard (shinyapps.io)
GitHub Pages **cannot** run R code. Because Shiny apps require an active R server running in the background to handle the interactive slider logic and plot generation, it cannot be hosted on GitHub Pages.

The industry standard, free way to deploy a Shiny app is via **shinyapps.io** (owned by Posit/RStudio).

**How to deploy:**
1. Go to [shinyapps.io](https://www.shinyapps.io/) and create a free account.
2. Go to your Dashboard -> Account -> Tokens. Click **Show** and copy the `rsconnect::setAccountInfo(...)` command.
3. Open your terminal and start an R session (type `R`). Paste and run that command to link your computer to your account.
4. Quit R (`q()`) and run the deployment script I created for you:
   ```powershell
   Rscript deploy_app.R
   ```
5. R will automatically bundle up your `app/` folder (including the fast, pre-computed `.rds` files) and push it to the server. Your dashboard will be live on a public URL!