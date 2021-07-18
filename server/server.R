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

dyBarChart <- function(dygraph) {
  dyPlotter(dygraph = dygraph,
            name = "BarChart",
            path = system.file("plotters/barchart.js",
                               package = "dygraphs"))
}

server <- function(input, output, session) {
  volumes <- c(Home = fs::path_home(), "R Installation" = R.home(), getVolumes()())
  
  shinyDirChoose(
    input, "directory", roots = volumes, session = session,
    restrictions = system.file(package = "base"), allowDirCreate = FALSE
  )
  
  output$directory_path <- renderPrint({
    if (is.integer(input$directory)) {
      cat("No directory has been selected.")
    } else {
      cat(parseDirPath(volumes, input$directory))
    }
  })
  
  exif_dates <- reactive({
    image_files <- file.path(parseDirPath(volumes, input$directory))
    exif_data <- exif_read(image_files, recursive = TRUE)$DateTimeOriginal
    data.table(datetime = sort(ymd_hms(exif_data)))  %>%
      mutate(value = 1) 
  })
  
  output$time_plot <- renderDygraph({
    if (!is.integer(input$directory)) {
      group_by_scale <- function(scale) {
        switch(
          scale,
          "monthly" = exif_dates() %>%
            mutate(date = as.Date(format(datetime, "%Y-%m-01"))),
          "daily" = exif_dates() %>%
            mutate(date = date(datetime)),
          "hourly" = exif_dates() %>%
            mutate(date = ymd_hms(format(datetime, "%Y-%m-%d %H-00-00")))
        ) %>%
          group_by(date) %>%
          summarize(count = sum(value))
      }
      
      grouped_by_scale <- group_by_scale(input$bin_width)
      date_ts <- xts(x = grouped_by_scale$count, order.by = grouped_by_scale$date)
      dygraph(date_ts, main = "Histogram of photos", ylab = "Frequency") %>%
        dySeries(fillGraph = TRUE, stepPlot = TRUE, color = "red", 
                 label = "Frequency") %>%
        dyBarChart() %>%
        dyRangeSelector()
    }
  })
}
