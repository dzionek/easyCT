# UI part of save tab. Used to e

library(shinydashboard)

export_tab.menu <- menuItem("Export", tabName = "export", icon = icon("file-download"))

export_tab.body <- tabItem(
  tabName = "export",
  h2("EXPORT"),
  p("This tab is used to export your models and results from the application.")
)
