# UI part of classifier tab.

library(shinydashboard)
library(shinyFiles)

classifier_tab.menu <- menuItem(
  "Classifier", icon = icon("th"), tabName = "classifier"
)

classifier_tab.body <- tabItem(tabName = "classifier", fluidRow(
  column(6,
     box(title = "General settings", status = "primary", solidHeader = TRUE,
       width = 12,
       
       numericInput(
         "top_trim", value = 0, min = 0, step = 1,
         label = "Select the number of pixels to be trimmed from the top:"
       ),
       numericInput(
         "bottom_trim", value = 0, min = 0, step = 1,
         label = "Select the number of pixels to be trimmed from the bottom:"
       ),
     ),
     
     box(title = "Classifier settings", status = "primary", solidHeader = TRUE,
       width = 12,
       
       numericInput(
         "threshold", value = 0.5, min = 0, max = 1, step = 0.01,
         label = "Select the threshold for classifying positive (0 ≤ x ≤ 1):"
       ),
       
       h3("Images to classify"),
       strong("Select a directory of images to be classified:"),
       HTML("&nbsp;&nbsp;&nbsp;"),
       shinyDirButton(
         "classify_dir", "Select a directory",
         "Please select a directory of images to be classified."
       ),
       br(), br(),
       verbatimTextOutput("classify_dir_path")
     ),
  ),
  
  column(6,
    box(title = "Model settings", status = "primary", solidHeader = TRUE,
      width = 12,
        
      selectInput(
        "new_model_selection", "Do you want to build a new model?",
        choices = list("Yes, create a new model." = TRUE,
        "No, I want to use a model from _cache/models." = FALSE)
      )
    ),
    
    uiOutput("model_settings2")
  ),
  
  # Training
  uiOutput("training"),
  
  # Classifying
  box(status = "warning", width = 12,
      column(12, align="center", h2("Classifying images"))
  ),
  
  tabBox(title = "Classification results", side = "right",
         tabPanel("Ratio", plotlyOutput("classification_ratio")),
         tabPanel("Histogram", plotlyOutput("classification_histogram"))
  ),
  
  box(status = "warning", title = "Classify",
    "The button below will classify the images in the directory you selected",
    br(),
    br(),
    actionButton("classify_button", "Classify images")  
  ),
  
  uiOutput("classification_output"),
  
  box(status = "success", width = 12,
      column(12, align="center", h2("Applying the classification"))
  )
))
