library(plumber)
library(dotenv)

# Ensure environment is loaded before starting the API (only if file exists)
if (file.exists(".env")) {
  dotenv::load_dot_env(file = ".env")
}

cat("Starting Plumber API...\n")
pr <- plumber::plumb(file = "app.R")
pr$run(host = "0.0.0.0", port = 8000)
