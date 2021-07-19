# Back-end part of the application.

library(shiny)
library(fs)
library(dplyr)
library(exiftoolr)
library(data.table)
library(plotly)
library(lubridate)
library(tidyr)
library(stringr)


server <- function(input, output, session) {
  volumes <- c(Home = fs::path_home(), "R Installation" = R.home(), getVolumes()())
  
  # Time tab ========================================================
  shinyDirChoose(
    input, "directory", roots = volumes, session = session,
    restrictions = system.file(package = "base"), allowDirCreate = FALSE
  )
  
  # Folder selection
  output$directory_path <- renderPrint({
    if (is.integer(input$directory)) {
      cat("No directory has been selected.")
    } else {
      cat(parseDirPath(volumes, input$directory))
    }
  })
  
  # Reading date and times of photos.
  exif_dates <- reactive({
    image_files <- file.path(parseDirPath(volumes, input$directory))
    exif_data <- exif_read(image_files, recursive = TRUE)$DateTimeOriginal
    data.table(datetime = sort(ymd_hms(exif_data)))  %>%
      mutate(value = 1) 
  })
  
  # Histogram of the number of photos over time.
  output$time_plot <- renderPlotly({
    if (!is.integer(input$directory)) {
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
    if (!is.integer(input$directory)) {
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
      
      print(grouped_by_type)
      
      plot_ly(grouped_by_type, x=~type, y=~count, type = "bar") %>%
        layout(
          title = paste(str_to_title(input$activity_type), "activity histogram"),
          yaxis = list(title = paste(
            str_to_title(input$activity_function, " of frequency")
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
}
