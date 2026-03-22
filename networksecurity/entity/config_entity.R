# ============================================================
# Config Entities  (mirrors config_entity.py)
# ============================================================

source(file.path("networksecurity", "constants", "training_pipeline.R"))

# ---- TrainingPipelineConfig --------------------------------
TrainingPipelineConfig <- function(timestamp = format(Sys.time(), "%m_%d_%Y_%H_%M_%S")) {
  list(
    pipeline_name = PIPELINE_NAME,
    artifact_name = ARTIFACT_DIR,
    artifact_dir  = file.path(ARTIFACT_DIR, timestamp),
    model_dir     = "final_model",
    timestamp     = timestamp
  )
}

# ---- DataIngestionConfig -----------------------------------
DataIngestionConfig <- function(training_pipeline_config) {
  base <- file.path(training_pipeline_config$artifact_dir, DATA_INGESTION_DIR_NAME)
  list(
    data_ingestion_dir     = base,
    feature_store_file_path = file.path(base, DATA_INGESTION_FEATURE_STORE_DIR, FILE_NAME),
    training_file_path     = file.path(base, DATA_INGESTION_INGESTED_DIR, TRAIN_FILE_NAME),
    testing_file_path      = file.path(base, DATA_INGESTION_INGESTED_DIR, TEST_FILE_NAME),
    train_test_split_ratio = DATA_INGESTION_TRAIN_TEST_SPLIT_RATIO,
    collection_name        = DATA_INGESTION_COLLECTION_NAME,
    database_name          = DATA_INGESTION_DATABASE_NAME
  )
}

# ---- DataValidationConfig ----------------------------------
DataValidationConfig <- function(training_pipeline_config) {
  base      <- file.path(training_pipeline_config$artifact_dir, DATA_VALIDATION_DIR_NAME)
  valid_dir <- file.path(base, DATA_VALIDATION_VALID_DIR)
  list(
    data_validation_dir    = base,
    valid_data_dir         = valid_dir,
    invalid_data_dir       = file.path(base, DATA_VALIDATION_INVALID_DIR),
    valid_train_file_path  = file.path(valid_dir, TRAIN_FILE_NAME),
    valid_test_file_path   = file.path(valid_dir, TEST_FILE_NAME),
    invalid_train_file_path = file.path(base, DATA_VALIDATION_INVALID_DIR, TRAIN_FILE_NAME),
    invalid_test_file_path  = file.path(base, DATA_VALIDATION_INVALID_DIR, TEST_FILE_NAME),
    drift_report_file_path  = file.path(base, DATA_VALIDATION_DRIFT_REPORT_DIR,
                                        DATA_VALIDATION_DRIFT_REPORT_FILE_NAME)
  )
}

# ---- DataTransformationConfig ------------------------------
DataTransformationConfig <- function(training_pipeline_config) {
  base <- file.path(training_pipeline_config$artifact_dir, DATA_TRANSFORMATION_DIR_NAME)
  list(
    data_transformation_dir        = base,
    transformed_train_file_path    = file.path(base, DATA_TRANSFORMATION_TRANSFORMED_DATA_DIR,
                                               sub("\\.csv$", ".rds", TRAIN_FILE_NAME)),
    transformed_test_file_path     = file.path(base, DATA_TRANSFORMATION_TRANSFORMED_DATA_DIR,
                                               sub("\\.csv$", ".rds", TEST_FILE_NAME)),
    transformed_object_file_path   = file.path(base, DATA_TRANSFORMATION_TRANSFORMED_OBJECT_DIR,
                                               PREPROCESSING_OBJECT_FILE_NAME)
  )
}

# ---- ModelTrainerConfig ------------------------------------
ModelTrainerConfig <- function(training_pipeline_config) {
  base <- file.path(training_pipeline_config$artifact_dir, MODEL_TRAINER_DIR_NAME)
  list(
    model_trainer_dir          = base,
    trained_model_file_path    = file.path(base, MODEL_TRAINER_TRAINED_MODEL_DIR, MODEL_FILE_NAME),
    expected_accuracy          = MODEL_TRAINER_EXPECTED_SCORE,
    overfitting_underfitting_threshold = MODEL_TRAINER_OVERFITTING_UNDERFITTING_THRESHOLD
  )
}
