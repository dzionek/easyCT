# Back-end part of the application.

library(shiny)
library(fs)
library(dplyr)
library(exiftoolr)
library(plotly)
library(lubridate)
library(tidyr)
library(stringr)
library(DT)
library(yardstick)
library(ggplot2)
library(purrr)

# Classifier files
source("classifier/model.R", local = TRUE)
source("classifier/generate_features.R", local = TRUE)
source("classifier/apply_model.R", local = TRUE)

MODELS_PATH <- paste0(getwd(), "/_cache/models/")
RESULTS_PATH <- paste0(getwd(), "/_cache/results/")
MODEL_METADATA_FILE <- "meta.csv"

POSITIVE_COLOR <- "#00CC96"
NEGATIVE_COLOR <- "#EF553B"

server <- function(input, output, session) {
  volumes <- c(Home = fs::path_home(), "R Installation" = R.home(), getVolumes()())
  
  # Time tab ========================================================
  
  # Reading date and times of photos.
  exif_dates <- reactive({
    image_files <- file.path(parseDirPath(volumes, input$directory))
    exif_data <- exif_full <- exif_read(
      image_files, recursive = TRUE, tags = c("SourceFile", "DateTimeOriginal")
    ) %>% 
      rename(datetime = DateTimeOriginal) %>%
      mutate(datetime = ymd_hms(datetime), value = 1) %>%
      dplyr::arrange(datetime)
  })
  
  is_folder_selected <- reactive({ !is.integer(input$directory) })
  
  shinyDirChoose(
    input, "directory", roots = volumes, session = session,
    restrictions = system.file(package = "base"), allowDirCreate = FALSE
  )
  
  # Folder path
  output$directory_path <- renderPrint({
    if (is_folder_selected()) {
      cat(parseDirPath(volumes, input$directory))
    } else {
      cat("No directory has been selected.")
    }
  })
  
  # Histogram of the number of photos over time.
  output$time_plot <- renderPlotly({
    if (is_folder_selected()) {
      grouped_by_type <- exif_dates() %>%
        mutate(date = floor_date(datetime, unit = input$bin_width)) %>%
        group_by(date) %>%
        summarize(count = sum(value))
      
      plot_ly(grouped_by_type, x=~date, y=~count, type = "bar") %>%
        layout(title = "Histogram of photos", yaxis = list(title = "Frequency"),
               xaxis = list(title = "Time"), hovermode = "x unified")
    }
  })
  
  # Activity plot
  output$activity_plot <- renderPlotly({
    if (is_folder_selected()) {
      grouped_by_type <- exif_dates() %>%
        mutate(date = floor_date(
          datetime,
          unit = switch(input$activity_type,
            "weekly" = "day", "daily" = "hour"
          ))) %>%
        group_by(date) %>%
        summarize(count = sum(value)) %>%
        mutate(type = switch(input$activity_type,
          "weekly" = wday(date, label = T, week_start = 1, abbr = F),
          "daily" = as.POSIXct(str_pad(hour(date), 2, pad = "0"), format = "%H", tz= "UTC")
        )) %>%
        group_by(type) %>%
        summarize(count = eval(parse(text = paste0(input$activity_function, "(count)"))))
      
      plot_ly(grouped_by_type, x=~type, y=~count, type = "bar") %>%
        layout(
          title = paste(str_to_title(input$activity_type), "activity histogram"),
          yaxis = list(title = paste(
            str_to_title(input$activity_function, "of frequency")
            )),
          xaxis = list(title = switch(input$activity_type,
              "weekly" = "Days of the week", "daily" = "Hours of the day",  
            ),
            'tickformat' = '%H:00'
          ),
          hovermode = "x unified"
        )
    }
  })
  
  # Datetime selection
  output$datetime_selection <- renderUI({
    start <- end <- mini <- maxi <- NULL
    
    if (is_folder_selected()) {
      start <- mini <- floor_date(
        head((exif_dates() %>% select(datetime))[[1]], n = 1),
        unit = "day"
      )
      end <- maxi <- floor_date(
        tail((exif_dates() %>% select(datetime))[[1]], n = 1),
        unit = "day"
      )
    }
    
    box(
      title = "Photo selector", status = "danger",
      dateRangeInput(
        "selection_days", label = "Choose date range to filter photos:",
        start = start, end = end, min = mini, max = maxi, weekstart = 1
      ),
      fluidRow(
        column(7,
               timeInput(
                 "selection_time1", "Enter time for the first date:",
                 minute.steps = 10,
                 value = strptime("00:00:00", "%T")
               )
        ),
        column(5,
               timeInput(
                 "selection_time2", "Enter time for the second date:",
                 minute.steps = 10,
                 value = strptime("00:00:00", "%T")
               )
        )
      )
    )
  })
  
  # Files selected
  output$selected_photos <- DT::renderDataTable({
    if (is_folder_selected()) {
      first_date <- ymd_hms(paste(
        input$selection_days[[1]],
        format(input$selection_time1, "%H:%M:%S")
      ))
      second_date <- ymd_hms(paste(
        input$selection_days[[2]],
        format(input$selection_time2, "%H:%M:%S")
      ))
      
      selected <- exif_dates() %>%
        filter(between(datetime, first_date, second_date)) %>%
        select(!value)
      
      selected
    }
  })
  
  # Classify tab ========================================================
  
  # Directory selections
  shinyDirChoose(
    input, "positive_dir", roots = volumes, session = session,
    restrictions = system.file(package = "base"), allowDirCreate = FALSE
  )
  output$positive_dir_path <- renderPrint({
    if (!is.integer(input$positive_dir)) {
      cat(parseDirPath(volumes, input$positive_dir))
    } else {
      cat("No directory has been selected.")
    }
  })
  
  shinyDirChoose(
    input, "negative_dir", roots = volumes, session = session,
    restrictions = system.file(package = "base"), allowDirCreate = FALSE
  )
  output$negative_dir_path <- renderPrint({
    if (!is.integer(input$negative_dir)) {
      cat(parseDirPath(volumes, input$negative_dir))
    } else {
      cat("No directory has been selected.")
    }
  })
  
  shinyDirChoose(
    input, "classify_dir", roots = volumes, session = session,
    restrictions = system.file(package = "base"), allowDirCreate = FALSE
  )
  output$classify_dir_path <- renderPrint({
    if (!is.integer(input$classify_dir)) {
      cat(parseDirPath(volumes, input$classify_dir))
    } else {
      cat("No directory has been selected.")
    }
  })
  
  classifier_inputs_ready <- reactive({
    !is.integer(input$classify_dir) && is.character(input$model_name) &&
    (input$model_name != "") && (
      (!is.integer(input$positive_dir) && !is.integer(input$negative_dir))
      || !as.logical(input$new_model_selection)
    )
  })
  
  # Load labels from meta.csv if selected an existing model.
  loaded_labels <- reactive({
    if (!as.logical(input$new_model_selection) && is.character(input$model_name)
        && input$model_name != "") {
      tryCatch(
        expr = {
          fread(file.path(MODELS_PATH, input$model_name, MODEL_METADATA_FILE))
        },
        error = function(cond) {
          return(NULL)
        }
      )
    } else {
      NULL
    }
  })
  
  output$labels <- renderUI({
    existing_labels <- loaded_labels()
    existing_pos_label <- ifelse(is.data.table(existing_labels),
                                  existing_labels$positive_label, "")
    existing_neg_label <- ifelse(is.data.table(existing_labels),
                                 existing_labels$negative_label, "")
    tagList(
      textInput(
        "positive_label", label = "Choose a label for the positive class:",
        placeholder = "cats", value = existing_pos_label
      ),
      
      textInput(
        "negative_label", label = "Choose a label for the negative class:",
        placeholder = "dogs", value = existing_neg_label
      ),
    )
  })
  
  output$model_settings2 <- renderUI({
    if (input$new_model_selection) {
      # We want to create a new model.
      box(title = "New model settings", status = "primary", solidHeader = TRUE,
          width = 12,
          textInput(
            "model_name", placeholder = "cats_dogs",
            label = "Select a name for your model:"
          ),
          
          h3("Positive class"),
          textInput(
            "positive_label", label = "Choose a label for the positive class:",
            placeholder = "cats"
          ),
          strong("Select a directory of the positive class:"),
          HTML("&nbsp;&nbsp;&nbsp;"),
          shinyDirButton(
            "positive_dir", "Select a directory",
            "Please select a directory for the positive class."
          ),
          br(), br(),
          verbatimTextOutput("positive_dir_path"),
          
          h3("Negative class"),
          textInput(
            "negative_label", label = "Choose a label for the negative class:",
            placeholder = "dogs"
          ),
          strong("Select a directory of the negative class:"),
          HTML("&nbsp;&nbsp;&nbsp;"),
          shinyDirButton(
            "negative_dir", "Select a directory",
            "Please select a directory for the negative class."
          ),
          br(), br(),
          verbatimTextOutput("negative_dir_path"),
      )
      
    } else {
      # We want to use an existing model from _cache.
      box(title = "Prebuilt model settings", status = "primary", solidHeader = TRUE,
        width = 12,
        
        selectInput(
          "model_name", "Choose your model from the _cache/models directory:",
          choices = list.dirs(MODELS_PATH, recursive = FALSE, full.names = FALSE)
        ),
        
        uiOutput("labels"),
      )
    }
  })
  
  # Training the classifier
  output$training <- renderUI({
    if (input$new_model_selection) {
      tagList(
        box(status = "danger", width = 12,
            column(12, align="center", h2("Training the model"))
        ),
        
        tabBox(title = "Confusion matrix", side = "right",
               tabPanel("Number of photos", plotOutput("confusion_matrix")),
               tabPanel("Proportion", plotOutput("proportion_matrix"))
        ),
        
        box(status = "danger", title = "Train",
            "The following app will run an Inceptionv v3 based classifier developed
      in Li et al.",
      br(),
      br(),
      actionButton("train_button", "Train the classifier"),
        ),
      
      uiOutput("train_result"),
      valueBoxOutput("accuracy_box", width = 3),
      valueBoxOutput("loss_box", width = 3),
      ) 
    }
  })
  
  training_results <- eventReactive(input$train_button, {
    if (classifier_inputs_ready()) {
      trim_train_save(
        as.numeric(input$top_trim), as.numeric(input$bottom_trim),
        parseDirPath(volumes, input$positive_dir),
        parseDirPath(volumes, input$negative_dir),
        input$model_name
      )
    }
  })
  
  output$confusion_matrix <- renderPlot({
    confusion_matrix <- training_results()$confusion_matrix
    autoplot(yardstick::conf_mat(confusion_matrix), type = "heatmap") +
      scale_fill_gradient(low="#fee8c8",high = "#e34a33") +
      theme(legend.position = "right", plot.title = element_text(hjust = 0.5)) +
      labs(title = "Confusion matrix", x = "Actual", y = "Predicted")
  })
  
  output$proportion_matrix <- renderPlot({
    proportion_matrix <- training_results()$proportion
    autoplot(yardstick::conf_mat(proportion_matrix), type = "heatmap") +
      scale_fill_gradient(low="#fee8c8",high = "#e34a33") +
      theme(legend.position = "right", plot.title = element_text(hjust = 0.5)) +
      labs(title = "Confusion matrix (proportion)", x = "Actual", y = "Predicted")
  })
  
  output$train_result <- renderUI({
    if (is.numeric(training_results()$accuracy)) {
      model_dir <- paste0(MODELS_PATH, input$model_name)
      fwrite(
        list("positive_label" = input$positive_label,
             "negative_label" = input$negative_label),
        file = paste0(model_dir, "/", MODEL_METADATA_FILE)
      )
      
      box(status = "danger", title = "Model path",
          "The model was successfully saved at:",
          br(),
          pre(model_dir)
      ) 
    }
  })
  
  output$accuracy_box <- renderValueBox({
    valueBox(
      training_results()$accuracy, "Accuracy", color = "red",
      icon = icon("crosshairs", lib = "font-awesome")
    )
  })
  output$loss_box <- renderValueBox({
    valueBox(
      training_results()$loss, "Loss", color = "red",
      icon("level-down-alt", lib = "font-awesome")
    )
  })
  
  # Classifying images
  classification_results <- eventReactive(input$classify_button, {
    if (classifier_inputs_ready()) {
      time <- format(Sys.time(), "%d%h%Y_%H-%M")
      dir.create(paste0(RESULTS_PATH, time), recursive = TRUE)
      save_dir <- paste0(RESULTS_PATH, time)
      
      get_features(
        "images to classify", parseDirPath(volumes, input$classify_dir),
        input$top_trim, input$bottom_trim, save = TRUE, save_dir = save_dir
      )
      
      apply_model(
        source_dir = save_dir, model_name = paste0(MODELS_PATH, input$model_name),
        threshold = input$threshold, pos_label = input$positive_label, 
        neg_label = input$negative_label
      )
      
      classified_path <- paste0(save_dir, "/_results_v3.csv")
      list(
        "path" = classified_path,
        "table" = fread(classified_path)
      )
    }
  })
  
  output$classification_ratio <- renderPlotly ({
    num_positive <- sum(classification_results()$table$class == input$positive_label)
    num_negative <- sum(classification_results()$table$class == input$negative_label)
    fig <- plot_ly(
      labels = c(input$positive_label, input$negative_label),
      values = c(num_positive, num_negative), type = 'pie',
      textposition = 'inside', textinfo = 'label+percent', showlegend = TRUE,
      marker = list(colors=c(POSITIVE_COLOR, NEGATIVE_COLOR))
    )
    
    fig %>% layout(title = "Classified images",
                   xaxis = list(showgrid = FALSE, zeroline = FALSE, showticklabels = FALSE),
                   yaxis = list(showgrid = FALSE, zeroline = FALSE, showticklabels = FALSE),
                   legend=list(title=list(text='<b> Label </b>')))
  })
  
  output$classification_histogram <- renderPlotly ({
    probabilities <- round(classification_results()$table$p, 2)
    
    positives <- keep(probabilities, function(x) x >= input$threshold)
    negatives <- keep(probabilities, function(x) x < input$threshold)
      
    fig <- plotly_empty() 
    
    if (length(positives) > 0) {
      fig <- fig %>% add_histogram(
        x = positives,
        name = input$positive_label, marker = list(color=POSITIVE_COLOR)
      ) 
    }
    
    if (length(negatives) > 0) {
      fig <- fig %>% add_histogram(
        x = negatives, 
        name = input$negative_label, marker = list(color=NEGATIVE_COLOR)
      ) 
    }

    fig %>% layout(barmode = "overlay", title = "Classification probability histogram",
              yaxis = list(title = "Frequency"),
              xaxis = list(title = "Probability"),
              hovermode = "x unified", legend=list(title=list(text="<b> Label </b>")))
  })
  
  output$classification_output <- renderUI({
    if (is.data.table(classification_results()$table)) {
      box(status = "warning", title = "Classification output",
          "The classification was successfully saved at:",
          br(),
          pre(classification_results()$path)
      ) 
    }
  })
}
