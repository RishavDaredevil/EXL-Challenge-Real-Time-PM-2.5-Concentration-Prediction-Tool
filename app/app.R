# app/app.R
library(shiny)
library(bslib)
library(fpp3)
library(plotly)
library(DT)

# Load pre-computed data
eda_features <- readRDS("data/eda_features.rds")
stl_components <- readRDS("data/stl_components.rds")
forecasts <- readRDS("data/forecasts.rds")
clean_tsibble <- readRDS("data/clean_tsibble.rds")

ui <- page_navbar(
  title = "EXL PM 2.5 Real-Time Predictor",
  theme = bs_theme(version = 5, bootswatch = "flatly"),
  
  sidebar = sidebar(
    selectInput("city", "Select City:", choices = unique(eda_features$City)),
    selectInput("model", "Select Model Forecast:", choices = unique(forecasts$Model)),
    
    layout_columns(
      col_widths = c(8, 4),
      sliderInput("horizon_slider", "Forecast Horizon (Days):", min = 1, max = 365, value = 3, step = 1),
      numericInput("horizon_num", "Days:", min = 1, max = 365, value = 3, step = 1)
    ),
    
    helpText("Select a city to view historical EDA and upcoming Dynamic Horizon Forecast.")
  ),
  
  nav_panel("Overview",
    layout_columns(
      col_widths = c(12),
      card(
        card_header(class = "bg-primary text-white", "Project Executive Summary"),
        markdown("
### EXL EQ’ 2023 Challenge: Real-Time PM 2.5 Concentration Predictor

**The Objective:** Develop a robust, real-time prediction engine to forecast PM 2.5 concentrations across 34 major Indian cities. The goal was to predict pollution levels 3 days into the future (in 4-hour intervals) to help identify highly hazardous conditions and peak pollution windows.

**Methodology & Approach:**
* **Exploratory Data Analysis:** Identified strong multi-seasonal patterns, specifically diurnal (daily) and weekly/annual cycles in human activity and traffic that heavily influence PM 2.5 levels.
* **Feature Engineering:** Integrated meteorological variables and core pollutant data (NO, NO2, NOx, NH3, SO2, CO, Benzene, AT) to capture multivariate effects.
* **Forecasting Engine:** Developed a multi-model approach using the `fable` framework:
    1. **STL + ARIMA:** A univariate model utilizing STL decomposition on seasonally adjusted data.
    2. **Multivariate DHR:** Dynamic Harmonic Regression with ARMA errors, leveraging stepwise regression on exogenous environmental factors.

**Key Results:**
By combining robust seasonal decomposition with exogenous variable forecasting, the final Multivariate DHR model achieved a **Mean Absolute Percentage Error (MAPE) of approximately 20-25%**, providing highly actionable insights into upcoming hazardous air quality periods.

**Project Links:**
* 📖 **[Research Methodology Report (Quarto)](https://rishavdaredevil.github.io/EXL-Challenge-Real-Time-PM-2.5-Concentration-Prediction-Tool/reports/research_methodology.html)** - A comprehensive breakdown of the mathematics, data engineering, and EDA behind these models.
* 💻 **[GitHub Repository](https://github.com/RishavDaredevil/EXL-Challenge-Real-Time-PM-2.5-Concentration-Prediction-Tool)** - View the full source code and pipeline scripts.

**Tech Stack:**
`R` | `Tidyverse` | `Tidymodels` | `Tsibble` | `Fable` | `Shiny` | `bslib`
        ")
      )
    )
  ),
  
  nav_panel("EDA",
    navset_card_tab(
      nav_panel("Advanced Statistics",
        navset_pill(
          nav_panel("Basic Metrics", DTOutput("stats_basic")),
          nav_panel("Trend & Seasonality (STL)", DTOutput("stats_stl")),
          nav_panel("Autocorrelation (ACF)", DTOutput("stats_acf"))
        )
      ),
      nav_panel("Time Plot",
        plotlyOutput("time_plot")
      ),
      nav_panel("Seasonal Plots",
        navset_pill(
          nav_panel("Daily Pattern (14 Days)", plotlyOutput("season_plot_daily")),
          nav_panel("Weekly Pattern (4 Weeks)", plotlyOutput("season_plot_weekly")),
          nav_panel("Annual Pattern", plotlyOutput("season_plot_annual"))
        )
      ),
      nav_panel("STL Decomposition",
        plotOutput("stl_plot")
      )
    )
  ),
  
  nav_panel("Forecasts",
    card(
      card_header(textOutput("forecast_header")),
      plotlyOutput("forecast_plot")
    )
  )
)

server <- function(input, output, session) {
  
  # Sync slider and numeric inputs
  observeEvent(input$horizon_slider, {
    updateNumericInput(session, "horizon_num", value = input$horizon_slider)
  })
  
  observeEvent(input$horizon_num, {
    updateSliderInput(session, "horizon_slider", value = input$horizon_num)
  })
  
  # --- Advanced Statistics Tables (Grouped & Interactive) ---
  
  city_features <- reactive({
    eda_features %>% filter(City == input$city)
  })
  
  # Group 1: Basic Metrics
  output$stats_basic <- renderDT({
    req(nrow(city_features()) > 0)
    city_features() %>%
      select(starts_with("Mean_"), starts_with("Median_"), starts_with("Max_"), starts_with("P90_")) %>%
      pivot_longer(cols = everything(), names_to = "Metric", values_to = "Value") %>%
      datatable(options = list(dom = 't', paging = FALSE), 
                class = 'cell-border stripe hover', rownames = FALSE) %>%
      formatRound(columns = "Value", digits = 2)
  })
  
  # Group 2: STL Features (Trend and Seasonality strength)
  output$stats_stl <- renderDT({
    req(nrow(city_features()) > 0)
    city_features() %>%
      select(contains("strength"), contains("peak"), contains("trough"), spikiness, linearity, curvature) %>%
      pivot_longer(cols = everything(), names_to = "Metric", values_to = "Value") %>%
      datatable(options = list(dom = 't', paging = FALSE, scrollX = TRUE), 
                class = 'cell-border stripe hover', rownames = FALSE) %>%
      formatRound(columns = "Value", digits = 3)
  })
  
  # Group 3: ACF Features (Autocorrelation)
  output$stats_acf <- renderDT({
    req(nrow(city_features()) > 0)
    city_features() %>%
      select(contains("acf")) %>%
      pivot_longer(cols = everything(), names_to = "Metric", values_to = "Value") %>%
      datatable(options = list(dom = 't', paging = FALSE, scrollX = TRUE), 
                class = 'cell-border stripe hover', rownames = FALSE) %>%
      formatRound(columns = "Value", digits = 3)
  })
  
  # --- Interactive Plots ---
  
  output$time_plot <- renderPlotly({
    p <- clean_tsibble %>% 
      filter(City == input$city) %>% 
      autoplot(PM2.5) +
      labs(title = paste("PM 2.5 over Time in", input$city), x = "Time", y = "PM 2.5") +
      theme_minimal()
    ggplotly(p)
  })
  
  # Seasonal Plot 1: Daily Pattern (Filtered to a recent 14 days to avoid crisscrossing mess)
  output$season_plot_daily <- renderPlotly({
    recent_data <- clean_tsibble %>% 
      filter(City == input$city) %>%
      tail(84) # 14 days * 6 obs/day
      
    p <- recent_data %>% 
      gg_season(PM2.5, period = "day") +
      labs(title = "Daily Pattern (Last 14 Days)", x = "Time of Day", y = "PM 2.5") +
      theme_minimal() +
      theme(legend.position = "none") 
    ggplotly(p)
  })
  
  # Seasonal Plot 2: Weekly Pattern (Filtered to recent 4 weeks)
  output$season_plot_weekly <- renderPlotly({
    recent_data <- clean_tsibble %>% 
      filter(City == input$city) %>%
      tail(168) # 4 weeks * 42 obs/week
      
    p <- recent_data %>% 
      gg_season(PM2.5, period = "week") +
      labs(title = "Weekly Pattern (Last 4 Weeks)", x = "Day of Week", y = "PM 2.5") +
      theme_minimal() +
      theme(legend.position = "none")
    ggplotly(p)
  })
  
  # Seasonal Plot 3: Annual Pattern (All data)
  output$season_plot_annual <- renderPlotly({
    p <- clean_tsibble %>% 
      filter(City == input$city) %>% 
      gg_season(PM2.5, period = "year") +
      labs(title = "Annual Pattern", x = "Month", y = "PM 2.5") +
      theme_minimal()
    ggplotly(p)
  })
  
  output$stl_plot <- renderPlot({
    stl_components %>% 
      filter(City == input$city) %>% 
      autoplot() +
      labs(title = paste("STL Decomposition of PM 2.5 in", input$city)) +
      theme_minimal()
  })
  
  output$forecast_header <- renderText({
    paste("Dynamic Horizon Forecast (", input$horizon_num, " Days)", sep = "")
  })
  
  output$forecast_plot <- renderPlotly({
    req_periods <- input$horizon_num * 6
    
    city_forecast <- forecasts %>% 
      filter(City == input$city, Model == input$model) %>%
      arrange(`Time Periods`) %>%
      head(req_periods)
    
    p <- ggplot(city_forecast, aes(x = `Time Periods`, y = Predicted_PM2.5)) +
      geom_line(color = "red") +
      geom_point() +
      labs(title = paste("PM 2.5 Forecasts for", input$city, "(", input$model, ")"), x = "Time", y = "Predicted PM 2.5") +
      theme_minimal()
      
    ggplotly(p)
  })
}

shinyApp(ui, server)