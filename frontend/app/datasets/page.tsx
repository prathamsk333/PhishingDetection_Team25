'use client';

import { useEffect, useState } from 'react';
import { api, type DataSplitsResult } from '@/lib/api';

export default function Datasets() {
  const [data, setData] = useState<DataSplitsResult | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [activeTab, setActiveTab] = useState<'train' | 'test'>('train');
  const [page, setPage] = useState(1);
  const [pageSize, setPageSize] = useState(20);
  const [exporting, setExporting] = useState(false);

  const scrollToTop = () => {
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  const loadData = async (newPage: number = page, newPageSize: number = pageSize) => {
    setLoading(true);
    setError(null);
    try {
      // Ensure page and pageSize are numbers and page is at least 1
      const pageNum = Math.max(1, Number(newPage));
      const pageSizeNum = Number(newPageSize);
      
      const result = await api.getDataSplits('all', pageNum, pageSizeNum);
      setData(result);
      setPage(pageNum);
      setPageSize(pageSizeNum);
    } catch (err: any) {
      setError(err.message || 'Failed to load dataset splits');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadData(1, 20);
  }, []);

  const handlePageSizeChange = (newSize: number) => {
    setPageSize(newSize);
    loadData(1, newSize);
  };

  const handleExport = async () => {
    setExporting(true);
    try {
      const blob = await api.exportDataSplit(activeTab);
      const url = window.URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `${activeTab}_data.csv`;
      document.body.appendChild(a);
      a.click();
      window.URL.revokeObjectURL(url);
      document.body.removeChild(a);
    } catch (err: any) {
      setError(err.message || 'Failed to export dataset');
    } finally {
      setExporting(false);
    }
  };

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

      {loading && !data ? (
        <div className="text-center py-12">
          <div className="text-neutral-600">Loading datasets...</div>
        </div>
      ) : data ? (
        <>
          {/* Controls */}
          <div className="mb-6 flex flex-col md:flex-row md:items-center justify-between gap-4">
            <div className="flex gap-4 border-b border-neutral-200 w-full md:w-auto overflow-x-auto">
              <button
                onClick={() => { setActiveTab('train'); setPage(1); loadData(1, pageSize); }}
                className={`pb-3 px-1 text-sm font-medium transition-colors cursor-pointer ${
                  activeTab === 'train'
                    ? 'border-b-2 border-black text-black'
                    : 'text-neutral-500 hover:text-black'
                }`}
              >
                Training Data
                {data.train && (
                  <span className="ml-2 text-xs text-neutral-500">
                    ({data.train.total_rows.toLocaleString()} rows)
                  </span>
                )}
              </button>
              <button
                onClick={() => { setActiveTab('test'); setPage(1); loadData(1, pageSize); }}
                className={`pb-3 px-1 text-sm font-medium transition-colors cursor-pointer ${
                  activeTab === 'test'
                    ? 'border-b-2 border-black text-black'
                    : 'text-neutral-500 hover:text-black'
                }`}
              >
                Test Data
                {data.test && (
                  <span className="ml-2 text-xs text-neutral-500">
                    ({data.test.total_rows.toLocaleString()} rows)
                  </span>
                )}
              </button>
            </div>

            <div className="flex items-center gap-3">
              <label className="text-sm text-neutral-600">Rows/page:</label>
              <select
                value={pageSize}
                onChange={(e) => handlePageSizeChange(parseInt(e.target.value))}
                className="border border-neutral-300 px-3 py-2 text-sm focus:outline-none focus:border-black cursor-pointer"
              >
                <option value={20}>20</option>
                <option value={50}>50</option>
                <option value={100}>100</option>
                <option value={200}>200</option>
                <option value={500}>500</option>
              </select>
              <button
                onClick={handleExport}
                disabled={exporting}
                className="px-4 py-2 bg-green-600 text-white text-sm hover:bg-green-700 transition-colors disabled:opacity-50 cursor-pointer"
              >
                {exporting ? 'Exporting...' : '↓ Export CSV'}
              </button>
            </div>
          </div>

          {/* Info */}
          {currentSplit && (
            <div className="mb-6 p-4 bg-neutral-50 border border-neutral-200 text-sm">
              <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                <div>
                  <div className="text-neutral-500">Artifact</div>
                  <div className="font-mono text-xs break-all">{data.artifact}</div>
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
                  <div className="text-neutral-500">Page Size</div>
                  <div className="font-medium">{currentSplit.page_size} rows/page</div>
                </div>
              </div>
            </div>
          )}

          {/* Data Table */}
          {currentSplit && currentSplit.data.length > 0 ? (
            <>
              <div className="border border-neutral-200 overflow-hidden">
                <div className="overflow-x-auto">
                  <table className="w-full text-xs">
                    <thead className="bg-neutral-50 border-b border-neutral-200">
                      <tr>
                        <th className="px-3 py-2 text-left font-medium sticky left-0 bg-neutral-50 z-10">#</th>
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
                          <td className="px-3 py-2 text-neutral-500 sticky left-0 bg-inherit z-10">
                            {(currentSplit.current_page - 1) * currentSplit.page_size + idx + 1}
                          </td>
                          {features.map((feature) => {
                            const value = row[feature];
                            const displayValue = value !== null && value !== undefined 
                              ? (typeof value === 'number' && !isNaN(value)) || typeof value === 'string'
                                ? value.toString()
                                : '-'
                              : '-';
                            
                            return (
                              <td 
                                key={feature} 
                                className={`px-3 py-2 font-mono ${
                                  feature === 'Result' 
                                    ? value === -1 
                                      ? 'text-red-600 font-semibold' 
                                      : value === 1
                                        ? 'text-green-600 font-semibold'
                                        : ''
                                    : ''
                                }`}
                              >
                                {displayValue}
                              </td>
                            );
                          })}
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>

              {/* Pagination */}
              <div className="mt-6 flex flex-col md:flex-row items-center justify-between gap-4 text-sm">
                <div className="text-neutral-600">
                  Page {currentSplit.current_page} of {currentSplit.total_pages} 
                  <span className="mx-2">·</span>
                  Showing {((currentSplit.current_page - 1) * currentSplit.page_size) + 1} - {Math.min(currentSplit.current_page * currentSplit.page_size, currentSplit.total_rows)} of {currentSplit.total_rows.toLocaleString()} rows
                </div>
                <div className="flex items-center gap-2">
                  <button
                    onClick={() => loadData(1, pageSize)}
                    disabled={currentSplit.current_page === 1 || loading}
                    className="px-3 py-1 border border-neutral-300 hover:bg-neutral-50 disabled:opacity-50 disabled:cursor-not-allowed cursor-pointer"
                  >
                    First
                  </button>
                  <button
                    onClick={() => loadData(Number(currentSplit.current_page) - 1, pageSize)}
                    disabled={currentSplit.current_page === 1 || loading}
                    className="px-3 py-1 border border-neutral-300 hover:bg-neutral-50 disabled:opacity-50 disabled:cursor-not-allowed cursor-pointer"
                  >
                    Previous
                  </button>
                  <button
                    onClick={() => loadData(Number(currentSplit.current_page) + 1, pageSize)}
                    disabled={currentSplit.current_page === currentSplit.total_pages || loading}
                    className="px-3 py-1 border border-neutral-300 hover:bg-neutral-50 disabled:opacity-50 disabled:cursor-not-allowed cursor-pointer"
                  >
                    Next
                  </button>
                  <button
                    onClick={() => loadData(currentSplit.total_pages, pageSize)}
                    disabled={currentSplit.current_page === currentSplit.total_pages || loading}
                    className="px-3 py-1 border border-neutral-300 hover:bg-neutral-50 disabled:opacity-50 disabled:cursor-not-allowed cursor-pointer"
                  >
                    Last
                  </button>
                </div>
              </div>

              {/* Scroll to Top Button - Only show when page size >= 100 */}
              {pageSize >= 100 && (
                <div className="mt-6 text-center">
                  <button
                    onClick={scrollToTop}
                    className="px-6 py-2 bg-neutral-800 text-white text-sm hover:bg-black transition-colors cursor-pointer"
                  >
                    ↑ Scroll to Top
                  </button>
                </div>
              )}
            </>
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
