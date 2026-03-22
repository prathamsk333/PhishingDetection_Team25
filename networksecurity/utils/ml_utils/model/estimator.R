# ============================================================
# NetworkModel estimator  (mirrors estimator.py)
# ============================================================
# Wraps a caret pre-processor (recipe/preProcess) + a fitted model
# so that predict() applies the same transformation at inference time.

source(file.path("networksecurity", "logging",   "logger.R"))
source(file.path("networksecurity", "exception", "exception.R"))

# Constructor
NetworkModel <- function(preprocessor, model) {
  tryCatch({
    obj <- list(preprocessor = preprocessor, model = model)
    class(obj) <- "NetworkModel"
    obj
  }, error = function(e) ns_stop(paste("NetworkModel init failed:", e$message)))
}

# Predict method
predict.NetworkModel <- function(network_model, newdata) {
  tryCatch({
    x_transformed <- predict(network_model$preprocessor, newdata = newdata)
    preds <- predict(network_model$model, newdata = x_transformed)
    as.integer(as.character(preds))
  }, error = function(e) ns_stop(paste("NetworkModel predict failed:", e$message)))
}
