# UI part of time tab. Contains time series histograms useful for exploratory
# data analysis.

library(shinydashboard)
library(shinyFiles)
library(plotly)

time_tab.menu <- menuItem("Time", tabName = "time", icon = icon("dashboard"))

time_tab.body <- tabItem(tabName = "time", fluidRow(
  box(status = "danger", plotlyOutput("time_plot")),
  box(
    title = "Select photos", status = "primary", solidHeader = TRUE,
    h5("Select a folder with photos"),
    shinyDirButton("directory", "Folder select", "Please select a folder"),
    h5("You have selected:"),
    verbatimTextOutput("directory_path")
  ),
  box(
    title = "Histogram settings", status = "danger",
    radioButtons("bin_width", label = "Choose the bin width:",
                 choices = c("months", "weeks", "days", "hours"), 
                 selected = "days")
  ),
  box(status = "warning", plotlyOutput("activity_plot")),
  box(
    title = "Activity plot settings", status = "warning",
    selectInput("activity_type", label = "Choose the type of activity:",
                 choices = c("weekly", "daily"),
                 selected = "day"),
    selectInput("activity_function", label = "Choose the statistal function:",
                choices = c("mean", "median", "sum"), selected = "mean")
  )
))
