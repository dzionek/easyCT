# UI part of classifier tab.

library(shinydashboard)
library(shinyFiles)

classifier_tab.menu <- menuItem(
  "Classifier", icon = icon("th"), tabName = "classifier"
)

classifier_tab.body <- tabItem(tabName = "classifier", fluidRow(
  box(
    title = "Classifier settings", status = "primary", solidHeader = TRUE,
    
    textInput(
      "model_name", placeholder = "cats_dogs",
      label = "Select a name for your model:"
    ),
  
    numericInput(
      "top_trim", value = 0, min = 0,
      label = "Select the number of pixels to be trimmed from the top:"
    ),
    numericInput(
      "top_trim", value = 0, min = 0,
      label = "Select the number of pixels to be trimmed from the bottom:"
    )
  ),
  
  box(
    title = "Classifier folders", status = "primary", solidHeader = TRUE,
    strong("Select a folder of the positive class:"),
    HTML("&nbsp;&nbsp;&nbsp;"),
    shinyDirButton(
      "positive_dir", "Select a folder", "Please select a folder"
    ),
    br(), br(),
    verbatimTextOutput("positive_dir_path"),
    br(),
    
    strong("Select a folder of the negative class:"),
    HTML("&nbsp;&nbsp;&nbsp;"),
    shinyDirButton(
      "negative_dir", "Select a folder", "Please select a folder"
    ),
    br(), br(),
    verbatimTextOutput("negative_dir_path"),
    br(),
    
    strong("Select a folder of the data to be classified:"),
    HTML("&nbsp;&nbsp;&nbsp;"),
    shinyDirButton(
      "classify_dir", "Select a folder", "Please select a folder"
    ),
    br(), br(),
    verbatimTextOutput("classify_dir_path"),
  )
))
