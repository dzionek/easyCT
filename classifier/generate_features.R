####
## Generate features from images.
##
## This script will get inception-v3 features (2048 values)
## from images from a provided directory and optionally save them.
##
###

library(tensorflow)  # Tensor flow also the Python Tensorflow
library(keras)
library(reticulate)
library(data.table)
library(lubridate)
library(shiny)

source_python("classifier/crop_generator.py")

# Inception model without fully connected top layer, with max pooling
# This is our 'feature generator'.
# NB: I've occasionally had problems with loading this inception-v3 model
#  possibly due to conflicting h5py version in python. Re-installing from above
#  seems to fix it for the moment
inception_v3_feature_model <- application_inception_v3(
  include_top = FALSE,
  weights = "imagenet",
  input_tensor = NULL,
  input_shape = NULL,
  pooling = "max"
)


#' Given an image path, extract features for that image.
#' 
#' @param img_path The path of an individual image.
#' @param top_trim The number of pixels that should be trimmed from the top.
#' @param bottom_trim The number of pixels that should be trimmed from the bottom.
#' @return The features of the image.
#' 
#' @note The input image format for this model is different than for the VGG16
#'       and ResNet models (299x299 instead of 224x224).
extract_features_inception_v3 <- function(img_path, top_trim, bottom_trim) {
  # Load image as colour and resize
  img <- image_load(
    img_path,
    grayscale = FALSE,
    #target_size = c(299, 299),
    #interpolation = "nearest"
  )
  
  # Trim the info bar
  img_crop <- defined_crop(img, top_trim = top_trim, bottom_trim = bottom_trim,
                           min_width = 50, min_height = 50)
  
  # Resize the image to 299 x 299
  resized_img <- image_array_resize(img_crop, width=299, height=299)
  
  # Reshape for preprocess function
  resized_img <- array_reshape(resized_img, c(1, dim(resized_img)))
  vals <- inception_v3_preprocess_input(resized_img)
  
  # pass image into inception model and get output features
  # e.g. predicting to near the final layers and getting those values
  feats <- inception_v3_feature_model %>% predict(vals)
  feats
}

#' Get features from a directory of images. Optionally save them to a file.
#' 
#' @param message The message to be displayed next to the progress bar.
#' @param directory_path The path to the base directory of images.
#' @param top_trim The number of pixels that should be trimmed from the top.
#' @param bottom_trim The number of pixels that should be trimmed from the bottom.
#' @param save True if the features should be saved, false otherwise.
#' @param save_dir The optional parameter used when you want to save the features.
#' @return The data frame of features associated with the given images.
get_features <- function(message, directory_path, top_trim, bottom_trim,
                         save = FALSE, save_dir = NULL) {
  files <- list.files(
    directory_path, pattern = "*.JPG|*.jpg", full.names = TRUE, recursive = TRUE
  )
  feature_list <- list()
  
  # Progress bar
  number_of_files <- length(files)
  progress <- shiny::Progress$new()
  on.exit(progress$close())
  progress$set(message = paste0("Processing ", message, ":"), value = 0)
  
  ptm <- proc.time()
  for (i in seq_along(files)) {
    f <- files[i]
    full_time <- (proc.time() - ptm)[[3]]  # elapsed time
    est_time <- round(full_time / i * (number_of_files - i)) %>%
      duration("seconds")
    
    progress$inc(
      1/number_of_files,
      detail = paste0("Image ", i, "/", number_of_files,". Est. time: ", est_time)
      )
    feature_list[[f]] <- extract_features_inception_v3(f, top_trim, bottom_trim)
  }
  
  # Convert to dataframe
  if (save) {
    features_df <- data.frame(filename = names(feature_list), matrix(
      unlist(feature_list), nrow=length(feature_list), byrow=TRUE
    ))
    fwrite(features_df, paste0(save_dir, "/_features_v3.csv"))
  } else {
    features_df <- data.frame(matrix(
      unlist(feature_list), nrow=length(feature_list), byrow=TRUE
    ))
    return(features_df)
  }
}
