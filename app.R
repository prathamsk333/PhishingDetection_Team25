# ============================================================
# REST API using Plumber  (mirrors app.py / FastAPI)
# ============================================================
# Run with: Rscript app.R
# Or:       plumber::plumb("app.R")$run(host="0.0.0.0", port=8000)

library(plumber)
library(dotenv)
library(mongolite)

# Load environment variables from .env (only if file exists)
if (file.exists(".env")) {
  dotenv::load_dot_env(file = ".env")
}

# Source utilities (needed for predictions)
source(file.path("networksecurity", "utils", "main_utils", "utils.R"))
source(file.path("networksecurity", "utils", "ml_utils", "model", "estimator.R"))
source(file.path("networksecurity", "logging",   "logger.R"))
source(file.path("networksecurity", "exception", "exception.R"))

# Source training pipeline only if training packages are available
# (not needed for production API with pre-trained model)
if (requireNamespace("gbm", quietly = TRUE) && 
    requireNamespace("randomForest", quietly = TRUE)) {
  source(file.path("networksecurity", "pipeline",  "training_pipeline.R"))
  source(file.path("networksecurity", "constants", "training_pipeline.R"))
}

# MongoDB connection (used for reading live data)
mongo_url      <- Sys.getenv("MONGODB_URL_KEY")

#* @apiTitle  Network Security - Phishing Detection API
#* @apiDescription R/Plumber port of the Python networksecurity project.

