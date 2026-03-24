export default function ApiDocs() {
  const endpoints = [
    {
      method: 'GET',
      path: '/health',
      description: 'Check server status and model availability',
      response: {
        status: 'healthy',
        model_loaded: true,
        version: '1.0.0',
        timestamp: '2026-03-24 10:30:00',
      },
    },
    {
      method: 'GET',
      path: '/model/info',
      description: 'Get current model metadata and performance metrics',
      response: {
        status: 'success',
        model_name: 'Random Forest',
        train_f1: 0.9234,
        test_f1: 0.8876,
        trained_at: '2026-03-22 22:59:15',
      },
    },
    {
      method: 'GET',
      path: '/features/schema',
      description: 'Get all 31 feature names with descriptions',
      response: {
        status: 'success',
        features: [
          {
            name: 'having_IP_Address',
            description: 'URL uses IP address instead of domain name',
            type: 'binary',
          },
          '... (30 more features)',
        ],
      },
    },
    {
      method: 'GET',
      path: '/generate_test_data',
      description: 'Generate random test data for phishing detection',
      params: [
        { name: 'type', type: 'string', description: 'phishing | legitimate | random' },
        { name: 'count', type: 'number', description: '1-100 (default: 1)' },
      ],
      response: {
        status: 'success',
        type: 'phishing',
        count: 1,
        data: { having_IP_Address: -1, URL_Length: -1, '...': '...' },
      },
    },
    {
      method: 'POST',
      path: '/predict_json',
      description: 'Predict phishing status from JSON payload',
      body: {
        having_IP_Address: -1,
        URL_Length: -1,
        '... (all 31 features)': '...',
      },
      response: {
        status: 'success',
        prediction: 0,
      },
    },
    {
      method: 'POST',
      path: '/predict',
      description: 'Predict phishing status from uploaded CSV file',
      body: 'multipart/form-data with file field',
      response: {
        status: 'success',
        rows: 10,
        predictions: [1, 0, 1, 0, 0, 1, 1, 0, 1, 0],
        output_file: 'prediction_output/output.csv',
      },
    },
    {
      method: 'GET',
      path: '/train',
      description: 'Trigger the full ML training pipeline',
      response: {
        status: 'success',
        message: 'Training completed successfully.',
      },
    },
  ];

  return (
    <div className="max-w-7xl mx-auto px-6 py-16">
      <div className="mb-16">
        <h1 className="text-4xl font-bold tracking-tight mb-4">API Documentation</h1>
        <p className="text-neutral-600 max-w-2xl mb-6">
          REST API endpoints for phishing detection, model training, and test data generation.
        </p>
        <div className="flex items-center gap-4">
          <div className="text-sm">
            <span className="text-neutral-500">Base URL:</span>{' '}
            <code className="bg-neutral-100 px-2 py-1 font-mono text-xs">http://localhost:8000</code>
          </div>
          <a
            href="http://localhost:8000/__docs__/"
            target="_blank"
            rel="noopener noreferrer"
            className="text-sm text-neutral-600 hover:text-black underline"
          >
            View Swagger Docs →
          </a>
        </div>
      </div>

      {/* Endpoints */}
      <div className="space-y-8">
        {endpoints.map((endpoint, idx) => (
          <div key={idx} className="border border-neutral-200">
            <div className="p-6 border-b border-neutral-200 bg-neutral-50">
              <div className="flex items-center gap-4 mb-2">
                <span
                  className={`px-2 py-1 text-xs font-mono font-semibold ${
                    endpoint.method === 'GET'
                      ? 'bg-blue-100 text-blue-800'
                      : 'bg-green-100 text-green-800'
                  }`}
                >
                  {endpoint.method}
                </span>
                <code className="text-sm font-mono">{endpoint.path}</code>
              </div>
              <p className="text-sm text-neutral-600">{endpoint.description}</p>
            </div>

            <div className="p-6 space-y-4">
              {endpoint.params && (
                <div>
                  <h4 className="text-sm font-medium mb-2">Query Parameters</h4>
                  <div className="space-y-2">
                    {endpoint.params.map((param) => (
                      <div key={param.name} className="text-sm">
                        <code className="bg-neutral-100 px-2 py-1 font-mono text-xs">
                          {param.name}
                        </code>
                        <span className="text-neutral-500 mx-2">·</span>
                        <span className="text-neutral-600">{param.type}</span>
                        <span className="text-neutral-500 mx-2">·</span>
                        <span className="text-neutral-600">{param.description}</span>
                      </div>
                    ))}
                  </div>
                </div>
              )}

              {endpoint.body && (
                <div>
                  <h4 className="text-sm font-medium mb-2">Request Body</h4>
                  <pre className="bg-neutral-50 p-4 text-xs font-mono overflow-x-auto border border-neutral-200">
                    {typeof endpoint.body === 'string'
                      ? endpoint.body
                      : JSON.stringify(endpoint.body, null, 2)}
                  </pre>
                </div>
              )}

              <div>
                <h4 className="text-sm font-medium mb-2">Response</h4>
                <pre className="bg-neutral-50 p-4 text-xs font-mono overflow-x-auto border border-neutral-200">
                  {JSON.stringify(endpoint.response, null, 2)}
                </pre>
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Response Codes */}
      <div className="mt-16 border border-neutral-200 p-8">
        <h2 className="text-2xl font-semibold mb-6">Response Codes</h2>
        <div className="space-y-3 text-sm">
          <div className="flex items-center gap-4">
            <code className="bg-green-100 text-green-800 px-2 py-1 font-mono font-semibold">200</code>
            <span className="text-neutral-600">Success - Request completed successfully</span>
          </div>
          <div className="flex items-center gap-4">
            <code className="bg-yellow-100 text-yellow-800 px-2 py-1 font-mono font-semibold">400</code>
            <span className="text-neutral-600">Bad Request - Invalid parameters or missing data</span>
          </div>
          <div className="flex items-center gap-4">
            <code className="bg-red-100 text-red-800 px-2 py-1 font-mono font-semibold">404</code>
            <span className="text-neutral-600">Not Found - Model not trained or endpoint doesn't exist</span>
          </div>
          <div className="flex items-center gap-4">
            <code className="bg-red-100 text-red-800 px-2 py-1 font-mono font-semibold">500</code>
            <span className="text-neutral-600">Server Error - Internal processing error</span>
          </div>
        </div>
      </div>

      {/* CORS Notice */}
      <div className="mt-8 border border-neutral-200 p-6 bg-neutral-50">
        <h3 className="font-medium mb-2">CORS Enabled</h3>
        <p className="text-sm text-neutral-600">
          All endpoints support Cross-Origin Resource Sharing (CORS) for frontend integration.
        </p>
      </div>
    </div>
  );
}
