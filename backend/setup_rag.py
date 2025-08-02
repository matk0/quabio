#!/usr/bin/env python3
"""
Setup script for MITO RAG system.
This script processes the Slovak articles and creates the vector database.
"""

import os
import sys
import argparse
from dotenv import load_dotenv

# Add the app directory to Python path
sys.path.append(os.path.join(os.path.dirname(__file__), 'app'))

from app.rag.data_processor import SlovakArticleProcessor
from app.rag.vector_store import MitoVectorStore
from app.rag.rag_factory import RAGServiceFactory
from app.models.types import RAGVariant

def setup_variant(variant: RAGVariant, articles_path: str, force_rebuild: bool = False):
    """Setup a specific RAG variant."""
    print(f"\n🔧 Setting up {RAGServiceFactory.get_variant_display_name(variant)} variant...")
    
    # Create chunker for this variant
    chunker = RAGServiceFactory.create_chunker(variant)
    
    # Initialize data processor with the chunker
    processor = SlovakArticleProcessor(chunker)
    
    # Process articles into documents
    print(f"🔨 Creating document chunks using {chunker.get_chunker_name()} strategy...")
    
    # Show detailed progress for semantic chunking
    if variant == RAGVariant.SEMANTIC:
        print("⚠️  SEMANTIC CHUNKING: This process generates embeddings for each sentence and may take several minutes...")
        print("📊 Progress will be shown for each article below:")
    
    documents = processor.process_articles(articles_path)
    
    if not documents:
        print(f"❌ No documents were processed for {variant.value} variant")
        return False
    
    # Initialize vector store for this variant
    print(f"🗄️  Setting up vector database for {variant.value} variant...")
    if variant == RAGVariant.SEMANTIC:
        persist_dir = "./chroma_db_semantic"
    else:
        persist_dir = "./chroma_db"
    
    vector_store = MitoVectorStore(persist_directory=persist_dir, variant=variant.value)
    
    # Check if vector store already has documents
    stats = vector_store.get_stats()
    if stats.get('document_count', 0) > 0 and not force_rebuild:
        print(f"ℹ️  Vector store for {variant.value} already contains {stats['document_count']} documents")
        return True
    elif stats.get('document_count', 0) > 0 and force_rebuild:
        print(f"🗑️  Deleting existing {variant.value} collection...")
        vector_store.delete_collection()
        vector_store = MitoVectorStore(persist_directory=persist_dir, variant=variant.value)
    
    # Add documents to vector store
    print(f"⚡ Adding {len(documents)} documents to {variant.value} vector store...")
    success = vector_store.add_documents(documents)
    
    if success:
        print(f"✅ {RAGServiceFactory.get_variant_display_name(variant)} variant setup complete!")
        print(f"📊 Vector store statistics: {vector_store.get_stats()}")
        return True
    else:
        print(f"❌ Failed to setup {variant.value} variant")
        return False

def main():
    """Main setup function."""
    parser = argparse.ArgumentParser(description="Setup MITO RAG System with different variants")
    parser.add_argument(
        "--variant", 
        choices=["fixed", "semantic", "both"], 
        default="both",
        help="Which variant to setup (default: both)"
    )
    parser.add_argument(
        "--force", 
        action="store_true", 
        help="Force rebuild existing vector stores"
    )
    
    args = parser.parse_args()
    
    print("🧬 MITO RAG System Setup")
    print("=" * 50)
    
    # Load environment variables
    load_dotenv()
    
    # Check for OpenAI API key
    if not os.getenv('OPENAI_API_KEY'):
        print("❌ Error: OPENAI_API_KEY not found in environment variables")
        print("Please create a .env file with your OpenAI API key")
        return
    
    # Get article statistics - handle different path structures
    script_dir = os.path.dirname(os.path.abspath(__file__))
    articles_path = os.path.join(script_dir, "data", "articles")
    
    # If that doesn't exist, try relative path
    if not os.path.exists(articles_path):
        articles_path = "data/articles"
    
    # Try absolute path for production
    if not os.path.exists(articles_path):
        articles_path = "/app/data/articles"
    
    # If still doesn't exist, show available paths for debugging
    if not os.path.exists(articles_path):
        print(f"❌ Articles directory not found at: {articles_path}")
        print(f"Current working directory: {os.getcwd()}")
        print("Available directories:")
        for item in os.listdir("."):
            if os.path.isdir(item):
                print(f"  - {item}")
        
        # In production, this is a critical error
        if os.getenv("ENVIRONMENT") == "production":
            print("❌ CRITICAL: Articles not found in production environment")
            sys.exit(1)
        return
    
    # Get basic article stats
    temp_processor = SlovakArticleProcessor()
    stats = temp_processor.get_article_stats(articles_path)
    print(f"📊 Found {stats['total_articles']} articles")
    print(f"📊 Total words: {stats['total_words']:,}")
    print(f"📊 Topics: {stats['topics']}")
    
    # Setup variants based on arguments
    success_count = 0
    total_variants = 0
    
    if args.variant in ["fixed", "both"]:
        total_variants += 1
        if setup_variant(RAGVariant.FIXED_SIZE, articles_path, args.force):
            success_count += 1
    
    if args.variant in ["semantic", "both"]:
        total_variants += 1
        if setup_variant(RAGVariant.SEMANTIC, articles_path, args.force):
            success_count += 1
    
    # Summary
    print("\n" + "=" * 50)
    if success_count == total_variants:
        print(f"✅ Successfully setup {success_count}/{total_variants} RAG variants!")
        print("\n🚀 You can now start the FastAPI server with:")
        print("   uvicorn app.main:app --reload")
        print("\n📚 Available endpoints:")
        print("   POST /api/chat - Single variant response")
        print("   POST /api/chat/compare - Compare all variants")
        print("   GET /api/rag/variants - List available variants")
    else:
        print(f"⚠️  Setup completed with issues: {success_count}/{total_variants} variants successful")

if __name__ == "__main__":
    main()
