# Entry point for the application

# To restart R session before running use:
# .rs.restartR() 

library(shiny)

source("ui/ui.R")
source("server/server.R")

shinyApp(ui = ui, server = server)
