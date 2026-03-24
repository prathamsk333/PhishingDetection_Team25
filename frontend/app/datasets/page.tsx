'use client';

import { useEffect, useState } from 'react';
import { api, type DataSplitsResult } from '@/lib/api';

export default function Datasets() {
  const [data, setData] = useState<DataSplitsResult | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [activeTab, setActiveTab] = useState<'train' | 'test'>('train');
  const [limit, setLimit] = useState(100);

  const loadData = async () => {
    setLoading(true);
    setError(null);
    try {
      const result = await api.getDataSplits('all', limit);
      setData(result);
    } catch (err: any) {
      setError(err.message || 'Failed to load dataset splits');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadData();
  }, [limit]);

  const currentSplit = activeTab === 'train' ? data?.train : data?.test;
  const features = currentSplit?.data && currentSplit.data.length > 0 
    ? Object.keys(currentSplit.data[0]) 
    : [];

  return (
    <div className="max-w-7xl mx-auto px-6 py-16">
      <div className="mb-12">
        <h1 className="text-4xl font-bold tracking-tight mb-4">Dataset Viewer</h1>
        <p className="text-neutral-600 max-w-2xl">
          Browse the training and test datasets used for model training and evaluation.
        </p>
      </div>

      {error && (
        <div className="mb-8 border-2 border-red-500 bg-red-50 p-6">
          <h3 className="font-semibold text-red-900 mb-2">⚠️ Error</h3>
          <p className="text-sm text-red-800">{error}</p>
        </div>
      )}

      {loading ? (
        <div className="text-center py-12">
          <div className="text-neutral-600">Loading datasets...</div>
        </div>
      ) : data ? (
        <>
          {/* Controls */}
          <div className="mb-6 flex flex-col md:flex-row md:items-center justify-between gap-4">
            <div className="flex gap-4 border-b border-neutral-200 w-full md:w-auto overflow-x-auto">
              <button
                onClick={() => setActiveTab('train')}
                className={`pb-3 px-1 text-sm font-medium transition-colors ${
                  activeTab === 'train'
                    ? 'border-b-2 border-black text-black'
                    : 'text-neutral-500 hover:text-black'
                }`}
              >
                Training Data
                {data.train && (
                  <span className="ml-2 text-xs text-neutral-500">
                    ({data.train.returned_rows} of {data.train.total_rows})
                  </span>
                )}
              </button>
              <button
                onClick={() => setActiveTab('test')}
                className={`pb-3 px-1 text-sm font-medium transition-colors ${
                  activeTab === 'test'
                    ? 'border-b-2 border-black text-black'
                    : 'text-neutral-500 hover:text-black'
                }`}
              >
                Test Data
                {data.test && (
                  <span className="ml-2 text-xs text-neutral-500">
                    ({data.test.returned_rows} of {data.test.total_rows})
                  </span>
                )}
              </button>
            </div>

            <div className="flex items-center gap-3">
              <label className="text-sm text-neutral-600">Rows:</label>
              <select
                value={limit}
                onChange={(e) => setLimit(parseInt(e.target.value))}
                className="border border-neutral-300 px-3 py-1 text-sm focus:outline-none focus:border-black"
              >
                <option value={10}>10</option>
                <option value={50}>50</option>
                <option value={100}>100</option>
                <option value={500}>500</option>
                <option value={1000}>1000</option>
              </select>
              <button
                onClick={loadData}
                className="px-4 py-1 bg-black text-white text-sm hover:opacity-80 transition-opacity"
              >
                Refresh
              </button>
            </div>
          </div>

          {/* Info */}
          {currentSplit && (
            <div className="mb-6 p-4 bg-neutral-50 border border-neutral-200 text-sm">
              <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                <div>
                  <div className="text-neutral-500">Artifact</div>
                  <div className="font-mono text-xs">{data.artifact}</div>
                </div>
                <div>
                  <div className="text-neutral-500">Source</div>
                  <div className="font-medium">{currentSplit.source}</div>
                </div>
                <div>
                  <div className="text-neutral-500">Total Rows</div>
                  <div className="font-medium">{currentSplit.total_rows.toLocaleString()}</div>
                </div>
                <div>
                  <div className="text-neutral-500">Showing</div>
                  <div className="font-medium">{currentSplit.returned_rows.toLocaleString()}</div>
                </div>
              </div>
            </div>
          )}

          {/* Data Table */}
          {currentSplit && currentSplit.data.length > 0 ? (
            <div className="border border-neutral-200 overflow-hidden">
              <div className="overflow-x-auto">
                <table className="w-full text-xs">
                  <thead className="bg-neutral-50 border-b border-neutral-200">
                    <tr>
                      <th className="px-3 py-2 text-left font-medium sticky left-0 bg-neutral-50">#</th>
                      {features.map((feature) => (
                        <th key={feature} className="px-3 py-2 text-left font-medium whitespace-nowrap">
                          {feature}
                        </th>
                      ))}
                    </tr>
                  </thead>
                  <tbody>
                    {currentSplit.data.map((row, idx) => (
                      <tr 
                        key={idx} 
                        className={idx % 2 === 0 ? 'bg-white' : 'bg-neutral-50'}
                      >
                        <td className="px-3 py-2 text-neutral-500 sticky left-0 bg-inherit">{idx + 1}</td>
                        {features.map((feature) => (
                          <td 
                            key={feature} 
                            className={`px-3 py-2 font-mono ${
                              feature === 'Result' 
                                ? row[feature] === -1 || row[feature] === 1
                                  ? row[feature] === -1 
                                    ? 'text-red-600 font-semibold' 
                                    : 'text-green-600 font-semibold'
                                  : ''
                                : ''
                            }`}
                          >
                            {row[feature] !== null && row[feature] !== undefined ? row[feature].toString() : '-'}
                          </td>
                        ))}
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          ) : (
            <div className="text-center py-12 border border-neutral-200">
              <div className="text-neutral-500">No data available for this split</div>
            </div>
          )}
        </>
      ) : null}
    </div>
  );
}
