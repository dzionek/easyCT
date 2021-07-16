# Entry point for the application

library(shiny)

source("ui.R")
source("server.R")

shinyApp(ui = ui, server = server)
