####
## Generate csv files of 'features' for a directory of images.
## 
## This script will try and generate a csv of inception-v3 features (2048 values)
## for every directory of images in a given directory
##
###

library(tensorflow)
library(keras)
library(data.table)

#' Apply the classification model to the data. Results are stored in
#' the results file.
#' 
#' @param source_dir The source directory with feature files and the model.
#' @param model_name The name of the model created in model.R
#' @param threshold The probability threshold associated with the positive class.
#' @param pos_label The label of the positive class.
#' @param neg_label The label of the negative class.
apply_model <- function(source_dir, model_name, threshold, pos_label, neg_label) {
  classify_model <- load_model_tf(model_name)
  files <- list.files(
    source_dir, pattern = "*_features_v3.csv", full.names = TRUE
  )
  
  # Look for feature files in the source_dir
  for (f in files) {
    print(sprintf("Processing file %s", f))
    
    # Read in feature data
    feature_data <- fread(f)
    
    filenames <- feature_data$filename
    # Get rid of filesname (just leaving feature data)
    input_data <- feature_data[, filename:=NULL]
    
    # Apply model to feature data
    result <- tf$constant(as.matrix(input_data)) %>% classify_model
    
    result_table <- data.table(filename = filenames, p = as.numeric(result))
    result_table$class = ifelse(result_table$p > threshold, pos_label, neg_label)
    
    fwrite(result_table, file = gsub("_features_v3.csv", "_results_v3.csv", f))
  } 
}
