<div align="center">
  <h1>🛡️ Network Security: Phishing Detection (R Edition)</h1>
  <p><i>An End-to-End Machine Learning Pipeline ported to R</i></p>

  <!-- Badges -->
  <img src="https://img.shields.io/badge/Language-R-blue.svg" alt="R">
  <img src="https://img.shields.io/badge/API-Plumber-orange.svg" alt="Plumber">
  <img src="https://img.shields.io/badge/ML-caret%20%7C%20MLflow-yellow.svg" alt="ML">
  <img src="https://img.shields.io/badge/CI%2FCD-GitHub%20Actions-lightgrey.svg" alt="CI/CD">
  <img src="https://img.shields.io/badge/Deployment-Docker%20%7C%20AWS%20EC2-brightgreen.svg" alt="Deploy">
</div>

---

## Team Members
- Pratham – 2023BCS0201  
- Akhil – 2023BCD0015
- Arjun – 2023BCS0135
- Aryan – 2023BCD0012
---

---

## Problem Statement
Phishing attacks are a major cybersecurity threat where malicious URLs trick users into revealing sensitive information. Manual detection is inefficient and unreliable. This project builds a machine learning system to automatically classify URLs as phishing or legitimate.

---

## Objectives
- Build a phishing detection ML model  
- Perform data preprocessing and validation  
- Train and compare multiple models  
- Select best model using evaluation metrics  
- Deploy as an API for real-time prediction  

---
---

## 🌐 Live Application

**Try it now:** [https://networksecurityx.vercel.app/](https://networksecurityx.vercel.app/)

Interactive web interface for phishing detection with real-time predictions, model training, and dataset exploration.

---
## Dataset
- **Source: UC Irvine(https://archive.ics.uci.edu/dataset/327/phishing+websites)
- **Observations:** Dynamic dataset  
- **Variables:** 31 features

  
## 💻 Tech Stack & Python → R Translation

For developers coming from the Python ecosystem, here is how the stack translates:

| Concept / Tool | Python Stack | R Stack |
|:---|:---|:---|
| **Web API** | `FastAPI` | `plumber` |
| **Data Structures** | `pandas.DataFrame` | `data.frame` |
| **Imputation** | `sklearn KNNImputer` | `caret::preProcess(knnImpute)` |
| **Hyperparameter Tuning**| `GridSearchCV` | `caret::train` + `tuneGrid` |
| **Serialization** | `pickle` | `saveRDS` / `readRDS` |
| **Experiment Tracking** | `mlflow` (Python) | `mlflow` (R SDK) |

---

## 🎯 The Vision
Modern cybersecurity relies on rapid, accurate detection of threats. This project provides a complete Machine Learning ecosystem to **detect phishing URLs**, ported entirely from Python into idiomatic **R**. It's designed not just as a model, but as a fully operationalized service ready for production.

---

## 🏗️ Methodology(Architecture)

Our system is structured into several robust, scalable components:
- **Data Layer:** Ingests live data safely from MongoDB.
- **ML Pipeline:** Handles validation, imputation, and multi-model training.
- **Serving Layer:** Exposes models via a high-performance REST API (`plumber`).
- **DevOps:** Fully containerized with Docker and continuously deployed to AWS EC2 via GitHub Actions.

---

## 🚀 The Machine Learning Pipeline

1. **📥 Ingestion:** Fetches the latest network data from MongoDB and splits into Train/Test (80/20).
2. **⚖️ Validation:** Validates schema and performs **Kolmogorov-Smirnov (KS) tests** to detect data drift before training.
3. **🔄 Transformation:** Uses `caret::preProcess` for K-Nearest Neighbors (KNN) imputation and feature scaling.
4. **🧠 Training & Tuning:** Trains multiple models (Random Forest, Decision Tree, GBM, Logistic Regression, AdaBoost). Tunes hyperparameters automatically and selects the best model based on **F1 Score**.
5. **📊 Tracking:** Every experiment is logged to **MLflow** for total reproduceability.

---
### Models Used
- Random Forest  
- Decision Tree  
- Gradient Boosting (GBM)  
- Logistic Regression
- C5.0
  
### Evaluation Methods
- F1 Score (primary metric)  
- Model comparison  
- Hyperparameter tuning 

---

## Results
- Multiple models were trained and evaluated  
- Best model selected based on F1 Score (C5.0)  
- High accuracy in phishing detection  

---

## 🔌 API Endpoints

The API is served directly via `app.R` / `server.R` running on port 8000.

| Method | Endpoint | Description |
| :---: | :--- | :--- |
| **GET** | `/` | Redirects to the fully interactive Swagger Documentation. |
| **GET** | `/health` | Check server status and model availability. |
| **GET** | `/model/info` | Get current model metadata and performance metrics. |
| **GET** | `/features/schema` | Get all 31 feature names with descriptions. |
| **GET** | `/train` | Triggers the complete ML pipeline asynchronously. |
| **POST** | `/predict` | Accept a CSV file upload, returning phishing predictions. |
| **POST** | `/predict_json` | Accepts JSON payload for real-time inference. |
| **GET** | `/generate_test_data` | Generate random test data (phishing/legitimate/random). |
| **GET** | `/data/splits` | Get paginated dataset splits with pagination support (max 100 rows/page). |
| **GET** | `/data/export` | Export complete dataset split (train/test) to CSV file. |

---

## 🛫 Quick Start

Want to spin this up locally? Follow these steps:

### 1️⃣ Clone & Configure
```bash
# Clone the repository
git clone <your-repo-url>
cd networksecurity_r

# Set up environment variables
cp .env.example .env
# Important: Add your MONGODB_URL_KEY and AWS credentials to .env
```

### 2️⃣ Install R Dependencies
Open R or run this command directly to install required packages:
```r
install.packages(readLines("requirements.R"), repos = "https://cloud.r-project.org")
```

### 3️⃣ Run Locally
**Train the model from the CLI:**
```bash
Rscript main.R
```

**Serve the API:**
```bash
Rscript server.R
# Check out the Swagger UI at http://localhost:8000/__docs__/
```

**Run the Frontend:**
```bash
cd frontend
npm install
npm run dev
# Open http://localhost:3000 in your browser
```

---

## 🐳 Docker Deployment

To guarantee exact reproducibility across all environments, we provide a Dockerfile.

```bash
# Build the image
docker build -t networksecurity-r .

# Run the container (passes environment variables)
docker run -p 8000:8000 --env-file .env networksecurity-r
```
## Contribution

- Aryan | Data ingestion from MongoDB, data preprocessing, initial EDA, PPT preparation  
- Pratham | Data transformation, feature engineering, data validation 
- Arjun | Model training, hyperparameter tuning, model evaluation, artifact generation  
- Akhil | Frontend development, API implementation using Plumber, model integration, deployment

## ⚙️ Continuous Integration / Continuous Deployment (CI/CD)

Any push or pull request to the `main` branch triggers our GitHub Actions pipeline (`.github/workflows/main.yml`):
1. **Builds** the Docker Image.
2. **Pushes** the container to Amazon Elastic Container Registry (ECR).
3. **Deploys** securely to an Amazon EC2 instance via SSH.
