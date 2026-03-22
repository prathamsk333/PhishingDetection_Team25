# ============================================================
# Classification Metric  (mirrors classification_metric.py)
# ============================================================

library(caret)

source(file.path("networksecurity", "entity",    "artifact_entity.R"))
source(file.path("networksecurity", "logging",   "logger.R"))
source(file.path("networksecurity", "exception", "exception.R"))

get_classification_score <- function(y_true, y_pred) {
  tryCatch({
    y_true_f <- factor(y_true, levels = c(0, 1))
    y_pred_f <- factor(y_pred, levels = c(0, 1))

    cm <- confusionMatrix(y_pred_f, y_true_f, positive = "1")

    precision <- cm$byClass[["Precision"]]
    recall    <- cm$byClass[["Recall"]]
    f1        <- cm$byClass[["F1"]]

    # Replace NA with 0
    if (is.na(precision)) precision <- 0
    if (is.na(recall))    recall    <- 0
    if (is.na(f1))        f1        <- 0

    ClassificationMetricArtifact(
      f1_score        = f1,
      precision_score = precision,
      recall_score    = recall
    )
  }, error = function(e) ns_stop(paste("get_classification_score failed:", e$message)))
}
