# ============================================================
# General utilities  (mirrors main_utils/utils.py)
# ============================================================

library(yaml)

source(file.path("networksecurity", "logging",   "logger.R"))
source(file.path("networksecurity", "exception", "exception.R"))

# ---- YAML helpers ------------------------------------------
read_yaml_file <- function(file_path) {
  tryCatch(
    yaml::read_yaml(file_path),
    error = function(e) ns_stop(paste("read_yaml_file failed:", e$message))
  )
}

write_yaml_file <- function(file_path, content, replace = FALSE) {
  tryCatch({
    if (replace && file.exists(file_path)) file.remove(file_path)
    dir.create(dirname(file_path), recursive = TRUE, showWarnings = FALSE)
    yaml::write_yaml(content, file_path)
  }, error = function(e) ns_stop(paste("write_yaml_file failed:", e$message)))
}

# ---- Object serialisation ----------------------------------
save_object <- function(file_path, obj) {
  tryCatch({
    ns_log_info(sprintf("Saving object to: %s", file_path))
    dir.create(dirname(file_path), recursive = TRUE, showWarnings = FALSE)
    saveRDS(obj, file_path)
    ns_log_info("Object saved successfully.")
  }, error = function(e) ns_stop(paste("save_object failed:", e$message)))
}

load_object <- function(file_path) {
  tryCatch({
    ns_log_info(sprintf("Loading object from: %s", file_path))
    readRDS(file_path)
  }, error = function(e) ns_stop(paste("load_object failed:", e$message)))
}

# ---- Data helpers ------------------------------------------
save_data <- function(file_path, data) {
  tryCatch({
    dir.create(dirname(file_path), recursive = TRUE, showWarnings = FALSE)
    saveRDS(data, file_path)
  }, error = function(e) ns_stop(paste("save_data failed:", e$message)))
}

load_data <- function(file_path) {
  tryCatch(
    readRDS(file_path),
    error = function(e) ns_stop(paste("load_data failed:", e$message))
  )
}

# ---- Model evaluation --------------------------------------
# Runs GridSearchCV equivalent: tries all param combinations via caret's train()
# Returns a named list: model_name -> best_accuracy (F1 on test)
evaluate_models <- function(X_train, y_train, X_test, y_test, models, param_grids) {
  library(caret)
  results <- list()

  for (model_name in names(models)) {
    ns_log_info(sprintf("Evaluating model: %s", model_name))
    tryCatch({
      model_fn  <- models[[model_name]]
      tune_grid <- param_grids[[model_name]]

      train_ctrl <- trainControl(method = "cv", number = 3, verboseIter = FALSE)

      fit <- if (!is.null(tune_grid) && nrow(tune_grid) > 0) {
        caret::train(
          x         = X_train,
          y         = factor(y_train, levels = c(0, 1)),
          method    = model_fn,
          trControl = train_ctrl,
          tuneGrid  = tune_grid
        )
      } else {
        caret::train(
          x         = X_train,
          y         = factor(y_train, levels = c(0, 1)),
          method    = model_fn,
          trControl = train_ctrl
        )
      }

      preds <- predict(fit, newdata = X_test)
      cm    <- confusionMatrix(preds, factor(y_test, levels = c(0, 1)), positive = "1")
      f1    <- cm$byClass[["F1"]]
      if (is.na(f1)) f1 <- 0
      results[[model_name]] <- list(score = f1, fitted = fit)
      ns_log_info(sprintf("  %s -> F1 = %.4f", model_name, f1))
    }, error = function(e) {
      ns_log_warning(sprintf("  %s failed: %s", model_name, e$message))
      results[[model_name]] <<- list(score = 0, fitted = NULL)
    })
  }
  results
}
