'use client';

import { useEffect, useState } from 'react';
import { api, type Feature, type FeatureData } from '@/lib/api';

export default function Playground() {
  const [features, setFeatures] = useState<Feature[]>([]);
  const [data, setData] = useState<FeatureData>({});
  const [prediction, setPrediction] = useState<number | null>(null);
  const [loading, setLoading] = useState(false);
  const [activeTab, setActiveTab] = useState<'generate' | 'manual'>('generate');
  const [error, setError] = useState<string | null>(null);
  const [dataSource, setDataSource] = useState<string | null>(null);

  useEffect(() => {
    api.getFeatureSchema()
      .then((res) => {
        setFeatures(res.features);
        // Initialize data with all features set to 0
        const initialData: FeatureData = {};
        res.features.forEach((f) => {
          initialData[f.name] = 0;
        });
        setData(initialData);
        setError(null);
      })
      .catch((err) => {
        console.error('Failed to load features:', err);
        setError('Failed to connect to API server. Make sure the R server is running on port 8000.');
      });
  }, []);

  const handleGenerate = async (type: 'random' | 'phishing' | 'legitimate') => {
    setLoading(true);
    setPrediction(null);
    try {
      const result = await api.generateTestData(type, 1);
      let generatedData = Array.isArray(result.data) ? result.data[0] : result.data;
      
      // Flatten any array values and ensure all values are 0 or 1
      const flattenedData: FeatureData = {};
      Object.entries(generatedData).forEach(([key, value]) => {
        let numValue = Array.isArray(value) ? value[0] : value;
        // Keep -1, 0, and 1 exact feature state values as provided by backend
        flattenedData[key] = numValue;
      });
      
      console.log('Generated data:', flattenedData);
      console.log('Number of features:', Object.keys(flattenedData).length);
      setData(flattenedData);
      setDataSource(result.source || null);
    } catch (error) {
      console.error('Generation failed:', error);
    } finally {
      setLoading(false);
    }
  };

  const handlePredict = async () => {
    setLoading(true);
    try {
      const result = await api.predict(data);
      const pred = Array.isArray(result.prediction) ? result.prediction[0] : result.prediction;
      setPrediction(pred);
    } catch (error) {
      console.error('Prediction failed:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleValueChange = (featureName: string, value: number) => {
    setData((prev) => ({ ...prev, [featureName]: value }));
    setPrediction(null);
  };

  return (
    <div className="max-w-7xl mx-auto px-6 py-16">
      <div className="mb-12">
        <h1 className="text-4xl font-bold tracking-tight mb-4">Playground</h1>
        <p className="text-neutral-600 max-w-2xl">
          Generate test data or manually configure features to test the phishing detection model in real-time.
        </p>
      </div>

      {/* Error Message */}
      {error && (
        <div className="mb-8 border-2 border-red-500 bg-red-50 p-6">
          <h3 className="font-semibold text-red-900 mb-2">⚠️ Connection Error</h3>
          <p className="text-sm text-red-800 mb-4">{error}</p>
          <div className="text-sm text-red-700">
            <p className="mb-2">To start the R API server:</p>
            <code className="bg-red-100 px-2 py-1 font-mono text-xs block">Rscript server.R</code>
          </div>
        </div>
      )}

      {/* Tabs */}
      <div className="flex gap-4 mb-8 border-b border-neutral-200">
        <button
          onClick={() => setActiveTab('generate')}
          className={`pb-3 px-1 text-sm font-medium transition-colors ${
            activeTab === 'generate'
              ? 'border-b-2 border-black text-black'
              : 'text-neutral-500 hover:text-black'
          }`}
        >
          Generate Data
        </button>
        <button
          onClick={() => setActiveTab('manual')}
          className={`pb-3 px-1 text-sm font-medium transition-colors ${
            activeTab === 'manual'
              ? 'border-b-2 border-black text-black'
              : 'text-neutral-500 hover:text-black'
          }`}
        >
          Manual Entry
        </button>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        {/* Left Panel - Controls */}
        <div className="lg:col-span-1">
          {activeTab === 'generate' && (
            <div className="space-y-4">
              {dataSource === 'real_dataset' && (
                <div className="p-3 bg-green-50 border border-green-200 text-sm text-green-800">
                  ✓ Using real examples from training dataset
                </div>
              )}
              
              <div className="border border-neutral-200 p-6">
                <h3 className="font-medium mb-4">Generate Example</h3>
                <p className="text-sm text-neutral-600 mb-6">
                  Select a profile type to load a real example from the training dataset
                </p>
                <div className="space-y-3">
                  <button
                    onClick={() => handleGenerate('phishing')}
                    disabled={loading}
                    className="w-full px-6 py-4 bg-red-50 border-2 border-red-200 hover:border-red-400 hover:bg-red-100 transition-all disabled:opacity-50 disabled:cursor-not-allowed cursor-pointer text-left group"
                  >
                    <div className="flex items-center justify-between">
                      <div>
                        <div className="font-semibold text-red-900 mb-1">🚨 Phishing Example</div>
                        <div className="text-xs text-red-700">Load a malicious URL pattern</div>
                      </div>
                      <div className="text-red-400 group-hover:text-red-600 transition-colors">→</div>
                    </div>
                  </button>
                  
                  <button
                    onClick={() => handleGenerate('legitimate')}
                    disabled={loading}
                    className="w-full px-6 py-4 bg-green-50 border-2 border-green-200 hover:border-green-400 hover:bg-green-100 transition-all disabled:opacity-50 disabled:cursor-not-allowed cursor-pointer text-left group"
                  >
                    <div className="flex items-center justify-between">
                      <div>
                        <div className="font-semibold text-green-900 mb-1">✓ Legitimate Example</div>
                        <div className="text-xs text-green-700">Load a safe URL pattern</div>
                      </div>
                      <div className="text-green-400 group-hover:text-green-600 transition-colors">→</div>
                    </div>
                  </button>
                  
                  <button
                    onClick={() => handleGenerate('random')}
                    disabled={loading}
                    className="w-full px-6 py-4 bg-neutral-50 border-2 border-neutral-200 hover:border-neutral-400 hover:bg-neutral-100 transition-all disabled:opacity-50 disabled:cursor-not-allowed cursor-pointer text-left group"
                  >
                    <div className="flex items-center justify-between">
                      <div>
                        <div className="font-semibold text-neutral-900 mb-1">🎲 Random Example</div>
                        <div className="text-xs text-neutral-600">Load any random URL</div>
                      </div>
                      <div className="text-neutral-400 group-hover:text-neutral-600 transition-colors">→</div>
                    </div>
                  </button>
                </div>
              </div>
            </div>
          )}

          {activeTab === 'manual' && (
            <div className="border border-neutral-200 p-6">
              <h3 className="font-medium mb-2">Manual Configuration</h3>
              <p className="text-sm text-neutral-600 mb-4">
                Edit feature values in the table to the right. Use values -1, 0, or 1 depending on the feature state.
              </p>
            </div>
          )}

          {/* Prediction Button */}
          <button
            onClick={handlePredict}
            disabled={loading}
            className="w-full px-6 py-3 bg-black text-white text-sm font-medium hover:opacity-80 transition-opacity disabled:opacity-50 disabled:cursor-not-allowed cursor-pointer mt-4"
          >
            {loading ? 'Processing...' : 'Predict'}
          </button>

          {/* Result */}
          {prediction !== null && (
            <div className={`mt-4 p-6 border-2 ${prediction === 0 ? 'border-red-500 bg-red-50' : 'border-green-500 bg-green-50'}`}>
              <div className="text-center">
                <div className="text-3xl mb-2">{prediction === 0 ? '🚨' : '✅'}</div>
                <div className="text-lg font-semibold">
                  {prediction === 0 ? 'PHISHING' : 'LEGITIMATE'}
                </div>
                <div className="text-sm text-neutral-600 mt-1">
                  {prediction === 0 ? 'Malicious URL detected' : 'Safe URL detected'}
                </div>
              </div>
            </div>
          )}
        </div>

        {/* Right Panel - Data Table */}
        <div className="lg:col-span-2">
          <div className="border border-neutral-200">
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead className="border-b border-neutral-200 bg-neutral-50">
                  <tr>
                    <th className="text-left px-4 py-3 font-medium">Feature</th>
                    <th className="text-left px-4 py-3 font-medium">Value</th>
                    <th className="text-left px-4 py-3 font-medium">Description</th>
                  </tr>
                </thead>
                <tbody>
                  {features.map((feature, idx) => (
                    <tr 
                      key={feature.name} 
                      className={idx % 2 === 0 ? 'bg-white' : 'bg-neutral-50'}
                    >
                      <td className="px-4 py-3 font-mono text-xs">{feature.name}</td>
                      <td className="px-4 py-3">
                        <select
                          value={data[feature.name] !== undefined ? data[feature.name] : 0}
                          onChange={(e) => handleValueChange(feature.name, parseInt(e.target.value))}
                          className="border border-neutral-300 px-2 py-1 text-sm focus:outline-none focus:border-black"
                        >
                          <option value={-1}>-1</option>
                          <option value={0}>0</option>
                          <option value={1}>1</option>
                        </select>
                      </td>
                      <td className="px-4 py-3 text-neutral-600 text-xs">{feature.description}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
