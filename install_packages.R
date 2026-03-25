#!/usr/bin/env Rscript

# Use Posit Package Manager for pre-built binaries on Linux
# Falls back to CRAN on Windows/Mac
if (Sys.info()["sysname"] == "Linux") {
  options(repos = c(CRAN = "https://packagemanager.posit.co/cran/__linux__/jammy/latest"))
} else {
  options(repos = c(CRAN = "https://cloud.r-project.org"))
}

# Read package names from requirements.R
packages <- readLines("requirements.R")

# Remove empty lines, whitespace, and comments
packages <- trimws(packages)
packages <- packages[packages != ""]
packages <- packages[!grepl("^#", packages)]

# Install packages
cat("Installing", length(packages), "packages...\n")
for (pkg in packages) {
  if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
    cat("Installing:", pkg, "\n")
    install.packages(pkg, dependencies = TRUE)
  } else {
    cat("Already installed:", pkg, "\n")
  }
}

cat("All packages installed successfully!\n")
