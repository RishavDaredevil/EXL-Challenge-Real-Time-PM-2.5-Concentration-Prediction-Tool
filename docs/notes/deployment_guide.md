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

## 2. WebAssembly Static Deployment (Cloudflare Pages / GitHub Pages)
If you want to host the Shiny dashboard on a completely static host (like Cloudflare Pages or GitHub Pages) without paying for or configuring a live R server, you can compile the entire R engine and your app into WebAssembly (Wasm) using `shinylive`.

This allows the user's web browser to download a miniature R environment and run your app locally using their own CPU!

**How to build and deploy:**
1. Open your terminal in the project root.
2. Run the build script I created:
   ```powershell
   Rscript build_shinylive.R
   ```
3. This script will download the Shinylive assets, analyze your `app.R` for dependencies, and bundle everything into a new folder: `docs/shinylive_app/`.
4. **For Cloudflare Pages:**
   - Go to your Cloudflare dashboard and create a new **Pages** project.
   - Choose **Direct Upload** (or link it to your Git repository and set the build output directory to `docs/shinylive_app`).
   - If using Direct Upload, simply drag and drop the `docs/shinylive_app/` folder into Cloudflare.
   - Your site will deploy instantly!

*Note: The first time a user visits the WebAssembly app, they will see a loading bar for a few seconds while their browser downloads the R core. Subsequent visits will be cached and load faster.*

## 3. The Shiny Dashboard (shinyapps.io)
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