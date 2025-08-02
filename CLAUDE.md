# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

MITO is a Slovak health assistant RAG (Retrieval-Augmented Generation) chatbot specialized in health, epigenetics, and quantum biology. The application provides answers in Slovak based on a database of 179 specialized articles.

### Architecture

**Full-stack RAG Application:**
- **Backend**: FastAPI with LangChain, ChromaDB vector database, OpenAI GPT-4-turbo
- **Frontend**: React 18 with TypeScript, Tailwind CSS, Framer Motion
- **Data**: 179 Slovak JSON articles in `backend/data/articles/`
- **Vector DB**: ChromaDB persisted in `chroma_data/` directory

## Development Commands

### Backend Setup
```bash
cd backend
conda create -n mito-backend python=3.11
conda activate mito-backend
pip install -r requirements.txt

# Initialize RAG system - REQUIRED before first run
python setup_rag.py                    # Setup both variants (default)
python setup_rag.py --variant fixed    # Setup only fixed-size chunking
python setup_rag.py --variant semantic # Setup only semantic chunking
python setup_rag.py --force            # Force rebuild existing databases

uvicorn app.main:app --reload  # Start backend server on port 8000
```

### Frontend Setup
```bash
cd frontend
npm install
npm start    # Development server on port 3000
npm run build  # Production build
npm test     # Run tests
```

### Docker Development
```bash
docker-compose up --build  # Full stack development
docker-compose -f docker-compose.prod.yml up -d  # Production deployment
```

### RAG System Management
```bash
# Initialize or rebuild vector databases
python setup_rag.py --variant both     # Setup both variants
python setup_rag.py --variant semantic # Setup semantic chunking only
python setup_rag.py --force            # Force rebuild existing databases

# Backend debug endpoints for troubleshooting
curl http://localhost:8000/api/debug/rag
curl http://localhost:8000/api/health
curl http://localhost:8000/api/rag/variants  # List available variants
```

## Code Architecture

### Backend Structure (`backend/app/`)
- **`main.py`**: FastAPI application with CORS, serves React static files in production
- **`api/chat.py`**: Chat endpoints including comparison functionality, health checks, debug endpoints
- **`rag/chain.py`**: LangChain RAG implementation with Slovak-optimized prompts and variant support
- **`rag/vector_store.py`**: ChromaDB wrapper supporting multiple collections for different variants
- **`rag/data_processor.py`**: Processes Slovak JSON articles using pluggable chunking strategies
- **`rag/chunkers/`**: Chunking strategy implementations (fixed-size, semantic)
- **`rag/rag_factory.py`**: Factory for creating RAG services with different variants
- **`models/types.py`**: Pydantic models for API requests/responses including comparison types

### Frontend Structure (`frontend/src/`)
- **`App.tsx`**: Main app with React Query client setup
- **`components/ChatInterface.tsx`**: Main chat UI component with comparison support
- **`components/ComparisonView.tsx`**: Side-by-side display of variant responses
- **`hooks/useChat.ts`**: Custom hook for chat state management including comparison mode
- **`services/api.ts`**: API client for backend communication including comparison endpoints

### Key Features
- **Multi-Variant RAG**: Compare responses from fixed-size vs semantic chunking
- **Slovak Language Support**: Full Slovak interface with diacritical marks
- **Source Citation**: Every response includes relevant article sources with variant-specific chunking
- **Vector Search**: ChromaDB with OpenAI text-embedding-3-large embeddings
- **Session Management**: UUID-based chat sessions
- **Comparison UI**: Simple side-by-side display of different RAG variant responses
- **Debug Endpoints**: Production-ready debugging at `/api/debug/*`

## Environment Configuration

**Required Environment Variables:**
```bash
OPENAI_API_KEY=sk-...  # Required for LLM and embeddings
ENVIRONMENT=development|production
CHROMA_PERSIST_DIR=./chroma_db  # Vector database location
```

## Deployment

**Local Development:**
1. Set up backend with `setup_rag.py`
2. Start backend: `uvicorn app.main:app --reload`
3. Start frontend: `npm start`

**Docker Production:**
- Uses `docker-compose.prod.yml` for production builds
- Backend serves static frontend files
- Health checks and monitoring endpoints included

## Common Tasks

**Adding New Articles:**
1. Add JSON files to `backend/data/articles/`
2. Run `python setup_rag.py` to reindex
3. Restart backend server

**Modifying Slovak Prompts:**
Edit the system prompt in `backend/app/rag/chain.py:24-51` - contains specific instructions for Slovak health content presentation.

**API Endpoints:**
- `POST /api/chat` - Single variant response (backward compatible)
- `POST /api/chat/compare` - Compare responses from all variants
- `GET /api/rag/variants` - List available RAG variants
- `GET /api/health` - System health check
- `GET /api/stats` - RAG system statistics
- `GET /api/debug/rag` - Debug vector store status
- `GET /ping` - Simple monitoring endpoint

**Chunking Strategies:**
- **Fixed-Size**: 800 characters with 200 overlap, optimized for Slovak text
- **Semantic**: Sentence-level embeddings with similarity clustering (threshold 0.75)

**Vector Databases:**
- `chroma_db/` - Fixed-size chunking collection
- `chroma_db_semantic/` - Semantic chunking collection