# Front-end part of the application

library(shiny)
library(shinydashboard)
library(shinyFiles)

source("ui/tabs/time_tab.R")
source("ui/tabs/classifier_tab.R")
source("ui/tabs/info_tab.R")

sidebar <- dashboardSidebar(
  sidebarMenu(
    info_tab.menu,
    time_tab.menu,
    classifier_tab.menu,
    menuItem("GitHub", icon = icon("github"),
             href = "https://github.com/dzionek/easyCT")
  )
)

body <- dashboardBody(
  tabItems(
    time_tab.body,
    classifier_tab.body,
    info_tab.body
  )
)

ui <- dashboardPage(
  dashboardHeader(title = "easyCT"),
  sidebar,
  body,
  skin = "purple"
)
