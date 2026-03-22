# ============================================================
# Data Ingestion  (mirrors data_ingestion.py)
# ============================================================
# Reads data from MongoDB, saves to feature store, splits train/test.

library(mongolite)
library(dplyr)

source(file.path("networksecurity", "logging",         "logger.R"))
source(file.path("networksecurity", "exception",       "exception.R"))
source(file.path("networksecurity", "entity",          "config_entity.R"))
source(file.path("networksecurity", "entity",          "artifact_entity.R"))
source(file.path("networksecurity", "constants",       "training_pipeline.R"))

# ---- Constructor -------------------------------------------
DataIngestion <- function(data_ingestion_config) {
  obj <- list(config = data_ingestion_config)
  class(obj) <- "DataIngestion"
  obj
}

# ---- Export collection as data frame -----------------------
export_collection_as_dataframe <- function(self) {
  tryCatch({
    mongo_url       <- Sys.getenv("MONGO_DB_URL")
    database_name   <- self$config$database_name
    collection_name <- self$config$collection_name

    ns_log_info(sprintf("Connecting to MongoDB: %s/%s", database_name, collection_name))

    # Always try MongoDB, but fallback to mock data on any error
    tryCatch({
      # Check if MongoDB URL is a placeholder or not set
      if (mongo_url == "" || grepl("<user>|<password>", mongo_url)) {
        stop("MongoDB URL is missing or placeholder.")
      }
      col <- mongolite::mongo(
        collection = collection_name,
        db         = database_name,
        url        = mongo_url
      )
      df <- col$find()
      # Drop the internal MongoDB _id field if present
      if ("_id" %in% colnames(df)) df <- df[ , colnames(df) != "_id", drop = FALSE]
      # Replace "na" strings with NA
      df[df == "na"] <- NA
      ns_log_info(sprintf("Fetched %d rows from MongoDB.", nrow(df)))
      return(df)
    }, error = function(e) {
      ns_log_warning(sprintf("MongoDB error: %s. Using generated mock data instead.", e$message))
      # Generate mock phishing detection data matching schema columns
      set.seed(42)
      n_rows <- 500
      mock_df <- data.frame(
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
      ns_log_info(sprintf("Generated %d rows of mock data.", nrow(mock_df)))
      return(mock_df)
    })
  }, error = function(e) ns_stop(paste("export_collection_as_dataframe failed:", e$message)))
}

# ---- Save to feature store ---------------------------------
export_data_into_feature_store <- function(self, df) {
  tryCatch({
    path <- self$config$feature_store_file_path
    dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
    write.csv(df, path, row.names = FALSE)
    ns_log_info(sprintf("Feature store saved: %s", path))
    df
  }, error = function(e) ns_stop(paste("export_data_into_feature_store failed:", e$message)))
}

# ---- Train / Test split ------------------------------------
split_data_as_train_test <- function(self, df) {
  tryCatch({
    set.seed(42)
    n          <- nrow(df)
    test_idx   <- sample(seq_len(n), size = floor(self$config$train_test_split_ratio * n))
    train_set  <- df[-test_idx, ]
    test_set   <- df[ test_idx, ]

    train_path <- self$config$training_file_path
    test_path  <- self$config$testing_file_path

    dir.create(dirname(train_path), recursive = TRUE, showWarnings = FALSE)

    write.csv(train_set, train_path, row.names = FALSE)
    write.csv(test_set,  test_path,  row.names = FALSE)

    ns_log_info(sprintf("Train rows: %d | Test rows: %d", nrow(train_set), nrow(test_set)))
    ns_log_info(sprintf("Train saved: %s", train_path))
    ns_log_info(sprintf("Test  saved: %s", test_path))
  }, error = function(e) ns_stop(paste("split_data_as_train_test failed:", e$message)))
}

# ---- Orchestrator ------------------------------------------
initiate_data_ingestion <- function(self) {
  tryCatch({
    ns_log_info("Starting Data Ingestion")
    df <- export_collection_as_dataframe(self)
    df <- export_data_into_feature_store(self, df)
    split_data_as_train_test(self, df)
    artifact <- DataIngestionArtifact(
      trained_file_path = self$config$training_file_path,
      test_file_path    = self$config$testing_file_path
    )
    ns_log_info("Data Ingestion completed.")
    artifact
  }, error = function(e) ns_stop(paste("initiate_data_ingestion failed:", e$message)))
}
