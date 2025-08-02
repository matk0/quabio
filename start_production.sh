#!/bin/bash

# Production startup script for Railway deployment
echo "🧬 Starting MITO production server..."

# Check if RAG system needs initialization
echo "📊 Checking RAG system status..."
python -c "
import os
from app.rag.vector_store import MitoVectorStore

try:
    vs = MitoVectorStore(persist_directory='/app/chroma_db')
    stats = vs.get_stats()
    doc_count = stats.get('document_count', 0)
    
    if doc_count == 0:
        print('❌ RAG system not initialized. Document count: 0')
        print('🔨 Initializing RAG system...')
        exit(1)  # Trigger setup
    else:
        print(f'✅ RAG system ready. Document count: {doc_count}')
        exit(0)  # Skip setup
except Exception as e:
    print(f'❌ Error checking RAG system: {e}')
    print('🔨 Initializing RAG system...')
    exit(1)  # Trigger setup
"

# If exit code is 1, run setup
if [ $? -eq 1 ]; then
    echo "🔨 Running RAG setup..."
    python setup_rag.py
    
    if [ $? -eq 0 ]; then
        echo "✅ RAG setup completed successfully"
    else
        echo "❌ RAG setup failed"
        exit 1
    fi
fi

# Start the FastAPI server
echo "🚀 Starting FastAPI server..."
exec uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}