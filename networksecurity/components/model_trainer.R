# ============================================================
# Model Trainer  (mirrors model_trainer.py)
# ============================================================
# Trains multiple classifiers, picks the best by F1.
# Tracks experiments locally via JSON (mlflow optional).

library(caret)
library(randomForest)
library(gbm)
library(e1071)
library(C50)     # AdaBoost-style boosting, no system deps

source(file.path("networksecurity", "logging",         "logger.R"))
source(file.path("networksecurity", "exception",       "exception.R"))
source(file.path("networksecurity", "entity",          "config_entity.R"))
source(file.path("networksecurity", "entity",          "artifact_entity.R"))
source(file.path("networksecurity", "constants",       "training_pipeline.R"))
source(file.path("networksecurity", "utils", "main_utils",         "utils.R"))
source(file.path("networksecurity", "utils", "ml_utils", "metric", "classification_metric.R"))
source(file.path("networksecurity", "utils", "ml_utils", "model",  "estimator.R"))

# ---- Constructor -------------------------------------------
ModelTrainer <- function(model_trainer_config, data_transformation_artifact) {
  obj <- list(
    config                    = model_trainer_config,
    transformation_artifact   = data_transformation_artifact
  )
  class(obj) <- "ModelTrainer"
  obj
}

# ---- Local experiment tracking (no external service needed) ----
track_experiment <- function(model_name, metric_artifact, split = "train") {
  tryCatch({
    run_dir <- file.path("mlruns", format(Sys.time(), "%Y%m%d_%H%M%S"))
    dir.create(run_dir, recursive = TRUE, showWarnings = FALSE)
    entry <- list(
      model      = model_name,
      split      = split,
      f1         = metric_artifact$f1_score,
      precision  = metric_artifact$precision_score,
      recall     = metric_artifact$recall_score,
      timestamp  = format(Sys.time())
    )
    log_path <- file.path(run_dir, paste0(split, "_metrics.json"))
    write(jsonlite::toJSON(entry, auto_unbox = TRUE, pretty = TRUE), log_path)
    ns_log_info(sprintf("Experiment logged: %s", log_path))
  }, error = function(e) {
    ns_log_warning(sprintf("Experiment tracking failed (non-fatal): %s", e$message))
  })
}

# ---- Train and select best model ---------------------------
train_model <- function(self, X_train, y_train, X_test, y_test) {
  tryCatch({
    # caret method strings
    models <- list(
      "Random Forest"       = "rf",
      "Decision Tree"       = "rpart",
      "Gradient Boosting"   = "gbm",
      "Logistic Regression" = "glm",
      "C5.0 Boosting"       = "C5.0"
    )

    param_grids <- list(
      "Random Forest"       = expand.grid(mtry = c(2, 4, 8)),
      "Decision Tree"       = expand.grid(cp   = c(0.001, 0.01, 0.1)),
      "Gradient Boosting"   = expand.grid(
                                n.trees           = c(50, 100),
                                interaction.depth = c(1, 3),
                                shrinkage         = c(0.01, 0.1),
                                n.minobsinnode    = 10
                              ),
      "Logistic Regression" = NULL,
      "C5.0 Boosting"       = expand.grid(trials = c(10, 20, 30), model = "tree", winnow = FALSE)
    )

    results <- evaluate_models(X_train, y_train, X_test, y_test, models, param_grids)

    # Best model by F1
    scores         <- sapply(results, function(r) r$score)
    best_name      <- names(which.max(scores))
    best_score     <- scores[[best_name]]
    best_fit       <- results[[best_name]]$fitted

    ns_log_info(sprintf("Best model: %s | F1 = %.4f", best_name, best_score))

    if (best_score < self$config$expected_accuracy) {
      ns_log_warning(sprintf("Best model F1 (%.4f) < expected (%.2f)", best_score, self$config$expected_accuracy))
    }

    # Metrics on train
    y_train_pred <- as.integer(as.character(predict(best_fit, newdata = X_train)))
    train_metric <- get_classification_score(y_train, y_train_pred)
    track_experiment(best_name, train_metric, split = "train")

    # Metrics on test
    y_test_pred  <- as.integer(as.character(predict(best_fit, newdata = X_test)))
    test_metric  <- get_classification_score(y_test, y_test_pred)
    track_experiment(best_name, test_metric, split = "test")

    list(best_name = best_name, best_fit = best_fit,
         train_metric = train_metric, test_metric = test_metric)
  }, error = function(e) ns_stop(paste("train_model failed:", e$message)))
}

# ---- Orchestrator ------------------------------------------
initiate_model_trainer <- function(self) {
  tryCatch({
    ns_log_info("Starting Model Trainer")

    train_data <- load_data(self$transformation_artifact$transformed_train_file_path)
    test_data  <- load_data(self$transformation_artifact$transformed_test_file_path)

    X_train <- train_data[ , !names(train_data) %in% "target", drop = FALSE]
    y_train <- train_data[["target"]]

    X_test  <- test_data[ , !names(test_data) %in% "target", drop = FALSE]
    y_test  <- test_data[["target"]]

    result <- train_model(self, X_train, y_train, X_test, y_test)

    # Load preprocessor to build NetworkModel wrapper
    preprocessor  <- load_object(self$transformation_artifact$transformed_object_file_path)
    network_model <- NetworkModel(preprocessor = preprocessor, model = result$best_fit)

    # Save wrapped model and bare model
    dir.create(dirname(self$config$trained_model_file_path), recursive = TRUE, showWarnings = FALSE)
    save_object(self$config$trained_model_file_path, network_model)
    save_object(file.path("final_model", "model.rds"), result$best_fit)

    ns_log_info("Model Trainer completed.")

    ModelTrainerArtifact(
      trained_model_file_path  = self$config$trained_model_file_path,
      train_metric_artifact    = result$train_metric,
      test_metric_artifact     = result$test_metric
    )
  }, error = function(e) ns_stop(paste("initiate_model_trainer failed:", e$message)))
}
