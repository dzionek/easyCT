# Utility functions used inside tabs.
library(dygraphs)

#' Make a bar chart using dygraph.
#'
#' @param dygraph A dygraph on which the bar chart will be based.
#' @return The bar chart.
dyBarChart <- function(dygraph) {
  dyPlotter(dygraph = dygraph,
            name = "BarChart",
            path = system.file("plotters/barchart.js",
                               package = "dygraphs"))
}