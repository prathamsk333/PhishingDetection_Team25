# ============================================================
# Training Pipeline Constants
# ============================================================

TARGET_COLUMN <- "Result"
PIPELINE_NAME <- "NetworkSecurity"
ARTIFACT_DIR <- "Artifacts"
FILE_NAME <- "phisingData.csv"

TRAIN_FILE_NAME <- "train.csv"
TEST_FILE_NAME <- "test.csv"

SCHEMA_FILE_PATH <- file.path("data_schema", "schema.yaml")

SAVED_MODEL_DIR <- file.path("saved_models")
MODEL_FILE_NAME <- "model.rds"

# ------------------------------------------------------------
# Data Ingestion
# ------------------------------------------------------------
# Use generic names so they don't depend on any person or org
DATA_INGESTION_COLLECTION_NAME <- "network_data"
DATA_INGESTION_DATABASE_NAME <- "networksecurity_db"
DATA_INGESTION_DIR_NAME <- "data_ingestion"
DATA_INGESTION_FEATURE_STORE_DIR <- "feature_store"
DATA_INGESTION_INGESTED_DIR <- "ingested"
DATA_INGESTION_TRAIN_TEST_SPLIT_RATIO <- 0.2

# ------------------------------------------------------------
# Data Validation
# ------------------------------------------------------------
DATA_VALIDATION_DIR_NAME <- "data_validation"
DATA_VALIDATION_VALID_DIR <- "validated"
DATA_VALIDATION_INVALID_DIR <- "invalid"
DATA_VALIDATION_DRIFT_REPORT_DIR <- "drift_report"
DATA_VALIDATION_DRIFT_REPORT_FILE_NAME <- "report.yaml"
PREPROCESSING_OBJECT_FILE_NAME <- "preprocessing.rds"

# ------------------------------------------------------------
# Data Transformation
# ------------------------------------------------------------
DATA_TRANSFORMATION_DIR_NAME <- "data_transformation"
DATA_TRANSFORMATION_TRANSFORMED_DATA_DIR <- "transformed"
DATA_TRANSFORMATION_TRANSFORMED_OBJECT_DIR <- "transformed_object"

# KNN imputer parameters (n_neighbors equivalent)
DATA_TRANSFORMATION_KNN_NEIGHBORS <- 3

# ------------------------------------------------------------
# Model Trainer
# ------------------------------------------------------------
MODEL_TRAINER_DIR_NAME <- "model_trainer"
MODEL_TRAINER_TRAINED_MODEL_DIR <- "trained_model"
MODEL_TRAINER_EXPECTED_SCORE <- 0.6
MODEL_TRAINER_OVERFITTING_UNDERFITTING_THRESHOLD <- 0.05

TRAINING_BUCKET_NAME <- "netwworksecurity"
