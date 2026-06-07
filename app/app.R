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
clean_tsibble <- readRDS("../data/processed/clean_tsibble.rds")

ui <- page_navbar(
  title = "EXL PM 2.5 Real-Time Predictor",
  theme = bs_theme(version = 5, bootswatch = "flatly"),
  
  sidebar = sidebar(
    selectInput("city", "Select City:", choices = unique(eda_features$City)),
    selectInput("model", "Select Model Forecast:", choices = unique(forecasts$Model)),
    sliderInput("horizon", "Forecast Horizon (Days):", min = 1, max = 365, value = 3, step = 1),
    helpText("Select a city to view historical EDA and upcoming Dynamic Horizon Forecast.")
  ),
  
  nav_panel("Overview",
    card(
      card_header("Project Information"),
      markdown("This dashboard presents the results of the EXL EQ 2023 Challenge. It forecasts 4-hourly PM 2.5 concentrations for 34 Indian cities.")
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
          nav_panel("Daily Pattern (Month)", plotlyOutput("season_plot_daily")),
          nav_panel("Weekly Pattern (3 Months)", plotlyOutput("season_plot_weekly")),
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
  
  # Seasonal Plot 1: Daily Pattern (Filtered to a recent month to avoid crisscrossing mess)
  output$season_plot_daily <- renderPlotly({
    recent_data <- clean_tsibble %>% 
      filter(City == input$city) %>%
      tail(180) # 30 days * 6 obs/day
      
    p <- recent_data %>% 
      gg_season(PM2.5, period = "day") +
      labs(title = "Daily Pattern (Last 30 Days)", x = "Time of Day", y = "PM 2.5") +
      theme_minimal() +
      theme(legend.position = "none") 
    ggplotly(p)
  })
  
  # Seasonal Plot 2: Weekly Pattern (Filtered to recent 3 months)
  output$season_plot_weekly <- renderPlotly({
    recent_data <- clean_tsibble %>% 
      filter(City == input$city) %>%
      tail(504) # 12 weeks * 42 obs/week
      
    p <- recent_data %>% 
      gg_season(PM2.5, period = "week") +
      labs(title = "Weekly Pattern (Last 12 Weeks)", x = "Day of Week", y = "PM 2.5") +
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
    paste("Dynamic Horizon Forecast (", input$horizon, " Days)", sep = "")
  })
  
  output$forecast_plot <- renderPlotly({
    req_periods <- input$horizon * 6
    
    city_forecast <- forecasts %>% 
      filter(City == input$city, Model == input$model) %>%
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