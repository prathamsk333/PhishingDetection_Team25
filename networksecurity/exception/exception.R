# ============================================================
# Exception utility
# ============================================================
# Wraps errors with file and line information for easier debugging.

NetworkSecurityException <- function(message, call = sys.call(-1)) {
  # Build a structured condition that carries extra context
  structure(
    class = c("NetworkSecurityException", "error", "condition"),
    list(
      message = paste0("[NetworkSecurityException] ", message),
      call    = call
    )
  )
}

# Helper: raise a NetworkSecurityException and log it
ns_stop <- function(message, call = sys.call(-1)) {
  err <- NetworkSecurityException(message, call)
  # Try to log; if logger is not loaded yet, fall back to message()
  tryCatch(
    ns_log_error(conditionMessage(err)),
    error = function(e) message(conditionMessage(err))
  )
  stop(err)
}
