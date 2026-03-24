'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import { api, type HealthStatus, type ModelInfo } from '@/lib/api';

export default function Home() {
  const [health, setHealth] = useState<HealthStatus | null>(null);
  const [modelInfo, setModelInfo] = useState<ModelInfo | null>(null);

  useEffect(() => {
    api.getHealth().then(setHealth).catch(console.error);
    api.getModelInfo().then(setModelInfo).catch(console.error);
  }, []);

  return (
    <div className="max-w-7xl mx-auto px-6 py-16">
      {/* Hero Section */}
      <div className="max-w-3xl mb-24">
        <h1 className="text-5xl font-bold tracking-tight mb-6 leading-tight">
          ML-Powered Phishing Detection System
        </h1>
        <p className="text-lg text-neutral-600 leading-relaxed mb-8">
          An end-to-end machine learning pipeline for detecting phishing URLs using 31 behavioral and structural features. Built with R and deployed as a production-ready REST API.
        </p>
        <div className="flex gap-4">
          <Link
            href="/playground"
            className="px-6 py-3 bg-black text-white text-sm font-medium hover:opacity-80 transition-opacity"
          >
            Try Playground
          </Link>
          <Link
            href="/pipeline"
            className="px-6 py-3 border border-neutral-300 text-sm font-medium hover:border-black transition-colors"
          >
            View Pipeline
          </Link>
        </div>
      </div>

      {/* Status Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-24">
        <div className="border border-neutral-200 p-6">
          <h3 className="text-sm font-medium text-neutral-500 mb-4">System Status</h3>
          {health ? (
            <div className="space-y-3">
              <div className="flex justify-between items-center">
                <span className="text-sm text-neutral-600">Server</span>
                <span className="text-sm font-medium">{health.status === 'healthy' ? '● Online' : '○ Offline'}</span>
              </div>
              <div className="flex justify-between items-center">
                <span className="text-sm text-neutral-600">Model</span>
                <span className="text-sm font-medium">{health.model_loaded ? '● Loaded' : '○ Not Loaded'}</span>
              </div>
              <div className="flex justify-between items-center">
                <span className="text-sm text-neutral-600">Version</span>
                <span className="text-sm font-medium">{health.version}</span>
              </div>
            </div>
          ) : (
            <p className="text-sm text-neutral-400">Loading...</p>
          )}
        </div>

        <div className="border border-neutral-200 p-6">
          <h3 className="text-sm font-medium text-neutral-500 mb-4">Model Performance</h3>
          {modelInfo && modelInfo.status === 'success' ? (
            <div className="space-y-3">
              <div className="flex justify-between items-center">
                <span className="text-sm text-neutral-600">Algorithm</span>
                <span className="text-sm font-medium">{modelInfo.model_name}</span>
              </div>
              <div className="flex justify-between items-center">
                <span className="text-sm text-neutral-600">Test F1 Score</span>
                <span className="text-sm font-medium">
                  {typeof modelInfo.test_f1 === 'number'
                    ? modelInfo.test_f1.toFixed(4)
                    : (Number(modelInfo.test_f1)
                        ? Number(modelInfo.test_f1).toFixed(4)
                        : 'N/A')}
                </span>
              </div>
              <div className="flex justify-between items-center">
                <span className="text-sm text-neutral-600">Test Precision</span>
                <span className="text-sm font-medium">
                  {typeof modelInfo.test_precision === 'number'
                    ? modelInfo.test_precision.toFixed(4)
                    : (Number(modelInfo.test_precision)
                        ? Number(modelInfo.test_precision).toFixed(4)
                        : 'N/A')}
                </span>
              </div>
            </div>
          ) : (
            <p className="text-sm text-neutral-400">Model not trained</p>
          )}
        </div>
      </div>

      {/* Features Grid */}
      <div className="mb-24">
        <h2 className="text-2xl font-semibold mb-8">Key Features</h2>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          <div className="border border-neutral-200 p-6">
            <h3 className="font-medium mb-2">Real-time Detection</h3>
            <p className="text-sm text-neutral-600 leading-relaxed">
              Instant phishing classification using 31 URL and page features with sub-second response times.
            </p>
          </div>
          <div className="border border-neutral-200 p-6">
            <h3 className="font-medium mb-2">Multi-Model Training</h3>
            <p className="text-sm text-neutral-600 leading-relaxed">
              Trains 5 algorithms with hyperparameter tuning and selects the best performer by F1 score.
            </p>
          </div>
          <div className="border border-neutral-200 p-6">
            <h3 className="font-medium mb-2">Production Ready</h3>
            <p className="text-sm text-neutral-600 leading-relaxed">
              Complete ML pipeline with data validation, drift detection, and experiment tracking.
            </p>
          </div>
        </div>
      </div>

      {/* Tech Stack */}
      <div>
        <h2 className="text-2xl font-semibold mb-8">Technology Stack</h2>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          {['R + caret', 'Plumber API', 'MongoDB', 'Docker', 'KNN Imputation', 'Random Forest', 'Next.js', 'TypeScript'].map((tech) => (
            <div key={tech} className="border border-neutral-200 px-4 py-3 text-center text-sm font-medium">
              {tech}
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
