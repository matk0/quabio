import os
from typing import List, Optional
from langchain_openai import OpenAIEmbeddings
from langchain_community.vectorstores import Chroma
from langchain.schema import Document
from dotenv import load_dotenv

load_dotenv()

class MitoVectorStore:
    def __init__(self, persist_directory: str = "./chroma_db"):
        self.persist_directory = persist_directory
        
        # Use the larger embedding model for better multilingual support
        self.embeddings = OpenAIEmbeddings(
            model="text-embedding-3-large",
            chunk_size=100  # Process in smaller batches for reliability
        )
        
        # Initialize or load existing vector store
        self.vectorstore = None
        self._initialize_vectorstore()
    
    def _initialize_vectorstore(self):
        """Initialize or load existing ChromaDB vector store."""
        try:
            # Try to load existing vector store
            if os.path.exists(self.persist_directory):
                print("Loading existing vector store...")
                self.vectorstore = Chroma(
                    collection_name="mito_articles_sk",
                    embedding_function=self.embeddings,
                    persist_directory=self.persist_directory
                )
                print(f"Loaded vector store with {self.vectorstore._collection.count()} documents")
            else:
                print("Creating new vector store...")
                self.vectorstore = Chroma(
                    collection_name="mito_articles_sk",
                    embedding_function=self.embeddings,
                    persist_directory=self.persist_directory
                )
        except Exception as e:
            print(f"Error initializing vector store: {e}")
            # Create new vector store if loading fails
            self.vectorstore = Chroma(
                collection_name="mito_articles_sk",
                embedding_function=self.embeddings,
                persist_directory=self.persist_directory
            )
    
    def add_documents(self, documents: List[Document]) -> bool:
        """Add documents to the vector store."""
        try:
            print(f"Adding {len(documents)} documents to vector store...")
            
            # Add documents in batches to avoid memory issues
            batch_size = 50
            for i in range(0, len(documents), batch_size):
                batch = documents[i:i + batch_size]
                self.vectorstore.add_documents(batch)
                print(f"Added batch {i//batch_size + 1}/{(len(documents) + batch_size - 1)//batch_size}")
            
            # Persist the vector store
            self.vectorstore.persist()
            print("Documents added successfully and vector store persisted")
            return True
            
        except Exception as e:
            print(f"Error adding documents: {e}")
            return False
    
    def similarity_search(self, query: str, k: int = 6) -> List[Document]:
        """Search for similar documents."""
        try:
            results = self.vectorstore.similarity_search(
                query=query,
                k=k
            )
            return results
        except Exception as e:
            print(f"Error in similarity search: {e}")
            return []
    
    def similarity_search_with_score(self, query: str, k: int = 6) -> List[tuple]:
        """Search for similar documents with relevance scores."""
        try:
            results = self.vectorstore.similarity_search_with_score(
                query=query, 
                k=k
            )
            return results
        except Exception as e:
            print(f"Error in similarity search with score: {e}")
            return []
    
    def get_retriever(self, search_type: str = "similarity", k: int = 6):
        """Get a retriever for the vector store."""
        return self.vectorstore.as_retriever(
            search_type=search_type,
            search_kwargs={"k": k}
        )
    
    def get_stats(self) -> dict:
        """Get statistics about the vector store."""
        try:
            count = self.vectorstore._collection.count()
            return {
                "document_count": count,
                "collection_name": "mito_articles_sk",
                "embedding_model": "text-embedding-3-large",
                "persist_directory": self.persist_directory
            }
        except Exception as e:
            print(f"Error getting stats: {e}")
            return {"error": str(e)}
    
    def delete_collection(self):
        """Delete the entire collection (use with caution)."""
        try:
            self.vectorstore.delete_collection()
            print("Collection deleted successfully")
        except Exception as e:
            print(f"Error deleting collection: {e}")