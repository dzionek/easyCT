# Back-end part of the application.

library(shiny)
library(fs)
library(dplyr)
library(exiftoolr)
library(xts)
library(data.table)
library(dygraphs)
library(lubridate)
library(tidyr)

source("server/utils.R")

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
  output$time_plot <- renderDygraph({
    if (!is.integer(input$directory)) {
      grouped_by_scale <- exif_dates() %>%
        mutate(date = floor_date(datetime, unit = input$bin_width)) %>%
        group_by(date) %>%
        summarize(count = sum(value))
      date_ts <- xts(x = grouped_by_scale$count, order.by = grouped_by_scale$date)
      dygraph(date_ts, main = "Histogram of photos", ylab = "Frequency") %>%
        dySeries(fillGraph = TRUE, stepPlot = TRUE, color = "red", 
                 label = "Frequency") %>%
        dyBarChart() %>%
        dyRangeSelector()
    }
  })
}
