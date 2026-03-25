'use client';

import { useEffect, useState } from 'react';
import { api, type ModelInfo, type TrainingResult } from '@/lib/api';

export default function Model() {
  const [modelInfo, setModelInfo] = useState<ModelInfo | null>(null);
  const [isTraining, setIsTraining] = useState(false);
  const [showModal, setShowModal] = useState(false);
  const [trainingResult, setTrainingResult] = useState<TrainingResult | null>(null);
  const [trainingError, setTrainingError] = useState<string | null>(null);
const [showConfirmDialog, setShowConfirmDialog] = useState(false);

  useEffect(() => {
    loadModelInfo();
  }, []);

  const loadModelInfo = () => {
    api.getModelInfo().then(setModelInfo).catch(console.error);
  };

  const handleTrain = async () => {
    
    setShowConfirmDialog(false);
    setIsTraining(true);
    setShowModal(true);
    setTrainingError(null);
    setTrainingResult(null);

    try {
      const result = await api.train();
      setTrainingResult(result);
      // Reload model info after training
      setTimeout(() => {
        loadModelInfo();
      }, 1000);
    } catch (error) {
      setTrainingError(error instanceof Error ? error.message : 'Training failed');
    } finally {
      setIsTraining(false);
    }
  };

  const closeModal = () => {
    setShowModal(false);
    setTrainingResult(null);
    setTrainingError(null);
  };

  const models = [
    {
      name: 'Random Forest',
      description: 'Ensemble of decision trees with bootstrap aggregating',
      hyperparameters: 'mtry: 2, 4, 8',
      strengths: 'Handles non-linear relationships, robust to overfitting',
    },
    {
      name: 'Decision Tree',
      description: 'Single tree with recursive binary splits',
      hyperparameters: 'cp: 0.001, 0.01, 0.1',
      strengths: 'Interpretable, fast training',
    },
    {
      name: 'Gradient Boosting',
      description: 'Sequential ensemble that corrects previous errors',
      hyperparameters: 'n.trees: 50, 100 | depth: 1, 3 | shrinkage: 0.01, 0.1',
      strengths: 'High accuracy, handles complex patterns',
    },
    {
      name: 'Logistic Regression',
      description: 'Linear model with logistic link function',
      hyperparameters: 'None (baseline)',
      strengths: 'Fast, interpretable coefficients',
    },
    {
      name: 'C5.0 Boosting',
      description: 'Rule-based boosting algorithm',
      hyperparameters: 'trials: 10, 20, 30',
      strengths: 'Efficient, handles categorical features well',
    },
  ];

  return (
    <div className="max-w-7xl mx-auto px-6 py-16">
      <div className="mb-16 flex flex-col md:flex-row md:items-center py-4 justify-between gap-6">
        <div>
          <h1 className="text-4xl font-bold tracking-tight mb-4">Model Training</h1>
          <p className="text-neutral-600 max-w-2xl">
            Multi-model training with hyperparameter tuning and automatic selection based on F1 score.
          </p>
        </div>
        <button
          onClick={() => setShowConfirmDialog(true)}
          disabled={isTraining}
          className="px-6 py-3 bg-black text-white text-sm font-medium hover:opacity-80 transition-opacity disabled:opacity-50 cursor-pointer"
        >
          {isTraining ? 'Training...' : 'Train New Model'}
        </button>
      </div>

      {/* Confirmation Dialog */}
      {showConfirmDialog && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-6">
          <div className="bg-white max-w-lg w-full p-6 rounded-md">
            <h2 className="text-xl font-bold mb-4">Confirm Training</h2>
            <p className="text-sm text-neutral-600 mb-4">
              You won&apos;t be able to use the model while it&apos;s training. Do you want to proceed?
            </p>
            <div className="flex justify-end gap-4">
              <button
                onClick={() => setShowConfirmDialog(false)}
                className="px-4 py-2 text-sm text-gray-600 bg-gray-100 rounded hover:bg-gray-200 cursor-pointer"
              >
                Cancel
              </button>
              <button
                onClick={handleTrain}
                className="px-4 py-2 text-sm text-white bg-black rounded hover:opacity-80 cursor-pointer"
              >
                Proceed
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Training Modal */}
      {showModal && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-6">
          <div className="bg-white max-w-2xl w-full max-h-[90vh] overflow-y-auto">
            <div className="p-8">
              <div className="flex items-center justify-between mb-6">
                <h2 className="text-2xl font-semibold">Model Training</h2>
                {!isTraining && (
                  <button
                    onClick={closeModal}
                    className="text-neutral-500 hover:text-black text-2xl leading-none cursor-pointer"
                  >
                    ×
                  </button>
                )}
              </div>

              {isTraining && (
                <div className="text-center py-12">
                  <div className="inline-block w-16 h-16 border-4 border-neutral-200 border-t-black rounded-full animate-spin mb-6"></div>
                  <h3 className="text-lg font-medium mb-2">Training in Progress</h3>
                  <p className="text-sm text-neutral-600 mb-4">
                    Running 4-stage ML pipeline...
                  </p>
                  <div className="space-y-2 text-sm text-neutral-500 text-left max-w-md mx-auto">
                    <div>→ Data Ingestion (MongoDB → Train/Test Split)</div>
                    <div>→ Data Validation (Schema + Drift Detection)</div>
                    <div>→ Data Transformation (KNN Imputation)</div>
                    <div>→ Model Training (5 algorithms with tuning)</div>
                  </div>
                </div>
              )}

              {trainingError && (
                <div className="border-2 border-red-500 bg-red-50 p-6">
                  <h3 className="font-semibold text-red-900 mb-2">Training Failed</h3>
                  <p className="text-sm text-red-800">{trainingError}</p>
                </div>
              )}

              {trainingResult && trainingResult.status === 'success' && (
                <div>
                  <div className="border-2 border-green-500 bg-green-50 p-6 mb-6">
                    <div className="text-center mb-4">
                      <div className="text-4xl mb-2">✓</div>
                      <h3 className="text-lg font-semibold text-green-900">Training Complete!</h3>
                    </div>
                  </div>

                  {/* Metrics Visualization */}
                  <div className="space-y-6">
                    <div>
                      <h3 className="font-medium mb-4">Training Metrics</h3>
                      <div className="space-y-3">
                        <div>
                          <div className="flex justify-between text-sm mb-1">
                            <span className="text-neutral-600">F1 Score</span>
                            <span className="font-mono font-medium">
                              {trainingResult.train_metrics?.f1.toFixed(4)}
                            </span>
                          </div>
                          <div className="w-full bg-neutral-200 h-2">
                            <div
                              className="bg-black h-2"
                              style={{ width: `${(trainingResult.train_metrics?.f1 || 0) * 100}%` }}
                            ></div>
                          </div>
                        </div>
                        <div>
                          <div className="flex justify-between text-sm mb-1">
                            <span className="text-neutral-600">Precision</span>
                            <span className="font-mono font-medium">
                              {trainingResult.train_metrics?.precision.toFixed(4)}
                            </span>
                          </div>
                          <div className="w-full bg-neutral-200 h-2">
                            <div
                              className="bg-black h-2"
                              style={{ width: `${(trainingResult.train_metrics?.precision || 0) * 100}%` }}
                            ></div>
                          </div>
                        </div>
                        <div>
                          <div className="flex justify-between text-sm mb-1">
                            <span className="text-neutral-600">Recall</span>
                            <span className="font-mono font-medium">
                              {trainingResult.train_metrics?.recall.toFixed(4)}
                            </span>
                          </div>
                          <div className="w-full bg-neutral-200 h-2">
                            <div
                              className="bg-black h-2"
                              style={{ width: `${(trainingResult.train_metrics?.recall || 0) * 100}%` }}
                            ></div>
                          </div>
                        </div>
                      </div>
                    </div>

                    <div>
                      <h3 className="font-medium mb-4">Test Metrics</h3>
                      <div className="space-y-3">
                        <div>
                          <div className="flex justify-between text-sm mb-1">
                            <span className="text-neutral-600">F1 Score</span>
                            <span className="font-mono font-medium">
                              {trainingResult.test_metrics?.f1.toFixed(4)}
                            </span>
                          </div>
                          <div className="w-full bg-neutral-200 h-2">
                            <div
                              className="bg-black h-2"
                              style={{ width: `${(trainingResult.test_metrics?.f1 || 0) * 100}%` }}
                            ></div>
                          </div>
                        </div>
                        <div>
                          <div className="flex justify-between text-sm mb-1">
                            <span className="text-neutral-600">Precision</span>
                            <span className="font-mono font-medium">
                              {trainingResult.test_metrics?.precision.toFixed(4)}
                            </span>
                          </div>
                          <div className="w-full bg-neutral-200 h-2">
                            <div
                              className="bg-black h-2"
                              style={{ width: `${(trainingResult.test_metrics?.precision || 0) * 100}%` }}
                            ></div>
                          </div>
                        </div>
                        <div>
                          <div className="flex justify-between text-sm mb-1">
                            <span className="text-neutral-600">Recall</span>
                            <span className="font-mono font-medium">
                              {trainingResult.test_metrics?.recall.toFixed(4)}
                            </span>
                          </div>
                          <div className="w-full bg-neutral-200 h-2">
                            <div
                              className="bg-black h-2"
                              style={{ width: `${(trainingResult.test_metrics?.recall || 0) * 100}%` }}
                            ></div>
                          </div>
                        </div>
                      </div>
                    </div>

                    {/* Comparison */}
                    <div className="border border-neutral-200 p-4 bg-neutral-50">
                      <h4 className="text-sm font-medium mb-3">Train vs Test Comparison</h4>
                      <div className="grid grid-cols-3 gap-4 text-center text-sm">
                        <div>
                          <div className="text-neutral-500 mb-1">F1 Diff</div>
                          <div className="font-mono font-medium">
                            {Math.abs((trainingResult.train_metrics?.f1 || 0) - (trainingResult.test_metrics?.f1 || 0)).toFixed(4)}
                          </div>
                        </div>
                        <div>
                          <div className="text-neutral-500 mb-1">Precision Diff</div>
                          <div className="font-mono font-medium">
                            {Math.abs((trainingResult.train_metrics?.precision || 0) - (trainingResult.test_metrics?.precision || 0)).toFixed(4)}
                          </div>
                        </div>
                        <div>
                          <div className="text-neutral-500 mb-1">Recall Diff</div>
                          <div className="font-mono font-medium">
                            {Math.abs((trainingResult.train_metrics?.recall || 0) - (trainingResult.test_metrics?.recall || 0)).toFixed(4)}
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>

                  <button
                    onClick={closeModal}
                    className="w-full mt-6 px-6 py-3 bg-black text-white text-sm font-medium hover:opacity-80 transition-opacity cursor-pointer"
                  >
                    Close
                  </button>
                </div>
              )}
            </div>
          </div>
        </div>
      )}

      {/* Current Model Performance */}
      {modelInfo && modelInfo.status === 'success' && (
        <div className="mb-16 border border-neutral-200 p-8">
          <h2 className="text-2xl font-semibold mb-6">Current Model</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
            <div>
              <div className="text-sm text-neutral-500 mb-2">Selected Algorithm</div>
              <div className="text-3xl font-bold mb-6">{modelInfo.model_name}</div>
              <div className="text-sm text-neutral-500">
                Trained: {modelInfo.trained_at}
              </div>
            </div>
            <div className="space-y-4">
              <div className="flex justify-between items-center pb-3 border-b border-neutral-200">
                <span className="text-sm text-neutral-600">Test F1 Score</span>
                <span className="text-lg font-semibold">{modelInfo.test_f1?.toFixed(4)}</span>
              </div>
              <div className="flex justify-between items-center pb-3 border-b border-neutral-200">
                <span className="text-sm text-neutral-600">Test Precision</span>
                <span className="text-lg font-semibold">{modelInfo.test_precision?.toFixed(4)}</span>
              </div>
              <div className="flex justify-between items-center pb-3 border-b border-neutral-200">
                <span className="text-sm text-neutral-600">Test Recall</span>
                <span className="text-lg font-semibold">{modelInfo.test_recall?.toFixed(4)}</span>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Training Process */}
      <div className="mb-16">
        <h2 className="text-2xl font-semibold mb-6">Training Process</h2>
        <div className="space-y-4">
          <div className="border border-neutral-200 p-6">
            <h3 className="font-medium mb-2">1. Model Training</h3>
            <p className="text-sm text-neutral-600">
              Each model is trained using caret::train() with 3-fold cross-validation. Hyperparameters are tuned via grid search to find optimal configurations.
            </p>
          </div>
          <div className="border border-neutral-200 p-6">
            <h3 className="font-medium mb-2">2. Evaluation</h3>
            <p className="text-sm text-neutral-600">
              Models are evaluated on the test set using F1 score, precision, and recall. F1 score balances precision and recall, making it ideal for imbalanced datasets.
            </p>
          </div>
          <div className="border border-neutral-200 p-6">
            <h3 className="font-medium mb-2">3. Selection</h3>
            <p className="text-sm text-neutral-600">
              The model with the highest F1 score on the test set is selected as the final model and saved to final_model/ directory for inference.
            </p>
          </div>
          <div className="border border-neutral-200 p-6">
            <h3 className="font-medium mb-2">4. Experiment Tracking</h3>
            <p className="text-sm text-neutral-600">
              All training runs are logged to mlruns/ folder with timestamps, model names, and performance metrics for reproducibility.
            </p>
          </div>
        </div>
      </div>

      {/* Models Grid */}
      <div className="mb-16">
        <h2 className="text-2xl font-semibold mb-6">Candidate Models</h2>
        <div className="space-y-6">
          {models.map((model) => (
            <div key={model.name} className="border border-neutral-200 p-6">
              <h3 className="text-lg font-semibold mb-2">{model.name}</h3>
              <p className="text-sm text-neutral-600 mb-4">{model.description}</p>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
                <div>
                  <span className="text-neutral-500">Hyperparameters: </span>
                  <span className="font-mono text-xs">{model.hyperparameters}</span>
                </div>
                <div>
                  <span className="text-neutral-500">Strengths: </span>
                  <span>{model.strengths}</span>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Metrics Explanation */}
      <div className="border border-neutral-200 p-8">
        <h2 className="text-2xl font-semibold mb-6">Evaluation Metrics</h2>
        <div className="space-y-6">
          <div>
            <h3 className="font-medium mb-2">F1 Score</h3>
            <p className="text-sm text-neutral-600 mb-2">
              Harmonic mean of precision and recall. Ranges from 0 to 1, where 1 is perfect.
            </p>
            <code className="text-xs bg-neutral-100 px-2 py-1 font-mono">
              F1 = 2 × (Precision × Recall) / (Precision + Recall)
            </code>
          </div>
          <div>
            <h3 className="font-medium mb-2">Precision</h3>
            <p className="text-sm text-neutral-600">
              Proportion of predicted phishing URLs that are actually phishing. High precision means few false positives.
            </p>
          </div>
          <div>
            <h3 className="font-medium mb-2">Recall</h3>
            <p className="text-sm text-neutral-600">
              Proportion of actual phishing URLs that are correctly identified. High recall means few false negatives.
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}
