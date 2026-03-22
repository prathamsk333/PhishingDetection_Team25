# ============================================================
# Logger utility
# ============================================================
# Uses the 'logger' package for structured, timestamped logs.

library(logger)

# Set up a log file under logs/ directory
log_dir <- "logs"
dir.create(log_dir, recursive = TRUE, showWarnings = FALSE)

log_file <- file.path(log_dir, paste0("log_", format(Sys.time(), "%m_%d_%Y_%H_%M_%S"), ".log"))

# Log to both console and file
log_appender(appender_tee(log_file))
log_threshold(INFO)

# Convenience wrappers that match Python logging style
ns_log_info <- function(...) log_info(...)
ns_log_warning <- function(...) log_warn(...)
ns_log_error <- function(...) log_error(...)
