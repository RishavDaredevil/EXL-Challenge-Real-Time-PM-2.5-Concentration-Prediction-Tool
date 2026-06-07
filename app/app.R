# app/app.R
library(shiny)
library(bslib)
library(tidyverse)
library(plotly)

# Load pre-computed data
eda_summaries <- readRDS("data/eda_summaries.rds")
forecasts <- readRDS("data/forecasts.rds")

ui <- page_navbar(
  title = "EXL PM 2.5 Real-Time Predictor",
  theme = bs_theme(version = 5, bootswatch = "flatly"),
  
  sidebar = sidebar(
    selectInput("city", "Select City:", choices = unique(eda_summaries$City)),
    helpText("Select a city to view historical EDA and upcoming 3-day forecasts.")
  ),
  
  nav_panel("Overview",
    card(
      card_header("Project Information"),
      markdown("This dashboard presents the results of the EXL EQ 2023 Challenge. It forecasts 4-hourly PM 2.5 concentrations for 34 Indian cities.")
    )
  ),
  
  nav_panel("EDA",
    card(
      card_header("City Statistics"),
      tableOutput("stats_table")
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
    eda_summaries %>% filter(City == input$city)
  })
  
  output$forecast_plot <- renderPlotly({
    city_forecast <- forecasts %>% filter(City == input$city)
    
    p <- ggplot(city_forecast, aes(x = `Time Periods`, y = exp(Predicted_PM2.5)-1)) +
      geom_line(color = "red") +
      geom_point() +
      labs(title = paste("PM 2.5 Forecasts for", input$city), x = "Time", y = "Predicted PM 2.5") +
      theme_minimal()
      
    ggplotly(p)
  })
}

shinyApp(ui, server)
