# Front-end part of the application

library(shiny)
library(shinydashboard)
library(shinyFiles)

source("ui/tabs/time_tab.R")
source("ui/tabs/classifier_tab.R")
source("ui/tabs/info_tab.R")

sidebar <- dashboardSidebar(
  sidebarMenu(
    h4("Select a folder with photos", align = "center"),
    fluidRow(column(
      12, align = "center",
      shinyDirButton("directory", "Folder select", "Please select a folder")
    )),
    hr(),
    
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
  body
)
