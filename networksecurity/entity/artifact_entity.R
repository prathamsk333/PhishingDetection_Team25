# ============================================================
# Artifact Entities  (mirrors artifact_entity.py dataclasses)
# ============================================================

DataIngestionArtifact <- function(trained_file_path, test_file_path) {
  list(
    trained_file_path = trained_file_path,
    test_file_path    = test_file_path
  )
}

DataValidationArtifact <- function(validation_status,
                                   valid_train_file_path,
                                   valid_test_file_path,
                                   invalid_train_file_path,
                                   invalid_test_file_path,
                                   drift_report_file_path) {
  list(
    validation_status       = validation_status,
    valid_train_file_path   = valid_train_file_path,
    valid_test_file_path    = valid_test_file_path,
    invalid_train_file_path = invalid_train_file_path,
    invalid_test_file_path  = invalid_test_file_path,
    drift_report_file_path  = drift_report_file_path
  )
}

DataTransformationArtifact <- function(transformed_object_file_path,
                                       transformed_train_file_path,
                                       transformed_test_file_path) {
  list(
    transformed_object_file_path = transformed_object_file_path,
    transformed_train_file_path  = transformed_train_file_path,
    transformed_test_file_path   = transformed_test_file_path
  )
}

ClassificationMetricArtifact <- function(f1_score, precision_score, recall_score) {
  list(
    f1_score        = f1_score,
    precision_score = precision_score,
    recall_score    = recall_score
  )
}

ModelTrainerArtifact <- function(trained_model_file_path,
                                 train_metric_artifact,
                                 test_metric_artifact) {
  list(
    trained_model_file_path  = trained_model_file_path,
    train_metric_artifact    = train_metric_artifact,
    test_metric_artifact     = test_metric_artifact
  )
}
