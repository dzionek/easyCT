####
## Generate classifier from files of positive and negative class.
##
## This script will extract inception-v3 features (2048 values)
## for image from two directories (on the 'positive' class, the other
## the 'negative' class (e.g. cat vs dog)). It will then build
## a classifier to discriminate those classes and save it.
##
###

library(tensorflow)  # requires also the Python Tensorflow
library(keras)
library(data.table)
library(zeallot)

source("classifier/generate_features.R")

#' Get input and output matrices from the supervised set.
#' 
#' @param pos_directory_path The path to the positive set directory.
#' @param neg_directory_path The path to the negative set directory.
#' @param top_trim The number of pixels that should be trimmed from the top.
#' @param bottom_trim The number of pixels that should be trimmed from the bottom.
#' @return The input and output based on images.
get_input_output <- function(pos_directory_path, neg_directory_path,
                             top_trim, bottom_trim) {
  inputs_pos <- get_features("positive class", pos_directory_path, top_trim, bottom_trim)
  inputs_neg <- get_features("negative class", neg_directory_path, top_trim, bottom_trim)
  
  # Save inputs
  # fwrite(inputs_pos, "inputs_pos.csv")
  # fwrite(inputs_neg, "inputs_neg.csv") 
  
  # Get outputs matched to inputs
  output_pos = rep(1, nrow(inputs_pos))
  output_neg = rep(0, nrow(inputs_neg))
  
  # Return single variables for both
  list(
    "inputs" = rbind(inputs_pos, inputs_neg),
    "outputs" = c(output_pos, output_neg)
  )
}

#' Get train and tests sets from inputs and outputs.
#' 
#' @param inputs The featrues of images.
#' @param outputs The classifications of images.
#' @return The train and test sets in a list.
get_train_test_sets <- function(inputs, outputs) {
  # Set seed for reproducibility
  set.seed(101) 
  
  # Get indices to split outputs into training (75%) and test (25%)
  sample <- caTools::sample.split(outputs, SplitRatio = .75)
  
  # Use these to partition inputs and outputs
  list(
    "train_x" = as.matrix(subset(inputs, sample == TRUE)),
    "test_x" = as.matrix(subset(inputs, sample == FALSE)),
    "train_y" = as.matrix(outputs[sample == TRUE]),
    "test_y" = as.matrix(outputs[sample == FALSE])
  )
}

TrainingCallback <- R6::R6Class("TrainingCallback",
  inherit = KerasCallback,
  
  private = list(
    .current_epoch = NA,
    .progress = NULL
  ),
  
  public = list(
    initialize = function() {
      private$.current_epoch = 0
      private$.progress = shiny::Progress$new()
    },
    
    on_train_begin = function(logs = list()) {
      private$.progress$set(message = "Training model:", value = 0)
    },
    
    on_train_end = function(logs = list()) {
      private$.progress$close()
    },
    
    on_epoch_end = function(batch, logs = list()) {
     private$.current_epoch <- private$.current_epoch + 1
     private$.progress$inc(
       1/200,
       detail = paste0("Epoch: ", private$.current_epoch, "/200")
     )
   }
  )
)

#' Get the classification model.
#' 
#' @param train_x The training set image features.
#' @param test_x The test set image features.
#' @param train_y The train set image classification.
#' @param test_y The test set image classification.
#' @return The classification model.
get_model <- function(train_x, test_x, train_y, test_y) {
  # Very simple classification MLP
  #classify_model <- keras_model_sequential()
  
  # 2048 inputs into 100 hidden units
  #classify_model %>% 
  #  layer_dense(units = 100, activation = 'relu', input_shape = c(2048)) %>%
  #  layer_dense(units = 1, activation = 'sigmoid')
  
  # Alternative simple classification MLP with dropout
  classify_model <- keras_model_sequential()
  # 2048 inputs into 784 hidden units (with dropout to help generalisation)
  classify_model %>%
    layer_dense(units = 784, input_shape = c(2048)) %>% # Size of layer
    layer_dropout(rate=0.2) %>%                 # Apply dropout to nodes in layer
    layer_activation(activation = 'relu') %>% # Activation of nodes in layer
    layer_dense(units = 1, activation = 'sigmoid') # final layer is is single softmax output
  
  #compiling the defined model with metric = accuracy and optimiser as adam.
  classify_model %>% compile(
    optimizer = 'rmsprop',
    loss = 'binary_crossentropy',
    metrics = c('accuracy')
  )
  
  # Fit model
  classify_model %>%
    fit(train_x, train_y, epochs = 200, batch_size = 256,
        callbacks = list(TrainingCallback$new())
    )
  classify_model
}

#' Check prediction against the test set. Get evaluation metrics of the model.
#' 
#' @param classify_model The classification model trained on the training set.
#' @param test_x The test set image features.
#' @param test_y The test set image classification.
#' @return The list with loss, accuracy, absolute and proportion confusion matrix.
get_model_evaluations <- function(classify_model, test_x, test_y) {
  # Get metrics
  c(loss, accuracy) %<-% (classify_model %>%
                            evaluate(test_x, test_y, batch_size = 128))
  
  # Get confusion matrix
  prob_y <- classify_model %>% predict(test_x, batch_size = 128)
  pred_y <- round(prob_y)
  confusion_matrix <- table(pred_y, test_y)
  proportion <- prop.table(confusion_matrix, 2)
  
  list(
    "loss" = round(loss, 3),
    "accuracy" = round(accuracy, 3),
    "confusion_matrix" = confusion_matrix,
    "proportion" = proportion
  )
} 

#' Save the model to a file.
#' 
#' @param classify_model The model created in the process
#' @param model_name The name used for saving the file.
save_model <- function(classify_model, model_name) {
  classify_model %>% save_model_tf(paste0("_cache/models/", model_name))
}

#' Entry point for the entire process of trimming images, training model and
#' saving it to a file. Give the evaluation metrics of the model.
#' 
#' @param top_trim The number of pixels that should be trimmed from the top.
#' @param bottom_trim The number of pixels that should be trimmed from the bottom.
#' @param pos_directory_path The path to the positive set directory.
#' @param neg_directory_path The path to the positive set directory.
#' @param model_name The name of the model that will be the saved file name.
#' @return The list with loss, accuracy, absolute and proportion confusion matrix.
trim_train_save <- function(top_trim, bottom_trim, pos_directory_path,
                            neg_directory_path, model_name) {
  
  c(inputs, outputs) %<-% get_input_output(pos_directory_path, neg_directory_path,
                                           top_trim, bottom_trim)
  
  c(train_x, test_x, train_y, test_y) %<-% get_train_test_sets(inputs, outputs)
  
  model <- get_model(train_x, test_x, train_y, test_y)
  save_model(model, model_name)
  
  get_model_evaluations(model, test_x, test_y)
}
