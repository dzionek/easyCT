library(shinydashboard)

time_tab.menu <- menuItem("Time", tabName = "time", icon = icon("dashboard"))

time_tab.body <- tabItem(
  tabName = "time",
  h2("Distribution over time")
)
