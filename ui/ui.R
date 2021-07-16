# Front-end part of the application

library(shinydashboard)

source("ui/tabs/time_tab.R")
source("ui/tabs/classifier_tab.R")

sidebar <- dashboardSidebar(
  sidebarMenu(
    time_tab.menu,
    classifier_tab.menu,
    menuItem("GitHub", icon = icon("github"),
             href = "https://github.com/dzionek/easyCT")
  )
)

body <- dashboardBody(
  tabItems(
    time_tab.body,
    classifier_tab.body
  )
)

ui <- dashboardPage(
  dashboardHeader(title = "easyCT"),
  sidebar,
  body
)
