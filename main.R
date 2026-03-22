# ============================================================
# main.R  –  CLI entry point  (mirrors main.py)
# ============================================================
# Run the full training pipeline from the terminal:
#   Rscript main.R

library(dotenv)
dotenv::load_dot_env(file = ".env")

source(file.path("networksecurity", "pipeline", "training_pipeline.R"))
source(file.path("networksecurity", "logging",  "logger.R"))

tryCatch({
  ns_log_info("Initiating Training Pipeline")

  pipeline <- TrainingPipeline()
  artifact <- run_pipeline(pipeline)

  cat("\n===== Training Complete =====\n")
  cat(sprintf("Train F1 : %.4f\n", artifact$train_metric_artifact$f1_score))
  cat(sprintf("Test  F1 : %.4f\n", artifact$test_metric_artifact$f1_score))
  cat(sprintf("Train Precision : %.4f\n", artifact$train_metric_artifact$precision_score))
  cat(sprintf("Test  Precision : %.4f\n", artifact$test_metric_artifact$precision_score))
  cat(sprintf("Train Recall    : %.4f\n", artifact$train_metric_artifact$recall_score))
  cat(sprintf("Test  Recall    : %.4f\n", artifact$test_metric_artifact$recall_score))
  cat(sprintf("Model saved at  : %s\n",   artifact$trained_model_file_path))

}, error = function(e) {
  cat("[ERROR]", conditionMessage(e), "\n")
  quit(status = 1)
})
