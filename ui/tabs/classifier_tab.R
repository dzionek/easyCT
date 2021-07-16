library(shinydashboard)

classifier_tab.menu <- menuItem(
  "Classifier", icon = icon("th"), tabName = "classifier"
)

classifier_tab.body <- tabItem(
  tabName = "classifier",
  h2("Classification")
)
