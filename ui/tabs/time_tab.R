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
    verbatimTextOutput("directorypath")
  )
)
