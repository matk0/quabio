#!/usr/bin/env python3
"""
Setup script for MITO RAG system.
This script processes the Slovak articles and creates the vector database.
"""

import os
import sys
from dotenv import load_dotenv

# Add the app directory to Python path
sys.path.append(os.path.join(os.path.dirname(__file__), 'app'))

from app.rag.data_processor import SlovakArticleProcessor
from app.rag.vector_store import MitoVectorStore

def main():
    """Main setup function."""
    print("🧬 MITO RAG System Setup")
    print("=" * 50)
    
    # Load environment variables
    load_dotenv()
    
    # Check for OpenAI API key
    if not os.getenv('OPENAI_API_KEY'):
        print("❌ Error: OPENAI_API_KEY not found in environment variables")
        print("Please create a .env file with your OpenAI API key")
        return
    
    # Initialize data processor
    print("📚 Processing Slovak articles...")
    processor = SlovakArticleProcessor()
    
    # Get article statistics
    articles_path = "data/articles"
    stats = processor.get_article_stats(articles_path)
    print(f"📊 Found {stats['total_articles']} articles")
    print(f"📊 Total words: {stats['total_words']:,}")
    print(f"📊 Topics: {stats['topics']}")
    
    # Process articles into documents
    print("\n🔨 Creating document chunks...")
    documents = processor.process_articles(articles_path)
    
    if not documents:
        print("❌ No documents were processed. Check your articles directory.")
        return
    
    # Initialize vector store
    print("\n🗄️  Setting up vector database...")
    vector_store = MitoVectorStore(persist_directory="./chroma_db")
    
    # Check if vector store already has documents
    stats = vector_store.get_stats()
    if stats.get('document_count', 0) > 0:
        print(f"ℹ️  Vector store already contains {stats['document_count']} documents")
        overwrite = input("Do you want to overwrite? (y/N): ").lower()
        if overwrite == 'y':
            print("🗑️  Deleting existing collection...")
            vector_store.delete_collection()
            vector_store = MitoVectorStore(persist_directory="./chroma_db")
        else:
            print("✅ Keeping existing vector store")
            return
    
    # Add documents to vector store
    print(f"\n⚡ Adding {len(documents)} documents to vector store...")
    success = vector_store.add_documents(documents)
    
    if success:
        print("✅ RAG system setup complete!")
        print(f"📊 Vector store statistics: {vector_store.get_stats()}")
        print("\n🚀 You can now start the FastAPI server with:")
        print("   uvicorn app.main:app --reload")
    else:
        print("❌ Failed to setup RAG system")

if __name__ == "__main__":
    main()