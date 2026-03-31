# Network Security: Phishing Detection
 
## 📌 Project Links

|Resource|Link|
|---|---|
|🌐 **Live Website**|[networksecurityx.vercel.app](https://networksecurityx.vercel.app/)|
|📂 **GitHub Repository**|[github.com/prathamsk333/PhishingDetection_Team25](https://github.com/prathamsk333/PhishingDetection_Team25)|
|📊 **Presentation (PPT)**|[Google Slides](https://docs.google.com/presentation/d/19ztqwJ6ukjo5WPnrZ5dDoX2e_0aWYa7DJy6gpw3GceU/edit)|
|📁 **Dataset (UCI)**|[Phishing Websites – UCI ML Repository](https://archive.ics.uci.edu/dataset/327/phishing+websites)|

---

## Team Members

- Pratham – 2023BCS0201
- Akhil – 2023BCD0018
- Arjun – 2023BCS0135
- Aryan – 2023BCD0012

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

## Dataset

- **Source:** [UCI Machine Learning Repository – Phishing Websites](https://archive.ics.uci.edu/dataset/327/phishing+websites)
- **Observations:** 11,055 instances
- **Variables:** 31 features (all integer-valued)
- **Target:** `Result` — Binary classification (`1` = Legitimate, `1` = Phishing)

**Key Attributes:**

|Feature|Description|
|---|---|
|`having_IP_Address`|Whether the URL uses an IP address instead of a domain|
|`URL_Length`|Length of the URL (short / long / very long)|
|`SSLfinal_State`|HTTPS certificate trust level|
|`Domain_registration_length`|Domain registration duration|
|`web_traffic`|Alexa-based website traffic ranking|
|`Page_Rank`|Google PageRank of the page|
|`Links_pointing_to_page`|Number of inbound links|

## 💻 Tech Stack & Python → R Translation

For developers coming from the Python ecosystem, here is how the stack translates:

|Concept / Tool|Python Stack|R Stack|
|---|---|---|
|**Web API**|`FastAPI`|`plumber`|
|**Data Structures**|`pandas.DataFrame`|`data.frame`|
|**Imputation**|`sklearn KNNImputer`|`caret::preProcess(knnImpute)`|
|**Hyperparameter Tuning**|`GridSearchCV`|`caret::train` + `tuneGrid`|
|**Serialization**|`pickle`|`saveRDS` / `readRDS`|
|**Experiment Tracking**|`mlflow` (Python)|`mlflow` (R SDK)|

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

> 🔗 **Explore interactively:** [Pipeline Page on Website](https://networksecurityx.vercel.app/pipeline)

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

Best model selected: **C5.0** based on highest F1 Score on the test set.

> _View live metrics on the [Model Page](https://networksecurityx.vercel.app/model)._

---

## 🔌 API Endpoints

The API is served directly via `app.R` / `server.R` running on port 8000.

> 🔗 **Interactive API Docs:** [API Documentation Page](https://networksecurityx.vercel.app/api-docs)

|Method|Endpoint|Description|
|---|---|---|
|**GET**|`/`|Redirects to the fully interactive Swagger Documentation.|
|**GET**|`/health`|Check server status and model availability.|
|**GET**|`/model/info`|Get current model metadata and performance metrics.|
|**GET**|`/features/schema`|Get all 31 feature names with descriptions.|
|**GET**|`/train`|Triggers the complete ML pipeline asynchronously.|
|**POST**|`/predict`|Accept a CSV file upload, returning phishing predictions.|
|**POST**|`/predict_json`|Accepts JSON payload for real-time inference.|
|**GET**|`/generate_test_data`|Generate random test data (phishing/legitimate/random).|
|**GET**|`/data/splits`|Get paginated dataset splits with pagination support (max 100 rows/page).|
|**GET**|`/data/export`|Export complete dataset split (train/test) to CSV file.|

---

## 🛫 Quick Start

Want to spin this up locally? Follow these steps:

### 1️⃣ Clone & Configure

```bash
# Clone the repository
git clone <https://github.com/prathamsk333/PhishingDetection_Team25.git>
cd PhishingDetection_Team25

# Set up environment variables
cp .env.example .env
# Important: Add your MONGODB_URL_KEY and AWS credentials to .env
```

### 2️⃣ Install R Dependencies

Open R or run this command directly to install required packages:

```r
install.packages(readLines("requirements.R"), repos = "<https://cloud.r-project.org>")
```

### 3️⃣ Run Locally

**Train the model from the CLI:**

```bash
Rscript main.R
```

**Serve the API:**

```bash
Rscript server.R
# Check out the Swagger UI at <http://localhost:8000/__docs__/>
```

**Run the Frontend:**

```bash
cd frontend
npm install
npm run dev
# Open <http://localhost:3000> in your browser
```

---

## Conclusion

- **C5.0 Boosting** emerged as the best-performing model for phishing URL detection with the highest F1 score across all evaluated algorithms.
- The **4-stage ML pipeline** (Ingestion → Validation → Transformation → Training) ensures data quality through schema validation and drift detection before any model is trained.
- **KNN imputation** effectively handles missing values without introducing data leakage by fitting only on training data.
- **MLflow experiment tracking** ensures every training run is reproducible and comparable.

---

## Contribution

|Name|Roll Number|Contribution|
|---|---|---|
|Aryan|2023BCD0012|Data ingestion from MongoDB, data preprocessing, initial EDA, PPT preparation|
|Pratham|2023BCS0201|Data transformation, feature engineering, data validation|
|Arjun|2023BCS0135|Model training, hyperparameter tuning, model evaluation, artifact generation|
|Akhil|2023BCD0018|Frontend development, API implementation using Plumber, model integration, deployment|

---

## References

1. **Dataset:** Rami M. Mohammad, Fadi Thabtah, Lee McCluskey. _Phishing Websites Dataset._ UCI Machine Learning Repository, 2012. [Link](https://archive.ics.uci.edu/dataset/327/phishing+websites)
2. **R Plumber API:** [https://www.rplumber.io/](https://www.rplumber.io/)
3. **caret Package:** [https://topepo.github.io/caret/](https://topepo.github.io/caret/)
4. **MLflow for R:** [https://mlflow.org/docs/latest/R-api.html](https://mlflow.org/docs/latest/R-api.html)
