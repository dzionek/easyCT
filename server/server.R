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

# Classifier files
source("classifier/model.R", local = TRUE)
source("classifier/generate_features.R", local = TRUE)
source("classifier/apply_model.R", local = TRUE)

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
    !is.integer(input$positive_dir) && !is.integer(input$negative_dir) &&
      !is.integer(input$classify_dir) && length(input$model_name) > 0
  })
  
  # Training the classifier
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
      box(status = "danger", title = "Model path",
          "The model was successfuly saved at:",
          br(),
          pre(paste0(getwd(), "/_cache/models/", input$model_name))
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
}
