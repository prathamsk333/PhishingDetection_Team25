# Generates a small CSV with the exact feature columns expected by /predict
# Usage: Rscript scripts/generate_sample_predict_csv.R [rows] [out]

suppressPackageStartupMessages({
  library(yaml)
})

args <- commandArgs(trailingOnly = TRUE)
rows <- if (length(args) >= 1) as.integer(args[[1]]) else 5L
out  <- if (length(args) >= 2) args[[2]] else "sample_predict.csv"

schema <- yaml::read_yaml(file.path("data_schema", "schema.yaml"))
# schema$columns is a list of single-key maps like list(list(colA='integer'), ...)
cols <- unlist(lapply(schema$columns, names), use.names = FALSE)

# /predict expects feature columns only
feature_cols <- setdiff(cols, "Result")

set.seed(42)
df <- as.data.frame(setNames(
  replicate(length(feature_cols), sample(0:1, rows, replace = TRUE), simplify = FALSE),
  feature_cols
))

write.csv(df, out, row.names = FALSE)
cat(sprintf("Wrote %d rows to %s\n", rows, out))
