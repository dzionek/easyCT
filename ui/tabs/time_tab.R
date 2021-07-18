library(shinydashboard)
library(shinyFiles)
library(dygraphs)

time_tab.menu <- menuItem("Time", tabName = "time", icon = icon("dashboard"))

time_tab.body <- tabItem(
  tabName = "time",
  box(dygraphOutput("time_plot")),
  box(
    title = "Select photos", status = "info", solidHeader = TRUE,
    h5("Select a folder with photos"),
    shinyDirButton("directory", "Folder select", "Please select a folder"),
    h5("You have selected:"),
    verbatimTextOutput("directory_path")
  ),
  box(
    title = "Histogram settings", status = "info",
    radioButtons("bin_width", label = h5("Choose bin width:"),
                 choices = list("monthly" = "monthly", "daily" = "daily",
                                "hourly" = "hourly"), 
                 selected = "daily")
  )
)
