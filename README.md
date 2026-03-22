# Network Security – R Edition

An R port of the [networksecurity_done](../networksecurity_done) Python project.  
Detects phishing URLs using a full ML pipeline exposed via a REST API.

---

## Project Structure

```
networksecurity_r/
├── app.R                        # Plumber REST API  (replaces FastAPI app.py)
├── main.R                       # CLI training runner  (replaces main.py)
├── requirements.R               # R package list
├── Dockerfile
├── .env.example
├── data_schema/
│   └── schema.yaml
├── networksecurity/
│   ├── constants/
│   │   └── training_pipeline.R  # All pipeline constants
│   ├── entity/
│   │   ├── config_entity.R      # Config data structures
│   │   └── artifact_entity.R    # Artifact data structures
│   ├── exception/
│   │   └── exception.R          # Custom exception helpers
│   ├── logging/
│   │   └── logger.R             # File + console logger
│   ├── components/
│   │   ├── data_ingestion.R     # MongoDB → CSV
│   │   ├── data_validation.R    # Column check + KS drift test
│   │   ├── data_transformation.R# KNN imputation (caret)
│   │   └── model_trainer.R      # Multi-model training + MLflow
│   ├── pipeline/
│   │   └── training_pipeline.R  # End-to-end orchestration
│   └── utils/
│       ├── main_utils/utils.R   # YAML, save/load helpers, evaluate_models
│       └── ml_utils/
│           ├── metric/classification_metric.R
│           └── model/estimator.R  # NetworkModel wrapper
└── .github/workflows/main.yml   # CI/CD – ECR + EC2 deploy
```

---

## Quick Start

### 1. Install R packages

```r
install.packages(readLines("requirements.R"), repos = "https://cloud.r-project.org")
```

### 2. Configure environment

```bash
cp .env.example .env
# Fill in MONGODB_URL_KEY, MONGO_DB_URL, AWS keys
```

### 3. Run training pipeline

```bash
Rscript main.R
```

### 4. Start the API server

```bash
Rscript app.R
# API available at http://localhost:8000
# Swagger docs at http://localhost:8000/__docs__/
```

### 5. Docker

```bash
docker build -t networksecurity-r .
docker run -p 8000:8000 --env-file .env networksecurity-r
```

---

## API Endpoints

| Method | Endpoint   | Description                           |
| ------ | ---------- | ------------------------------------- |
| GET    | `/`        | Redirect to Swagger docs              |
| GET    | `/train`   | Trigger full training pipeline        |
| POST   | `/predict` | Upload CSV → get phishing predictions |

---

## ML Pipeline Steps

1. **Data Ingestion** – reads from MongoDB, splits train/test (80/20)
2. **Data Validation** – checks column count + KS-test for dataset drift
3. **Data Transformation** – KNN imputation via `caret::preProcess`
4. **Model Trainer** – trains RF / DT / GBM / LogReg / AdaBoost, picks best F1, logs with MLflow

---

## Python → R Equivalents

| Python                | R                              |
| --------------------- | ------------------------------ |
| `FastAPI`             | `plumber`                      |
| `pandas DataFrame`    | `data.frame`                   |
| `sklearn KNNImputer`  | `caret::preProcess(knnImpute)` |
| `sklearn Pipeline`    | `caret::preProcess` object     |
| `pickle.dump/load`    | `saveRDS / readRDS`            |
| `numpy .npy arrays`   | `.rds` data frames             |
| `GridSearchCV`        | `caret::train + tuneGrid`      |
| `mlflow` (Python SDK) | `mlflow` (R SDK)               |
| `logging`             | `logger` package               |
| `dataclasses`         | named R lists                  |
