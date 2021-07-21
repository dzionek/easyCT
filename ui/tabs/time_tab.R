# UI part of time tab. Contains time series histograms useful for exploratory
# data analysis.

library(shinydashboard)
library(shinyFiles)
library(shinyTime)

library(plotly)
library(DT)

time_tab.menu <- menuItem("Time", tabName = "time", icon = icon("dashboard"))

time_tab.body <- tabItem(tabName = "time", fluidRow(
  # Histogram
  box(status = "success", plotlyOutput("time_plot")),
  box(
    title = "Select photos", status = "primary", solidHeader = TRUE,
    h5("Select a folder with photos"),
    shinyDirButton("directory", "Folder select", "Please select a folder"),
    h5("You have selected:"),
    verbatimTextOutput("directory_path")
  ),
  box(
    title = "Histogram settings", status = "success",
    radioButtons("bin_width", label = "Choose the bin width:",
                 choices = c("months", "weeks", "days", "hours"), 
                 selected = "days")
  ),
  
  # Activity plot
  box(status = "warning", plotlyOutput("activity_plot")),
  box(
    title = "Activity plot settings", status = "warning",
    selectInput("activity_type", label = "Choose the type of activity:",
                 choices = c("weekly", "daily"),
                 selected = "day"),
    selectInput("activity_function", label = "Choose the statistal function:",
                choices = c("mean", "median", "sum"), selected = "mean")
  ),
  
  # Selecting dates
  uiOutput("datetime_selection"),
  
  # Selected photos panel
  box(
    title = "Selected photos", status = "danger", width = 12,
    DT::dataTableOutput("selected_photos")
  )
))
