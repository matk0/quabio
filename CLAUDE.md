# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a dual-stack RAG (Retrieval-Augmented Generation) application specialized in Slovak health, epigenetics, and quantum biology content:

- **Backend**: FastAPI Python application with LangChain RAG implementation (`/backend/`)
- **Frontend**: Rails 8 application (currently vanilla, no functionality) (`/mito/`)

## Common Development Commands

### Backend (FastAPI)

```bash
# Setup/Initialize RAG system with both chunking variants
cd backend
python setup_rag.py --variant both

# Run development server
uvicorn app.main:app --reload

# Run with Docker
docker-compose -f docker-compose.standalone.yml up
```

### Frontend (Rails)

```bash
# Setup
cd mito
bundle install
bin/rails db:create db:migrate

# Run development server with Tailwind CSS compilation
bin/dev
```

## Architecture

### RAG System Architecture

The backend implements a sophisticated multi-variant RAG system:

1. **Two Chunking Strategies**:
   - Fixed-size chunking (1000 tokens) - stored in `chroma_db/`
   - Semantic chunking (based on sentence embeddings) - stored in `chroma_db_semantic/`

2. **Factory Pattern** (`backend/app/rag/rag_factory.py`):
   - Creates RAG instances based on variant type
   - Supports comparison mode to query both variants

3. **API Endpoints** (`backend/app/api/v1/`):
   - `/chat` - Main chat endpoint supporting single variant or comparison mode
   - `/health` - Health check endpoint

4. **Data Source**: 190+ Slovak health articles in `backend/data/articles/`

### Key Backend Components

- `backend/app/rag/chain.py` - Core RAG chain implementation
- `backend/app/rag/vector_store.py` - ChromaDB vector store management
- `backend/app/rag/chunkers/` - Different chunking strategies
- `backend/app/models/` - Pydantic models for API requests/responses

### Frontend Status

The Rails application in `/mito/` is currently a vanilla Rails 8 setup with:
- Tailwind CSS configured
- PostgreSQL database
- No implemented functionality yet

## Environment Variables

Backend requires:
- `OPENAI_API_KEY` - For GPT-4 access
- CORS configuration supports multiple domains including `qua.bio` production domain

## Testing

Backend: No test framework currently configured (consider adding pytest)
Frontend: Rails comes with Minitest and system test setup ready

## Deployment

Backend supports Docker deployment with health checks and volume persistence for vector databases. The application is designed for production deployment on DigitalOcean and Vercel.