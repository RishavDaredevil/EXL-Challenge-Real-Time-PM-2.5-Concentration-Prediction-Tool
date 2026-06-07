# Project Goal: Generate Research Quarto Document (`research_methodology.qmd`)



You are acting as a senior data scientist. I need to create a comprehensive Quarto document detailing my research, methodology, and modeling approach for the EXL EQ’ 2023 Challenge. 



Please generate a file named `research_methodology.qmd` using the exact structure, text, LaTeX equations, and R code snippets provided below.



---```yaml

---

title: "Forecasting PM 2.5 in Indian Cities: A Multi-Seasonal Approach"

subtitle: "Research and Methodology for the EXL EQ' 2023 Challenge"

author: "Your Name"

date: today

format: 

  html:    theme: flatly

    toc: true

    toc-depth: 3

    number-sections: true

    code-fold: show

    code-tools: true

execute:

  warning: false

  message: false

---

1. Executive Summary

This document details the analytical methodology used to develop a robust, real-time prediction tool to forecast PM 2.5 concentrations across 34 Indian cities. The objective of the EXL EQ' 2023 Challenge was to predict pollution levels 3 days into the future at 4-hour intervals. By identifying complex multi-seasonal patterns and incorporating exogenous environmental factors, the final Multivariate Dynamic Harmonic Regression (DHR) model achieved a Mean Absolute Percentage Error (MAPE) of approximately 20-25%.

2. Data Engineering & Preprocessing

The dataset consisted of 4-hourly spaced observations over three years. Proper handling of this high-frequency time series was critical.

2.1 The tsibble Framework

The data was ingested and converted into a tsibble object to explicitly define the temporal structure and the nested geographical hierarchies (State > City).

R



library(tidyverse)

library(tsibble)

library(fable)

library(feasts)# Data ingestion and tsibble creation

clean_tsibble <- readRDS("data/processed/clean_tsibble.rds")

2.2 Feature Selection & Transformations

A critical step in stabilizing the variance of the highly skewed PM 2.5 data was applying a logarithmic transformation. To prevent mathematical instability with zero values, a $\log(x+1)$ transformation was utilized. Static demographic variables (e.g., latitude, population) were excluded from the final matrix to prevent rank deficiencies, focusing strictly on dynamic exogenous features: NO, NO2, NOx, NH3, SO2, CO, Benzene, and AT.

3. Exploratory Data Analysis (EDA)

Exploratory analysis revealed highly complex, overlapping seasonal structures within the PM 2.5 series.

3.1 Multi-Seasonal Decomposition

Using fabletools::gg_season() and STL decomposition, three distinct seasonalities were identified:

Diurnal (Daily): Peaks during morning and evening rush hours, dropping during midday.

Weekly: Noticeable reductions in PM 2.5 during weekends due to decreased industrial and commuting activity.

Annual: Severe spikes during winter months due to atmospheric inversion and agricultural burning.

R



clean_tsibble |> 

  filter(City == "Delhi") |> 

  model(STL(log1p(PM2.5) ~ season(period = "day") + season(period = "week") + season(period = "year"), robust = TRUE)) |> 

  components() |> 

  autoplot()

4. Model Formulation

To capture the complex dynamics of the data, three progressive forecasting models were developed.

4.1 Model 1: STL + ARIMA

The first approach isolated the seasonal components using a robust Seasonal and Trend decomposition using Loess (STL). An ARIMA model was then fitted strictly to the seasonally adjusted data.

4.2 Model 2: Univariate Dynamic Harmonic Regression (DHR)

To handle multiple complex seasonalities simultaneously without decomposing the data, a Dynamic Harmonic Regression model with ARMA errors was formulated. This model utilizes Fourier terms to represent the seasonal cycles.

The mathematical representation of the univariate DHR model is:

$$ y_t = \beta_0 + \sum_{i=1}^M \sum_{j=1}^{K_i} \left( \alpha_{i,j} \sin\left(\frac{2\pi j t}{m_i}\right) + \gamma_{i,j} \cos\left(\frac{2\pi j t}{m_i}\right) \right) + \eta_t $$

Where $m_i$ represents the seasonal periods (daily, weekly, annual), $K_i$ represents the number of Fourier pairs for each period, and $\eta_t$ is an ARIMA process. To avoid the Nyquist limit instability on 4-hourly data (6 periods/day), $K_{\text{day}}$ was restricted to 2.

4.3 Model 3: Multivariate DHR

The final and most robust model integrated the exogenous meteorological and pollutant variables into the DHR framework.

$$ y_t = \text{Fourier Terms} + \sum_{k=1}^P \delta_k x_{k,t} + \eta_t $$

Where $x_{k,t}$ represents the exogenous variables at time $t$.

R



# Multivariate DHR formulation

multivariate_formula <- as.formula(

  "log1p(PM2.5) ~ fourier(period = 'day', K = 2) + 

                  fourier(period = 'week', K = 3) + 

                  fourier(period = 'year', K = 5) + 

                  log1p(NO) + log1p(NO2) + log1p(CO) + log1p(Benzene)"

)



fit <- clean_tsibble |> 

  model(

    `Multivariate DHR` = ARIMA(!!multivariate_formula)

  )

5. Forecasting & Exogenous Simulation

To forecast PM 2.5 72 hours into the future, the multivariate model requires future states of its exogenous predictors. A secondary modeling pipeline was developed to generate baseline ARIMA forecasts for all exogenous variables before feeding them into the primary PM 2.5 prediction engine.

R



# Note: Code for generating future exogenous variables is detailed in the production pipeline (03_modeling.R).

6. Results and Conclusion

The inclusion of dual-Fourier terms and stepwise multivariate integration successfully stabilized the extreme variance of the raw data.

Accuracy: The final Multivariate DHR model achieved a steady-state MAPE of $20\% - 25\%$ on the holdout sets.

Deployment: The models were serialized and connected to a reactive Shiny dashboard (app.R), allowing users to dynamically interact with the forecasts and historical decompositions without incurring real-time computational overhead.