#* Enable CORS for frontend
#* @filter cors
function(req, res) {
  res$setHeader("Access-Control-Allow-Origin", "*")
  res$setHeader("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
  res$setHeader("Access-Control-Allow-Headers", "Content-Type, Authorization")
  
  if (req$REQUEST_METHOD == "OPTIONS") {
    res$status <- 200
    return(list())
  } else {
    plumber::forward()
  }
}

# ----------------------------------------------------------------
#* Redirect root to docs
#* @get /
function(res) {
  res$status <- 302
  res$setHeader("Location", "/__docs__/")
  list(message = "Redirecting to API docs")
}

# ----------------------------------------------------------------
#* Health check endpoint
#* @get /health
#* @serializer unboxedJSON
function() {
  tryCatch({
    model_exists <- file.exists(file.path("final_model", "model.rds")) && 
                    file.exists(file.path("final_model", "preprocessor.rds"))
    
    list(
      status = "healthy",
      model_loaded = model_exists,
      version = "1.0.0",
      timestamp = format(Sys.time(), "%Y-%m-%d %H:%M:%S")
    )
  }, error = function(e) {
    list(
      status = "error",
      model_loaded = FALSE,
      version = "1.0.0",
      message = conditionMessage(e)
    )
  })
}

# ----------------------------------------------------------------
#* Get current model information
#* @get /model/info
#* @serializer unboxedJSON
function(res) {
  tryCatch({
    # Check if model exists
    if (!file.exists(file.path("final_model", "model.rds"))) {
      res$status <- 404
      return(list(status = "error", message = "Model not found. Please train the model first."))
    }
    
    # Find the most recent local_runs folder containing metrics
    local_dirs <- list.dirs("local_runs", recursive = FALSE, full.names = TRUE)
    valid_dirs <- local_dirs[file.exists(file.path(local_dirs, "train_metrics.json"))]
    
    if (length(valid_dirs) == 0) {
      return(list(
        status = "success",
        model_name = "Unknown",
        message = "Model exists but no training metrics found"
      ))
    }
    
    # Sort alphabetically (since they are named YYYYMMDD_HHMMSS, this is chronological)
    valid_dirs <- sort(valid_dirs)
    latest_run <- valid_dirs[length(valid_dirs)]
    
    # Read metrics
    train_metrics_path <- file.path(latest_run, "train_metrics.json")
    test_metrics_path <- file.path(latest_run, "test_metrics.json")
    
    train_metrics <- if (file.exists(train_metrics_path)) {
      jsonlite::fromJSON(train_metrics_path)
    } else {
      list(f1 = NA, precision = NA, recall = NA)
    }
    
    test_metrics <- if (file.exists(test_metrics_path)) {
      jsonlite::fromJSON(test_metrics_path)
    } else {
      list(f1 = NA, precision = NA, recall = NA)
    }
    
    list(
      status = "success",
      model_name = if (!is.null(train_metrics$model)) train_metrics$model else "Unknown",
      train_f1 = if (!is.na(train_metrics$f1)) round(train_metrics$f1, 4) else NULL,
      train_precision = if (!is.na(train_metrics$precision)) round(train_metrics$precision, 4) else NULL,
      train_recall = if (!is.na(train_metrics$recall)) round(train_metrics$recall, 4) else NULL,
      test_f1 = if (!is.na(test_metrics$f1)) round(test_metrics$f1, 4) else NULL,
      test_precision = if (!is.na(test_metrics$precision)) round(test_metrics$precision, 4) else NULL,
      test_recall = if (!is.na(test_metrics$recall)) round(test_metrics$recall, 4) else NULL,
      trained_at = if (!is.null(train_metrics$timestamp)) train_metrics$timestamp else basename(latest_run)
    )
  }, error = function(e) {
    res$status <- 500
    list(status = "error", message = conditionMessage(e))
  })
}

# ----------------------------------------------------------------
#* Get feature schema with descriptions
#* @get /features/schema
#* @serializer json
function() {
  list(
    status = "success",
    features = list(
      list(name = "having_IP_Address", description = "URL uses IP address instead of domain name", type = "binary"),
      list(name = "URL_Length", description = "URL length is suspicious (too long or obfuscated)", type = "binary"),
      list(name = "Shortining_Service", description = "URL uses a shortening service (bit.ly, tinyurl, etc.)", type = "binary"),
      list(name = "having_At_Symbol", description = "URL contains @ symbol (often used to mislead)", type = "binary"),
      list(name = "double_slash_redirecting", description = "URL contains // after the protocol (redirect trick)", type = "binary"),
      list(name = "Prefix_Suffix", description = "Domain name contains dash/hyphen (e.g., fake-paypal.com)", type = "binary"),
      list(name = "having_Sub_Domain", description = "URL has multiple subdomains (suspicious nesting)", type = "binary"),
      list(name = "SSLfinal_State", description = "Website has valid SSL certificate (HTTPS)", type = "binary"),
      list(name = "Domain_registeration_length", description = "Domain registered for a long period (trustworthy)", type = "binary"),
      list(name = "Favicon", description = "Favicon is loaded from external domain (suspicious)", type = "binary"),
      list(name = "port", description = "URL uses non-standard port number", type = "binary"),
      list(name = "HTTPS_token", description = "Domain name contains 'https' string (fake security)", type = "binary"),
      list(name = "Request_URL", description = "High percentage of external objects in page", type = "binary"),
      list(name = "URL_of_Anchor", description = "High percentage of anchor tags point to different domains", type = "binary"),
      list(name = "Links_in_tags", description = "Suspicious links in meta, script, or link tags", type = "binary"),
      list(name = "SFH", description = "Server Form Handler (form action) is suspicious or empty", type = "binary"),
      list(name = "Submitting_to_email", description = "Form submits to email address (phishing data collection)", type = "binary"),
      list(name = "Abnormal_URL", description = "URL doesn't match WHOIS identity", type = "binary"),
      list(name = "Redirect", description = "Page has multiple redirects (>4)", type = "binary"),
      list(name = "on_mouseover", description = "JavaScript onMouseOver changes status bar", type = "binary"),
      list(name = "RightClick", description = "Right-click is disabled (hiding source code)", type = "binary"),
      list(name = "popUpWidnow", description = "Page uses pop-up windows (often for fake forms)", type = "binary"),
      list(name = "Iframe", description = "Page uses invisible iframes (hidden content loading)", type = "binary"),
      list(name = "age_of_domain", description = "Domain age is old/established (trustworthy)", type = "binary"),
      list(name = "DNSRecord", description = "Domain has valid DNS record", type = "binary"),
      list(name = "web_traffic", description = "Website has significant traffic (Alexa rank)", type = "binary"),
      list(name = "Page_Rank", description = "Website has good PageRank score", type = "binary"),
      list(name = "Google_Index", description = "Website is indexed by Google", type = "binary"),
      list(name = "Links_pointing_to_page", description = "Many external sites link to this page", type = "binary"),
      list(name = "Statistical_report", description = "Domain appears in phishing databases", type = "binary")
    )
  )
}

# ----------------------------------------------------------------
#* Trigger the full training pipeline
#* @get /train
#* @serializer unboxedJSON
function() {
  tryCatch({
    # Check if training pipeline is available
    if (!exists("TrainingPipeline")) {
      # Production mode - return existing model info
      ns_log_info("Training pipeline not available - returning existing model")
      
      if (!file.exists(file.path("final_model", "model.rds"))) {
        return(list(
          status = "error",
          message = "Model not found and training pipeline not available in production build."
        ))
      }
      
      # Simulate training delay for UX
      delay_secs <- sample(3:4, 1)
      ns_log_info(sprintf("Simulating training delay of %d seconds...", delay_secs))
      Sys.sleep(delay_secs)
      
      # Find the most recent local_runs folder containing metrics
      local_dirs <- list.dirs("local_runs", recursive = FALSE, full.names = TRUE)
      valid_dirs <- local_dirs[file.exists(file.path(local_dirs, "train_metrics.json"))]
      
      if (length(valid_dirs) == 0) {
        return(list(
          status = "success",
          message = "Model exists but no training metrics found.",
          model_name = "Unknown"
        ))
      }
      
      valid_dirs <- sort(valid_dirs)
      latest_run <- valid_dirs[length(valid_dirs)]
      
      train_metrics_path <- file.path(latest_run, "train_metrics.json")
      test_metrics_path  <- file.path(latest_run, "test_metrics.json")
      
      train_metrics <- if (file.exists(train_metrics_path)) jsonlite::fromJSON(train_metrics_path) else list(f1 = NA, precision = NA, recall = NA)
      test_metrics  <- if (file.exists(test_metrics_path))  jsonlite::fromJSON(test_metrics_path)  else list(f1 = NA, precision = NA, recall = NA)
      
      return(list(
        status = "success",
        message = "Returning existing model (training skipped).",
        model_name = if (!is.null(train_metrics$model)) train_metrics$model else "Unknown",
        train_metrics = list(
          f1        = if (!is.na(train_metrics$f1))        round(train_metrics$f1, 4)        else NULL,
          precision = if (!is.na(train_metrics$precision)) round(train_metrics$precision, 4) else NULL,
          recall    = if (!is.na(train_metrics$recall))    round(train_metrics$recall, 4)    else NULL
        ),
        test_metrics = list(
          f1        = if (!is.na(test_metrics$f1))        round(test_metrics$f1, 4)        else NULL,
          precision = if (!is.na(test_metrics$precision)) round(test_metrics$precision, 4) else NULL,
          recall    = if (!is.na(test_metrics$recall))    round(test_metrics$recall, 4)    else NULL
        ),
        model_path = file.path("final_model", "model.rds"),
        trained_at = if (!is.null(train_metrics$timestamp)) train_metrics$timestamp else basename(latest_run)
      ))
    }
    
    # Training pipeline available - train new model
    ns_log_info("Training triggered via API")
    pipeline <- TrainingPipeline()
    artifact <- run_pipeline(pipeline)
    
    list(
      status = "success",
      message = "Training completed successfully.",
      model_name = "Best Model Selected",
      train_metrics = list(
        f1 = artifact$train_metric_artifact$f1_score,
        precision = artifact$train_metric_artifact$precision_score,
        recall = artifact$train_metric_artifact$recall_score
      ),
      test_metrics = list(
        f1 = artifact$test_metric_artifact$f1_score,
        precision = artifact$test_metric_artifact$precision_score,
        recall = artifact$test_metric_artifact$recall_score
      ),
      model_path = artifact$trained_model_file_path
    )
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

# ----------------------------------------------------------------
#* Get dataset splits (train/test/validation data) with pagination
#* @get /data/splits
#* @param split:character Which split to retrieve: "train", "test", or "all" (default: "all")
#* @param page:int Page number (default: 1)
#* @param page_size:int Rows per page (default: 20, max: 1000)
#* @serializer json
function(split = "all", page = 1, page_size = 20, res) {
  tryCatch({
    # Validate page and page_size
    page <- as.integer(page)
    page_size <- as.integer(page_size)
    
    if (is.na(page) || page < 1) {
      res$status <- 400
      return(list(status = "error", message = "Page must be >= 1"))
    }
    
    if (is.na(page_size) || page_size < 1 || page_size > 1000) {
      res$status <- 400
      return(list(status = "error", message = "Page size must be between 1 and 1000"))
    }
    
    # Find the most recent artifact directory
    artifact_dirs <- list.dirs("Artifacts", recursive = FALSE, full.names = TRUE)
    if (length(artifact_dirs) == 0) {
      res$status <- 404
      return(list(status = "error", message = "No training artifacts found. Please train the model first."))
    }
    
    latest_artifact <- artifact_dirs[length(artifact_dirs)]
    
    # Helper function to load and paginate data
    load_split_data <- function(split_name) {
      # Try validated data first, then ingested
      validated_path <- file.path(latest_artifact, "data_validation", "validated", paste0(split_name, ".csv"))
      ingested_path <- file.path(latest_artifact, "data_ingestion", "ingested", paste0(split_name, ".csv"))
      
      if (file.exists(validated_path)) {
        data <- read.csv(validated_path, stringsAsFactors = FALSE)
        source <- "validated"
      } else if (file.exists(ingested_path)) {
        data <- read.csv(ingested_path, stringsAsFactors = FALSE)
        source <- "ingested"
      } else {
        return(NULL)
      }
      
      # Pagination
      total_rows <- nrow(data)
      total_pages <- ceiling(total_rows / page_size)
      
      start_idx <- (page - 1) * page_size + 1
      end_idx <- min(page * page_size, total_rows)
      
      if (start_idx > total_rows) {
        paginated_data <- data[0, ]  # Empty dataframe with same structure
      } else {
        paginated_data <- data[start_idx:end_idx, ]
      }
      
      list(
        split = split_name,
        source = source,
        total_rows = total_rows,
        total_pages = total_pages,
        current_page = page,
        page_size = page_size,
        returned_rows = nrow(paginated_data),
        data = paginated_data
      )
    }
    
    # Load requested splits
    result <- list(status = "success", artifact = basename(latest_artifact))
    
    if (split == "all") {
      train_data <- load_split_data("train")
      test_data <- load_split_data("test")
      
      result$train <- train_data
      result$test <- test_data
      
      if (is.null(train_data) && is.null(test_data)) {
        res$status <- 404
        return(list(status = "error", message = "No data splits found in artifacts"))
      }
    } else if (split %in% c("train", "test")) {
      split_data <- load_split_data(split)
      if (is.null(split_data)) {
        res$status <- 404
        return(list(status = "error", message = sprintf("No %s data found", split)))
      }
      result[[split]] <- split_data
    } else {
      res$status <- 400
      return(list(status = "error", message = "Split must be 'train', 'test', or 'all'"))
    }
    
    result
  }, error = function(e) {
    res$status <- 500
    list(status = "error", message = conditionMessage(e))
  })
}

# ----------------------------------------------------------------
#* Export dataset split to CSV
#* @get /data/export
#* @param split:character Which split to export: "train" or "test" (required)
#* @serializer csv
function(split, res) {
  tryCatch({
    if (missing(split) || !split %in% c("train", "test")) {
      res$status <- 400
      return(list(status = "error", message = "Split must be 'train' or 'test'"))
    }
    
    # Find the most recent artifact directory
    artifact_dirs <- list.dirs("Artifacts", recursive = FALSE, full.names = TRUE)
    if (length(artifact_dirs) == 0) {
      res$status <- 404
      return(list(status = "error", message = "No training artifacts found"))
    }
    
    latest_artifact <- artifact_dirs[length(artifact_dirs)]
    
    # Try validated data first, then ingested
    validated_path <- file.path(latest_artifact, "data_validation", "validated", paste0(split, ".csv"))
    ingested_path <- file.path(latest_artifact, "data_ingestion", "ingested", paste0(split, ".csv"))
    
    if (file.exists(validated_path)) {
      data <- read.csv(validated_path, stringsAsFactors = FALSE)
    } else if (file.exists(ingested_path)) {
      data <- read.csv(ingested_path, stringsAsFactors = FALSE)
    } else {
      res$status <- 404
      return(list(status = "error", message = sprintf("No %s data found", split)))
    }
    
    # Set download headers
    res$setHeader("Content-Disposition", sprintf('attachment; filename="%s_data.csv"', split))
    
    data
  }, error = function(e) {
    res$status <- 500
    list(status = "error", message = conditionMessage(e))
  })
}

# ----------------------------------------------------------------
#* Generate random test data for phishing detection
#* @get /generate_test_data
#* @param type:character Type of data to generate: "phishing", "legitimate", or "random" (default: "random")
#* @param count:int Number of records to generate (default: 1, max: 100)
#* @serializer json
function(type = "random", count = 1, res) {
  tryCatch({
    # Validate count
    count <- as.integer(count)
    if (is.na(count) || count < 1 || count > 100) {
      res$status <- 400
      return(list(status = "error", message = "Count must be between 1 and 100"))
    }
    
    # Validate type
    type <- tolower(type)
    if (!type %in% c("phishing", "legitimate", "random")) {
      res$status <- 400
      return(list(status = "error", message = "Type must be 'phishing', 'legitimate', or 'random'"))
    }
    
    # Try to load real data from feature store or generate mock data
    data_source <- NULL
    tryCatch({
      # Look for the most recent feature store file
      artifact_dirs <- list.dirs("Artifacts", recursive = FALSE, full.names = TRUE)
      if (length(artifact_dirs) > 0) {
        latest_artifact <- artifact_dirs[length(artifact_dirs)]
        feature_store_path <- file.path(latest_artifact, "data_ingestion", "ingested", "train.csv")
        if (file.exists(feature_store_path)) {
          data_source <- read.csv(feature_store_path, stringsAsFactors = FALSE)
          ns_log_info(sprintf("Loaded %d rows from feature store", nrow(data_source)))
        }
      }
    }, error = function(e) {
      ns_log_warning(sprintf("Could not load feature store: %s", e$message))
    })
    
    # If no real data, generate mock data
    if (is.null(data_source)) {
      ns_log_info("Generating mock data")
      set.seed(42)
      n_rows <- 500
      data_source <- data.frame(
        having_IP_Address = sample(0:1, n_rows, replace = TRUE),
        URL_Length = sample(0:1, n_rows, replace = TRUE),
        Shortining_Service = sample(0:1, n_rows, replace = TRUE),
        having_At_Symbol = sample(0:1, n_rows, replace = TRUE),
        double_slash_redirecting = sample(0:1, n_rows, replace = TRUE),
        Prefix_Suffix = sample(0:1, n_rows, replace = TRUE),
        having_Sub_Domain = sample(0:1, n_rows, replace = TRUE),
        SSLfinal_State = sample(0:1, n_rows, replace = TRUE),
        Domain_registeration_length = sample(0:1, n_rows, replace = TRUE),
        Favicon = sample(0:1, n_rows, replace = TRUE),
        port = sample(0:1, n_rows, replace = TRUE),
        HTTPS_token = sample(0:1, n_rows, replace = TRUE),
        Request_URL = sample(0:1, n_rows, replace = TRUE),
        URL_of_Anchor = sample(0:1, n_rows, replace = TRUE),
        Links_in_tags = sample(0:1, n_rows, replace = TRUE),
        SFH = sample(0:1, n_rows, replace = TRUE),
        Submitting_to_email = sample(0:1, n_rows, replace = TRUE),
        Abnormal_URL = sample(0:1, n_rows, replace = TRUE),
        Redirect = sample(0:1, n_rows, replace = TRUE),
        on_mouseover = sample(0:1, n_rows, replace = TRUE),
        RightClick = sample(0:1, n_rows, replace = TRUE),
        popUpWidnow = sample(0:1, n_rows, replace = TRUE),
        Iframe = sample(0:1, n_rows, replace = TRUE),
        age_of_domain = sample(0:1, n_rows, replace = TRUE),
        DNSRecord = sample(0:1, n_rows, replace = TRUE),
        web_traffic = sample(0:1, n_rows, replace = TRUE),
        Page_Rank = sample(0:1, n_rows, replace = TRUE),
        Google_Index = sample(0:1, n_rows, replace = TRUE),
        Links_pointing_to_page = sample(0:1, n_rows, replace = TRUE),
        Statistical_report = sample(0:1, n_rows, replace = TRUE),
        Result = sample(c(-1, 1), n_rows, replace = TRUE)
      )
    }
    
    # Filter by type and sample
    records <- list()
    if (type == "phishing") {
      # Filter for phishing examples (Result = -1)
      phishing_data <- data_source[data_source$Result == -1, ]
      if (nrow(phishing_data) == 0) {
        # Fallback if no phishing data
        phishing_data <- data_source[sample(nrow(data_source), min(count, nrow(data_source))), ]
      }
      sampled <- phishing_data[sample(nrow(phishing_data), min(count, nrow(phishing_data))), ]
    } else if (type == "legitimate") {
      # Filter for legitimate examples (Result = 1)
      legit_data <- data_source[data_source$Result == 1, ]
      if (nrow(legit_data) == 0) {
        # Fallback if no legitimate data
        legit_data <- data_source[sample(nrow(data_source), min(count, nrow(data_source))), ]
      }
      sampled <- legit_data[sample(nrow(legit_data), min(count, nrow(legit_data))), ]
    } else {
      # Random: sample from all data
      sampled <- data_source[sample(nrow(data_source), min(count, nrow(data_source))), ]
    }
    
    # Remove Result column and convert to list of records
    feature_cols <- setdiff(names(sampled), "Result")
    for (i in 1:nrow(sampled)) {
      record <- list()
      for (col in feature_cols) {
        # Convert to scalar integer (not array) and ensure 0/1 values
        value <- as.integer(sampled[i, col])
        # Convert -1 to 1 (phishing indicator) and 1 to 0 (safe indicator)
        # Wait, let's keep the original meaning: we want 1=risk, 0=safe
        # So if the data has -1 (phishing) we should map features appropriately
        record[[col]] <- value
      }
      records[[i]] <- record
    }
    
    # Return single object if count=1, otherwise array
    if (count == 1) {
      list(
        status = "success",
        type = type,
        count = 1,
        data = records[[1]],
        source = if (!is.null(data_source) && "Result" %in% names(data_source)) "real_dataset" else "generated"
      )
    } else {
      list(
        status = "success",
        type = type,
        count = length(records),
        data = records,
        source = if (!is.null(data_source) && "Result" %in% names(data_source)) "real_dataset" else "generated"
      )
    }
  }, error = function(e) {
    res$status <- 500
    list(status = "error", message = conditionMessage(e))
  })
}
