# ============================================================
# Data Validation  (mirrors data_validation.py)
# ============================================================
# Validates column count and detects dataset drift using KS test.

library(yaml)

source(file.path("networksecurity", "logging",         "logger.R"))
source(file.path("networksecurity", "exception",       "exception.R"))
source(file.path("networksecurity", "entity",          "config_entity.R"))
source(file.path("networksecurity", "entity",          "artifact_entity.R"))
source(file.path("networksecurity", "constants",       "training_pipeline.R"))
source(file.path("networksecurity", "utils", "main_utils", "utils.R"))

# ---- Constructor -------------------------------------------
DataValidation <- function(data_ingestion_artifact, data_validation_config) {
  obj <- list(
    ingestion_artifact  = data_ingestion_artifact,
    config              = data_validation_config,
    schema_config       = read_yaml_file(SCHEMA_FILE_PATH)
  )
  class(obj) <- "DataValidation"
  obj
}

# ---- Validate column count ---------------------------------
validate_number_of_columns <- function(self, df) {
  tryCatch({
    required_cols <- length(self$schema_config$columns)
    actual_cols   <- ncol(df)
    ns_log_info(sprintf("Required columns: %d | Actual columns: %d", required_cols, actual_cols))
    actual_cols == required_cols
  }, error = function(e) ns_stop(paste("validate_number_of_columns failed:", e$message)))
}

# ---- Dataset drift detection (KS test) ---------------------
detect_dataset_drift <- function(self, base_df, current_df, threshold = 0.05) {
  tryCatch({
    status <- TRUE
    report <- list()

    common_cols <- intersect(names(base_df), names(current_df))
    common_cols <- common_cols[sapply(base_df[common_cols], is.numeric)]

    for (col in common_cols) {
      ks_result  <- ks.test(base_df[[col]], current_df[[col]])
      p_val      <- ks_result$p.value
      drift_flag <- p_val < threshold

      if (drift_flag) status <- FALSE

      report[[col]] <- list(
        p_value      = round(p_val, 6),
        drift_status = drift_flag
      )
    }

    # Save drift report
    drift_path <- self$config$drift_report_file_path
    dir.create(dirname(drift_path), recursive = TRUE, showWarnings = FALSE)
    write_yaml_file(drift_path, report)
    ns_log_info(sprintf("Drift report saved: %s", drift_path))

    status
  }, error = function(e) ns_stop(paste("detect_dataset_drift failed:", e$message)))
}

# ---- Orchestrator ------------------------------------------
initiate_data_validation <- function(self) {
  tryCatch({
    ns_log_info("Starting Data Validation")

    train_path <- self$ingestion_artifact$trained_file_path
    test_path  <- self$ingestion_artifact$test_file_path

    train_df <- read.csv(train_path,  stringsAsFactors = FALSE)
    test_df  <- read.csv(test_path,   stringsAsFactors = FALSE)

    # Column count validation
    train_valid <- validate_number_of_columns(self, train_df)
    if (!train_valid) ns_log_warning("Train dataframe does not contain all required columns.")

    test_valid <- validate_number_of_columns(self, test_df)
    if (!test_valid) ns_log_warning("Test dataframe does not contain all required columns.")

    # Drift detection
    drift_status <- detect_dataset_drift(self, base_df = train_df, current_df = test_df)

    # Save validated data
    dir.create(dirname(self$config$valid_train_file_path), recursive = TRUE, showWarnings = FALSE)
    write.csv(train_df, self$config$valid_train_file_path, row.names = FALSE)
    write.csv(test_df,  self$config$valid_test_file_path,  row.names = FALSE)
    ns_log_info("Validated data saved.")

    artifact <- DataValidationArtifact(
      validation_status       = train_valid && test_valid,
      valid_train_file_path   = self$config$valid_train_file_path,
      valid_test_file_path    = self$config$valid_test_file_path,
      invalid_train_file_path = self$config$invalid_train_file_path,
      invalid_test_file_path  = self$config$invalid_test_file_path,
      drift_report_file_path  = self$config$drift_report_file_path
    )
    ns_log_info("Data Validation completed.")
    artifact
  }, error = function(e) ns_stop(paste("initiate_data_validation failed:", e$message)))
}
