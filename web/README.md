# RAG Dataset Visualizer

This is a web-based visualization tool for RAG (Retrieval-Augmented Generation) datasets in the EasyRAGBench.jl project.

## Project Structure

- `api/` - Julia backend API server
- `frontend/` - React frontend application

## Setup and Running

### Backend (Julia API)

1. Make sure you have Julia installed and the EasyRAGBench.jl package set up
2. Start the API server:

```bash
cd /path/to/EasyRAGBench.jl
julia --project=. web/api/server.jl
```

The server will start on port 9000.

### Frontend (React)

1. Make sure you have Node.js and npm installed
2. Install dependencies and start the development server:

```bash
cd /path/to/EasyRAGBench.jl/web/frontend
npm install
npm start
```

The React development server will start on port 3000 and should automatically open in your browser.

## Development

### API Endpoints

- `GET /api/datasets` - Get a list of all available datasets
- `GET /api/datasets/:id` - Get all documents for a specific dataset
- `GET /api/questions/:id` - Get all questions for a specific dataset
- `GET /api/configs/:index_id` - Get all available configurations for a dataset
- `GET /api/solutions/:index_id/:config_id` - Get solutions for a dataset with a specific configuration

### Adding Components

To add new components to the React frontend:

1. Create a new component file in `frontend/src/components/`
2. Import and use the component in `App.js`
