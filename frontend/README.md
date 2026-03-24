# Phishing Detection Frontend

A minimalist Next.js frontend for the Network Security Phishing Detection ML system.

## Features

- **Playground**: Interactive test data generation and real-time prediction
- **Pipeline**: Visual explanation of the 4-stage ML pipeline
- **Model**: Model training process and performance metrics
- **API Docs**: Complete REST API documentation

## Getting Started

1. **Install dependencies**:
   ```bash
   npm install
   ```

2. **Start the development server**:
   ```bash
   npm run dev
   ```

3. **Open in browser**:
   ```
   http://localhost:3000
   ```

## Prerequisites

- Node.js 18+ 
- R API server running on `http://localhost:8000`

## Environment Variables

Create a `.env.local` file:

```env
NEXT_PUBLIC_API_URL=http://localhost:8000
```

## Tech Stack

- Next.js 14 (App Router)
- TypeScript
- Tailwind CSS
- Inter font (Vercel design system)

## Design Philosophy

Minimalist monochrome aesthetic inspired by Vercel:
- Pure white background with deep black text
- High contrast, clean visual hierarchy
- Typography-first approach
- Generous whitespace
- Subtle micro-interactions

## Project Structure

```
app/
├── page.tsx              # Home/Dashboard
├── playground/page.tsx   # Test data generator & predictor
├── pipeline/page.tsx     # Pipeline explanation
├── model/page.tsx        # Model training details
├── api-docs/page.tsx     # API documentation
└── layout.tsx            # Shared layout with navigation

lib/
└── api.ts                # API client functions
```

## API Integration

The frontend connects to the R Plumber API running on port 8000. Make sure the API server is running before starting the frontend.

Start the R API:
```bash
cd ..
Rscript server.R
```

## Build for Production

```bash
npm run build
npm start
```

## License

MIT
