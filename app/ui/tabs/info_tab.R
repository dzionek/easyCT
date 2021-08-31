# UI part of info tab. Contains description of the application.

library(shinydashboard)

info_tab.menu <- menuItem("Description", tabName = "info", icon = icon("info"))

info_tab.body <- tabItem(
  tabName = "info",
  h2("Description of the application"),
  p("The application is a web dashboard. You can navigate between different tabs
     using the menu on the left. Click the three horizontal lines in the top-left
    corner to expand/hide the menu."),

  h3("Time tab"),
  
  h4("Overview"),
  p("This tab is used for exploratory data analysis of your camera trap photos
    over time."),
  
  h4("How to use"),
  tags$ol(
    tags$li("Select a directory with your camera trap photos."),
    tags$li("Wait until the photos are loaded into the app. The app
            extracts the date of creation of your images. Once this is finished,
            you will see two plots."),
    tags$li('The first plot shows a histogram of your photos over their whole timeline.
             You can use the "Histogram settings" panel to select the right bin width
             for this graph.'),
    tags$li('The second plot is also a histogram but with regard to days of the week
            or hours of the day. To choose one of these two options, you can select
            type of activity in the "Activity plot settings". You can also choose the
            function that should be applied to your data. This can be either mean,
            median, or total number of photos in a given interval.'),
    tags$li('The last functionality is "Photo selector". You select the date and time
            range the photos should fall into. For example, you can get only those
            photos that were captured between 1 May 10:00 and 2 May 13:00. The result
            is shown inside a table with pagination and search functionality.')
  ),
  
  h3("Classifier tab"),
  h4("Overview"),
  p('You can use this tab to train your own models and classify your photos.
     This uses a single species classifier (binary classifier) distinguishing
    positive and negative class. For example, suppose you have images showing cats
    and dogs. If you want to build a classifier that will find cats, you can train
    a model with positive class "cats" and negative class "dogs".'),
  
  h4("How to use"),
  tags$ol(
    tags$li('Camera trap photos very often contain an info bar at the top or bottom
            of each picture. We would like to avoid a situation when a change in time
            or temperature on an info bar affect classification. To remove the info bar,
            you can type a number of pixels to be removed from top/bottom in the
            "General settings" box.'),
    tags$li('In the "Classifier settings" you are asked to select a directory
            of images you want to classify. This is the data set you did not manually
            tagged. You can also adjust the threshold of probability needed to
            classify positive.'),
    tags$li('Next, in "Model settings" you can select whether you want to create a new
             model or use an existing one.'),
    tags$ol(
      tags$li('If you choose to create a new model, you need to give a name for
              your model, give names and directories of your positive and negative
              label.'),
      tags$li('If you decide to use a pre-built model, you will see a list of all
              models saved at easyCT/models directory in the path you specified.
              So, if you want to use a model you got from your colleagues,
              you need to copy it to this directory. After selecting appropriate
              model, you can check if labels and name are correct'),
    ),
    
    tags$li(
      tags$b("This step is optional and used only if you selected to build
             a new model."),
      'Inside "Training the model" part you can click 
       "Train the classifier" button. After some time (estimated by the progress
       bar), the model will be saved in the directory',
      tags$pre("easyCT/models"),
       'You will see two versions
       of confusion matrix for this model, you can navigate between usual
       and proportion versions.'),
    
    tags$li('Below "Classifying images" header you can click a button to classify
             your images. After some time (predicted by the progress bar), the results
             will be saved in a directory of the form',
            tags$pre('easyCT/results/<date-and-time>'),
            'You will also see
             an interactive pie-chart with ratio of classification. You can also
             open the histogram part to see the distribution of probability.')
  ),
  
  h4("Implementation details"),
  tags$ol(
    tags$li(
      "When you train a model, the images of positive and negative class are randomly
      split into training and test sets in proportion 75% to 25%."
    ),
    tags$li(
      "The training set is used to train the model and the test set is used to
       evaluate it. So, the numbers you see on the confusion matrix correspond
       to the test set."
    ),
    tags$li(
      "Confusion matrix in proportion format shows the percent of images in relation
      to their actual class."
    )
  ),

  h3("FAQ"),
  tags$ul(
    tags$li(
      tags$b("I use Docker Desktop and can't find my photos. What should I do?"),
      br(),
      "You need to check the README file with documentation. Make sure you allowed
      Docker Desktop to access your path in File Sharing settings. Also, check if you
      correctly inputted the path while executing ",
      tags$b("docker run"),
      " command. That is,
      you put your path instead of square brackets and you didn't modify ",
      tags$b(":/root/photos"),
      " after your path. It might be useful to read an example of running the app.
      Click Github in the menu to go to the documentation."
    ),
    
    tags$li(
      tags$b("All/some of my photos are missing after loading in the Time tab."),
      br(),
      "The Time tab reads Exif data of your photos and extracts the ",
      tags$i("DateTimeOriginal"),
      " tag. If it is missing for some reason, a given photo can't be loaded."
    ),
    
    tags$li(
      tags$b("What should be my probability threshold for the classifier?"),
      br(),
      "The probability threshold is up to you. You can empirically check what is the
      best for your needs. Note that the threshold doesn't affect the training and
      it is only used for classification. You can change the threshold
      in the CSV file generated after the classification. This can be easily done
      using various software, e.g. Microsoft Excel."
    ),
    
    tags$li(
      tags$b("What is the confusion matrix?"),
      br(),
      "The confusion matrix is a table used to compare the actual class (provided by
      you in directories of positive and negative class) with the predicted class
      (what the model thinks). You can think of it in the following way:",
      tags$table(class = "table-bordered table-dark",
        tags$tr(
          tags$td(class = "bg-success", "True Positive"),
          tags$td(class = "bg-danger", "False Positive"),
        ),
        tags$tr(
          tags$td(class = "bg-danger", "False Negative"),
          tags$td(class = "bg-success", "True Negative"),
        )
      )
    )
  )
  
)
