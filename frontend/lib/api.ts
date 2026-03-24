const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

export interface Feature {
  name: string;
  description: string;
  type: string;
}

export interface FeatureData {
  [key: string]: number;
}

export interface PredictionResult {
  status: string;
  prediction: number | number[];
}

export interface ModelInfo {
  status: string;
  model_name: string;
  train_f1: number;
  train_precision: number;
  train_recall: number;
  test_f1: number;
  test_precision: number;
  test_recall: number;
  trained_at: string;
}

export interface HealthStatus {
  status: string;
  model_loaded: boolean;
  version: string;
  timestamp: string;
}

export interface GeneratedData {
  status: string;
  type: string;
  count: number;
  data: FeatureData | FeatureData[];
  source?: string;
}

export interface TrainingResult {
  status: string;
  message: string;
  model_name?: string;
  train_metrics?: {
    f1: number;
    precision: number;
    recall: number;
  };
  test_metrics?: {
    f1: number;
    precision: number;
    recall: number;
  };
  model_path?: string;
}

export interface DataSplit {
  split: string;
  source: string;
  total_rows: number;
  returned_rows: number;
  data: any[];
}

export interface DataSplitsResult {
  status: string;
  artifact: string;
  train?: DataSplit;
  test?: DataSplit;
}

export const api = {
  async getHealth(): Promise<HealthStatus> {
    try {
      const res = await fetch(`${API_BASE_URL}/health`);
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      return res.json();
    } catch (error) {
      console.error('API Error:', error);
      throw new Error('Failed to connect to API server. Make sure the R server is running on port 8000.');
    }
  },

  async getModelInfo(): Promise<ModelInfo> {
    try {
      const res = await fetch(`${API_BASE_URL}/model/info`);
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      return res.json();
    } catch (error) {
      console.error('API Error:', error);
      throw error;
    }
  },

  async getFeatureSchema(): Promise<{ status: string; features: Feature[] }> {
    try {
      const res = await fetch(`${API_BASE_URL}/features/schema`);
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      return res.json();
    } catch (error) {
      console.error('API Error:', error);
      throw new Error('Failed to connect to API server. Make sure the R server is running on port 8000.');
    }
  },

  async generateTestData(type: 'random' | 'phishing' | 'legitimate', count: number = 1): Promise<GeneratedData> {
    try {
      const res = await fetch(`${API_BASE_URL}/generate_test_data?type=${type}&count=${count}`);
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      return res.json();
    } catch (error) {
      console.error('API Error:', error);
      throw error;
    }
  },

  async predict(data: FeatureData | FeatureData[]): Promise<PredictionResult> {
    try {
      const res = await fetch(`${API_BASE_URL}/predict_json`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data),
      });
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      return res.json();
    } catch (error) {
      console.error('API Error:', error);
      throw error;
    }
  },

  async train(): Promise<TrainingResult> {
    try {
      const res = await fetch(`${API_BASE_URL}/train`);
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      return res.json();
    } catch (error) {
      console.error('API Error:', error);
      throw error;
    }
  },

  async getDataSplits(split: 'train' | 'test' | 'all' = 'all', limit: number = 100): Promise<DataSplitsResult> {
    try {
      const res = await fetch(`${API_BASE_URL}/data/splits?split=${split}&limit=${limit}`);
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      return res.json();
    } catch (error) {
      console.error('API Error:', error);
      throw error;
    }
  },
};
