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
      "top_trim", value = 0, min = 0, step = 1,
      label = "Select the number of pixels to be trimmed from the top:"
    ),
    numericInput(
      "bottom_trim", value = 0, min = 0, step = 1,
      label = "Select the number of pixels to be trimmed from the bottom:"
    ),
    
    numericInput(
      "threshold", value = 0.5, min = 0, max = 1, step = 0.01,
      label = "Select the threshold for classifying positive (0 ≤ x ≤ 1):"
    ),
  ),
  
  box(
    title = "Classifier directories", status = "primary", solidHeader = TRUE,
    strong("Select a directory of the positive class:"),
    HTML("&nbsp;&nbsp;&nbsp;"),
    shinyDirButton(
      "positive_dir", "Select a directory",
      "Please select a directory for the positive class."
    ),
    br(), br(),
    verbatimTextOutput("positive_dir_path"),
    br(),
    
    strong("Select a directory of the negative class:"),
    HTML("&nbsp;&nbsp;&nbsp;"),
    shinyDirButton(
      "negative_dir", "Select a directory",
      "Please select a directory for the negative class."
    ),
    br(), br(),
    verbatimTextOutput("negative_dir_path"),
    br(),
    
    strong("Select a directory of images to be classified:"),
    HTML("&nbsp;&nbsp;&nbsp;"),
    shinyDirButton(
      "classify_dir", "Select a directory",
      "Please select a directory of images to be classified."
    ),
    br(), br(),
    verbatimTextOutput("classify_dir_path"),
  ),
  
  # Training
  box(status = "danger", width = 12,
      column(12, align="center", h2("Training the model"))
  ),
  
  box(status = "danger", title = "Model evaluation",
      verbatimTextOutput("model_evaluation")),
  box(status = "danger", title = "Activate",
    "The following app will run an Inceptionv v3 based classifier developed
    in Li et al.",
    actionButton("train_button", "Train the classifier"),
    verbatimTextOutput("test")
  ),
  
  box(status = "warning", width = 12,
      column(12, align="center", h2("Classifying images"))
  ),
  
  box(status = "success", width = 12,
      column(12, align="center", h2("Applying the classification"))
  )
))
