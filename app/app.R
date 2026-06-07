# app/app.R
library(shiny)
library(bslib)
library(fpp3)
library(plotly)

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
    helpText("Select a city to view historical EDA and upcoming 3-day forecasts.")
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
        tableOutput("stats_table")
      ),
      nav_panel("Time Plot",
        plotOutput("time_plot")
      ),
      nav_panel("Seasonal Plots",
        plotOutput("season_plot")
      ),
      nav_panel("STL Decomposition",
        plotOutput("stl_plot")
      )
    )
  ),
  
  nav_panel("Forecasts",
    card(
      card_header("3-Day Forecast"),
      plotlyOutput("forecast_plot")
    )
  )
)

server <- function(input, output, session) {
  
  output$stats_table <- renderTable({
    eda_features %>% filter(City == input$city)
  })
  
  output$time_plot <- renderPlot({
    clean_tsibble %>% 
      filter(City == input$city) %>% 
      autoplot(PM2.5) +
      labs(title = paste("PM 2.5 over Time in", input$city), x = "Time", y = "PM 2.5") +
      theme_minimal()
  })
  
  output$season_plot <- renderPlot({
    clean_tsibble %>% 
      filter(City == input$city) %>% 
      gg_season(PM2.5, period = "day") +
      labs(title = paste("Daily Seasonal Plot of PM 2.5 in", input$city), x = "Time of Day", y = "PM 2.5") +
      theme_minimal()
  })
  
  output$stl_plot <- renderPlot({
    stl_components %>% 
      filter(City == input$city) %>% 
      autoplot() +
      labs(title = paste("STL Decomposition of PM 2.5 in", input$city)) +
      theme_minimal()
  })
  
  output$forecast_plot <- renderPlotly({
    city_forecast <- forecasts %>% filter(City == input$city, Model == input$model)
    
    p <- ggplot(city_forecast, aes(x = `Time Periods`, y = exp(Predicted_PM2.5)-1)) +
      geom_line(color = "red") +
      geom_point() +
      labs(title = paste("PM 2.5 Forecasts for", input$city, "(", input$model, ")"), x = "Time", y = "Predicted PM 2.5") +
      theme_minimal()
      
    ggplotly(p)
  })
}

shinyApp(ui, server)