# UI part of save tab. Used to e

library(shinydashboard)

export_tab.menu <- menuItem("Import & Export", tabName = "export", icon = icon("file-download"))

export_tab.body <- tabItem(
  tabName = "export",
  h1("Import & Export"),
  p("This tab is used to import and export files between this application and
    your machine."),
  br(),
  
  h2("Time Tab"),
  fluidRow(
    tabBox(title = "Selected photos", side = "right",
           # tabPanel("Import", p("Currently not supported"))
           tabPanel("Export", p("Export here"))
    )
  ),

  h2("Classifier Tab"),
  fluidRow(
    tabBox(title = "Model", side = "right",
           tabPanel("Import", p("Import here")),
           tabPanel("Export", p("Export here"))
    ),
    
    tabBox(title = "Classification results", side = "right",
           # tabPanel("Import", p("Currently not supported"))
           tabPanel("Export", p("Export here"))
    )
  ),
)
