# ============================================================
# Data Transformation  (mirrors data_transformation.py)
# ============================================================
# Handles missing values via KNN imputation and saves
# the preprocessor + transformed arrays.

library(caret)
library(RANN)   # needed by caret's knnImpute method

source(file.path("networksecurity", "logging",         "logger.R"))
source(file.path("networksecurity", "exception",       "exception.R"))
source(file.path("networksecurity", "entity",          "config_entity.R"))
source(file.path("networksecurity", "entity",          "artifact_entity.R"))
source(file.path("networksecurity", "constants",       "training_pipeline.R"))
source(file.path("networksecurity", "utils", "main_utils", "utils.R"))

# ---- Constructor -------------------------------------------
DataTransformation <- function(data_validation_artifact, data_transformation_config) {
  obj <- list(
    validation_artifact = data_validation_artifact,
    config              = data_transformation_config
  )
  class(obj) <- "DataTransformation"
  obj
}

# ---- Build KNN preprocessor --------------------------------
get_data_transformer_object <- function(train_features) {
  tryCatch({
    ns_log_info(sprintf("Building KNN imputer (k=%d)", DATA_TRANSFORMATION_KNN_NEIGHBORS))
    preprocessor <- caret::preProcess(
      train_features,
      method  = "knnImpute",
      k       = DATA_TRANSFORMATION_KNN_NEIGHBORS
    )
    preprocessor
  }, error = function(e) ns_stop(paste("get_data_transformer_object failed:", e$message)))
}

# ---- Orchestrator ------------------------------------------
initiate_data_transformation <- function(self) {
  tryCatch({
    ns_log_info("Starting Data Transformation")

    train_df <- read.csv(self$validation_artifact$valid_train_file_path, stringsAsFactors = FALSE)
    test_df  <- read.csv(self$validation_artifact$valid_test_file_path,  stringsAsFactors = FALSE)

    # Separate features and target; replace -1 → 0 in target
    X_train <- train_df[ , !names(train_df) %in% TARGET_COLUMN, drop = FALSE]
    y_train <- ifelse(train_df[[TARGET_COLUMN]] == -1, 0, train_df[[TARGET_COLUMN]])

    X_test  <- test_df[ , !names(test_df) %in% TARGET_COLUMN, drop = FALSE]
    y_test  <- ifelse(test_df[[TARGET_COLUMN]] == -1, 0, test_df[[TARGET_COLUMN]])

    # Fit preprocessor on training features only
    preprocessor    <- get_data_transformer_object(X_train)
    X_train_transformed <- predict(preprocessor, newdata = X_train)
    X_test_transformed  <- predict(preprocessor, newdata = X_test)

    # Combine into a single data frame (features + target)
    train_transformed <- cbind(X_train_transformed, target = y_train)
    test_transformed  <- cbind(X_test_transformed,  target = y_test)

    # Save transformed datasets
    save_data(self$config$transformed_train_file_path, train_transformed)
    save_data(self$config$transformed_test_file_path,  test_transformed)

    # Save preprocessor
    save_object(self$config$transformed_object_file_path, preprocessor)
    save_object(file.path("final_model", "preprocessor.rds"), preprocessor)

    ns_log_info("Data Transformation completed.")

    DataTransformationArtifact(
      transformed_object_file_path = self$config$transformed_object_file_path,
      transformed_train_file_path  = self$config$transformed_train_file_path,
      transformed_test_file_path   = self$config$transformed_test_file_path
    )
  }, error = function(e) ns_stop(paste("initiate_data_transformation failed:", e$message)))
}
