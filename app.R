# ============================================================
# REST API using Plumber  (mirrors app.py / FastAPI)
# ============================================================
# Run with: Rscript app.R
# Or:       plumber::plumb("app.R")$run(host="0.0.0.0", port=8000)

library(plumber)
library(dotenv)
library(mongolite)

# Load environment variables from .env
dotenv::load_dot_env(file = ".env")

# Source pipeline and utilities
source(file.path("networksecurity", "pipeline",  "training_pipeline.R"))
source(file.path("networksecurity", "utils", "main_utils", "utils.R"))
source(file.path("networksecurity", "utils", "ml_utils", "model", "estimator.R"))
source(file.path("networksecurity", "logging",   "logger.R"))
source(file.path("networksecurity", "exception", "exception.R"))
source(file.path("networksecurity", "constants", "training_pipeline.R"))

# MongoDB connection (used for reading live data)
mongo_url      <- Sys.getenv("MONGODB_URL_KEY")

#* @apiTitle  Network Security - Phishing Detection API
#* @apiDescription R/Plumber port of the Python networksecurity project.

# ----------------------------------------------------------------
#* Redirect root to docs
#* @get /
function(res) {
  res$status <- 302
  res$setHeader("Location", "/__docs__/")
  list(message = "Redirecting to API docs")
}

# ----------------------------------------------------------------
#* Trigger the full training pipeline
#* @get /train
#* @serializer unboxedJSON
function() {
  tryCatch({
    ns_log_info("Training triggered via API")
    pipeline <- TrainingPipeline()
    run_pipeline(pipeline)
    list(status = "success", message = "Training completed successfully.")
  }, error = function(e) {
    list(status = "error", message = conditionMessage(e))
  })
}

# ----------------------------------------------------------------
#* Predict phishing status from uploaded CSV
#* @post /predict
#* @param file:file CSV file containing feature columns
#* @serializer json
function(req, res) {
  tryCatch({
    # Parse the uploaded multipart file
    body <- req$body
    if (is.null(body$file)) {
      res$status <- 400
      return(list(status = "error", message = "No file uploaded. Use field name 'file'."))
    }

    tmp <- tempfile(fileext = ".csv")
    writeBin(body$file$value, tmp)
    df <- read.csv(tmp, stringsAsFactors = FALSE)

    preprocessor  <- load_object(file.path("final_model", "preprocessor.rds"))
    model         <- load_object(file.path("final_model", "model.rds"))
    network_model <- NetworkModel(preprocessor = preprocessor, model = model)

    y_pred <- predict.NetworkModel(network_model, newdata = df)
    df[["predicted_column"]] <- y_pred

    # Save output
    dir.create("prediction_output", showWarnings = FALSE, recursive = TRUE)
    output_path <- file.path("prediction_output", "output.csv")
    write.csv(df, output_path, row.names = FALSE)
    ns_log_info(sprintf("Prediction saved to %s", output_path))

    list(
      status     = "success",
      rows       = nrow(df),
      predictions = df[["predicted_column"]],
      output_file = output_path
    )
  }, error = function(e) {
    res$status <- 500
    list(status = "error", message = conditionMessage(e))
  })
}

# ----------------------------------------------------------------
#* Predict phishing status from JSON payload
#* @post /predict_json
#* @serializer json
#* @parser json
function(req, res) {
  tryCatch({
    body <- req$body
    if (is.null(body) || length(body) == 0) {
      res$status <- 400
      return(list(status = "error", message = "No JSON body provided."))
    }
    
    # Convert list to dataframe
    df <- as.data.frame(body, stringsAsFactors = FALSE)
    
    preprocessor  <- load_object(file.path("final_model", "preprocessor.rds"))
    model         <- load_object(file.path("final_model", "model.rds"))
    network_model <- NetworkModel(preprocessor = preprocessor, model = model)
    
    y_pred <- predict.NetworkModel(network_model, newdata = df)
    df[["predicted_column"]] <- y_pred
    
    list(
      status = "success",
      prediction = y_pred
    )
  }, error = function(e) {
    res$status <- 500
    list(status = "error", message = conditionMessage(e))
  })
}
