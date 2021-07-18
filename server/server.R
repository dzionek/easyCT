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

server <- function(input, output, session) {
  volumes <- c(Home = fs::path_home(), "R Installation" = R.home(), getVolumes()())
  
  shinyDirChoose(
    input, "directory", roots = volumes, session = session,
    restrictions = system.file(package = "base"), allowDirCreate = FALSE
  )
  
  output$directorypath <- renderPrint({
    if (is.integer(input$directory)) {
      cat("No directory has been selected.")
    } else {
      parseDirPath(volumes, input$directory)
    }
  })
  
  output$time_plot <- renderDygraph({
    if (!is.integer(input$directory)) {
      image_files <- file.path(parseDirPath(volumes, input$directory))
      print(image_files)
      exif_data <- exif_read(image_files, recursive = TRUE)$DateTimeOriginal
      exif_dates <- sort(ymd_hms(exif_data))
      
      group_by_scale <- function(scale) {
        switch(
          scale,
          "daily" = data.table(datetime = exif_dates) %>%
            mutate(value = 1, date = date(datetime)) %>%
            complete(date = full_seq(date, period = 1), fill = list(value = 0)) %>%
            group_by(date) %>%
            summarize(count = sum(value))
        )
      }
      
      grouped_by_scale <- group_by_scale("daily")
      date_ts <- xts(x = grouped_by_scale$count, order.by = grouped_by_scale$date)
      dygraph(date_ts, main = "Histogram of photos") %>%
        dySeries(fillGraph = TRUE, stepPlot = TRUE, color = "red") %>%
        dyRangeSelector()
    }
  })
}
