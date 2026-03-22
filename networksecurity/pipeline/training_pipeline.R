# ============================================================
# Training Pipeline  (mirrors training_pipeline.py)
# ============================================================

source(file.path("networksecurity", "logging",   "logger.R"))
source(file.path("networksecurity", "exception", "exception.R"))

source(file.path("networksecurity", "entity", "config_entity.R"))
source(file.path("networksecurity", "entity", "artifact_entity.R"))

source(file.path("networksecurity", "components", "data_ingestion.R"))
source(file.path("networksecurity", "components", "data_validation.R"))
source(file.path("networksecurity", "components", "data_transformation.R"))
source(file.path("networksecurity", "components", "model_trainer.R"))

# ---- Constructor -------------------------------------------
TrainingPipeline <- function() {
  obj <- list(
    pipeline_config = TrainingPipelineConfig()
  )
  class(obj) <- "TrainingPipeline"
  obj
}

# ---- Step 1: Data Ingestion --------------------------------
start_data_ingestion <- function(self) {
  tryCatch({
    cfg      <- DataIngestionConfig(self$pipeline_config)
    ingester <- DataIngestion(cfg)
    ns_log_info("Starting Data Ingestion step")
    artifact <- initiate_data_ingestion(ingester)
    ns_log_info(sprintf("Data Ingestion completed: %s", artifact$trained_file_path))
    artifact
  }, error = function(e) ns_stop(paste("start_data_ingestion failed:", e$message)))
}

# ---- Step 2: Data Validation --------------------------------
start_data_validation <- function(self, ingestion_artifact) {
  tryCatch({
    cfg       <- DataValidationConfig(self$pipeline_config)
    validator <- DataValidation(ingestion_artifact, cfg)
    ns_log_info("Starting Data Validation step")
    artifact  <- initiate_data_validation(validator)
    ns_log_info("Data Validation completed.")
    artifact
  }, error = function(e) ns_stop(paste("start_data_validation failed:", e$message)))
}

# ---- Step 3: Data Transformation ----------------------------
start_data_transformation <- function(self, validation_artifact) {
  tryCatch({
    cfg         <- DataTransformationConfig(self$pipeline_config)
    transformer <- DataTransformation(validation_artifact, cfg)
    ns_log_info("Starting Data Transformation step")
    artifact    <- initiate_data_transformation(transformer)
    ns_log_info("Data Transformation completed.")
    artifact
  }, error = function(e) ns_stop(paste("start_data_transformation failed:", e$message)))
}

# ---- Step 4: Model Trainer ----------------------------------
start_model_trainer <- function(self, transformation_artifact) {
  tryCatch({
    cfg     <- ModelTrainerConfig(self$pipeline_config)
    trainer <- ModelTrainer(cfg, transformation_artifact)
    ns_log_info("Starting Model Trainer step")
    artifact <- initiate_model_trainer(trainer)
    ns_log_info("Model Trainer completed.")
    artifact
  }, error = function(e) ns_stop(paste("start_model_trainer failed:", e$message)))
}

# ---- Run full pipeline --------------------------------------
run_pipeline <- function(self) {
  tryCatch({
    ns_log_info("========== Training Pipeline Started ==========")

    ingestion_artifact      <- start_data_ingestion(self)
    validation_artifact     <- start_data_validation(self, ingestion_artifact)
    transformation_artifact <- start_data_transformation(self, validation_artifact)
    model_artifact          <- start_model_trainer(self, transformation_artifact)

    ns_log_info("========== Training Pipeline Finished ==========")
    ns_log_info(sprintf("Train F1: %.4f", model_artifact$train_metric_artifact$f1_score))
    ns_log_info(sprintf("Test  F1: %.4f", model_artifact$test_metric_artifact$f1_score))

    invisible(model_artifact)
  }, error = function(e) ns_stop(paste("run_pipeline failed:", e$message)))
}
