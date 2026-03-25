export default function Pipeline() {
  const stages = [
    {
      number: '01',
      title: 'Data Ingestion',
      description: 'Fetches phishing detection data from MongoDB and performs train/test split.',
      details: [
        'Connects to MongoDB collection (networksecurity_db.network_data)',
        'Performs 80/20 train-test split with seed=42',
        'Saves raw data to feature store as CSV',
        'Outputs: train.csv, test.csv',
      ],
    },
    {
      number: '02',
      title: 'Data Validation',
      description: 'Validates schema integrity and detects data drift between train and test sets.',
      details: [
        'Column count validation (ensures all 31 features present)',
        'Kolmogorov-Smirnov (KS) test for drift detection',
        'Threshold: p-value < 0.05 indicates drift',
        'Generates drift report as YAML',
        'Outputs: validated train/test files, drift_report.yaml',
      ],
    },
    {
      number: '03',
      title: 'Data Transformation',
      description: 'Handles missing values and prepares data for model training.',
      details: [
        'K-Nearest Neighbors (KNN) imputation with k=3',
        'Fits preprocessor on training data only (prevents leakage)',
        'Applies same transformation to test data',
        'Target encoding: -1 → 0 for binary classification',
        'Outputs: transformed RDS files, preprocessor object',
      ],
    },
    {
      number: '04',
      title: 'Model Training',
      description: 'Trains multiple models with hyperparameter tuning and selects the best performer.',
      details: [
        'Trains 5 algorithms: Random Forest, Decision Tree, GBM, Logistic Regression, C5.0',
        'Hyperparameter tuning via caret::train() with 3-fold CV',
        'Selects best model by F1 score on test set',
        'Logs metrics to mlruns/ folder (F1, precision, recall)',
        'Outputs: final_model/model.rds, final_model/preprocessor.rds',
      ],
    },
  ];

  return (
    <div className="max-w-7xl mx-auto px-6 py-16">
      <div className="mb-16">
        <h1 className="text-4xl font-bold tracking-tight mb-4">Training Pipeline</h1>
        <p className="text-neutral-600 max-w-2xl">
          A four-stage ML pipeline that transforms raw data into a production-ready phishing detection model.
        </p>
      </div>

      {/* Pipeline Flow Diagram */}
      <div className="mb-16 border border-neutral-200 p-4 md:p-8 overflow-x-auto">
        <div className="flex items-center justify-between min-w-max">
          {stages.map((stage, idx) => (
            <div key={stage.number} className="flex items-center">
              <div className="text-center">
                <div className="w-10 h-10 md:w-12 md:h-12 border-2 border-black flex items-center justify-center font-bold mb-2 text-sm md:text-base">
                  {stage.number}
                </div>
                <div className="text-xs font-medium max-w-[80px] md:max-w-[100px]">{stage.title}</div>
              </div>
              {idx < stages.length - 1 && (
                <div className="w-12 md:w-16 h-[2px] bg-neutral-300 mx-2 md:mx-4" />
              )}
            </div>
          ))}
        </div>
      </div>

      {/* Stage Details */}
      <div className="space-y-12">
        {stages.map((stage) => (
          <div key={stage.number} className="border border-neutral-200 p-4 md:p-8">
            <div className="flex flex-col md:flex-row items-start gap-4 md:gap-6">
              <div className="text-4xl md:text-5xl font-bold text-neutral-200">{stage.number}</div>
              <div className="flex-1">
                <h2 className="text-xl md:text-2xl font-semibold mb-3">{stage.title}</h2>
                <p className="text-neutral-600 mb-6 text-sm md:text-base">{stage.description}</p>
                <div className="space-y-2">
                  {stage.details.map((detail, idx) => (
                    <div key={idx} className="flex items-start gap-3">
                      <div className="w-1 h-1 bg-black rounded-full mt-2 flex-shrink-0" />
                      <p className="text-sm text-neutral-700">{detail}</p>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Artifacts Section */}
      <div className="mt-16 border border-neutral-200 p-4 md:p-8">
        <h2 className="text-xl md:text-2xl font-semibold mb-6">Pipeline Artifacts</h2>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div>
            <h3 className="font-medium mb-3">Intermediate Files</h3>
            <div className="space-y-2 text-xs md:text-sm font-mono text-neutral-600 break-all">
              <div>Artifacts/[timestamp]/data_ingestion/</div>
              <div>Artifacts/[timestamp]/data_validation/</div>
              <div>Artifacts/[timestamp]/data_transformation/</div>
              <div>Artifacts/[timestamp]/model_trainer/</div>
            </div>
          </div>
          <div>
            <h3 className="font-medium mb-3">Final Model</h3>
            <div className="space-y-2 text-xs md:text-sm font-mono text-neutral-600 break-all">
              <div>final_model/model.rds</div>
              <div>final_model/preprocessor.rds</div>
              <div>mlruns/[timestamp]/train_metrics.json</div>
              <div>mlruns/[timestamp]/test_metrics.json</div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
