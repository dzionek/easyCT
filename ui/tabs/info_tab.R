# UI part of info tab. Contains description of the application.

library(shinydashboard)

info_tab.menu <- menuItem("Description", tabName = "info", icon = icon("info"))

info_tab.body <- tabItem(
  tabName = "info",
  h2("How does this work?"),
  p("Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.")
)
