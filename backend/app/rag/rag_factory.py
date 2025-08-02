from typing import Dict
from .vector_store import MitoVectorStore
from .chain import MitoRAGChain
from .chunkers.fixed_size import FixedSizeChunker
from .chunkers.semantic import SemanticChunker
from app.models.types import RAGVariant

class RAGServiceFactory:
    """Factory for creating RAG services with different variants."""
    
    @staticmethod
    def create_vector_store(variant: RAGVariant, persist_directory: str = "./chroma_db") -> MitoVectorStore:
        """Create a vector store for the specified variant."""
        if variant == RAGVariant.SEMANTIC:
            persist_dir = persist_directory.replace("chroma_db", "chroma_db_semantic")
        else:
            persist_dir = persist_directory
            
        return MitoVectorStore(persist_directory=persist_dir, variant=variant.value)
    
    @staticmethod
    def create_rag_chain(variant: RAGVariant, persist_directory: str = "./chroma_db") -> MitoRAGChain:
        """Create a complete RAG chain for the specified variant."""
        vector_store = RAGServiceFactory.create_vector_store(variant, persist_directory)
        return MitoRAGChain(vector_store, variant)
    
    @staticmethod
    def create_chunker(variant: RAGVariant):
        """Create a chunker for the specified variant."""
        if variant == RAGVariant.SEMANTIC:
            return SemanticChunker()
        else:
            return FixedSizeChunker()
    
    @staticmethod
    def get_variant_display_name(variant: RAGVariant) -> str:
        """Get display name for a variant."""
        display_names = {
            RAGVariant.FIXED_SIZE: "Fixed-Size Chunking",
            RAGVariant.SEMANTIC: "Semantic Chunking"
        }
        return display_names.get(variant, variant.value)
    
    @staticmethod
    def get_all_variants() -> Dict[RAGVariant, str]:
        """Get all available variants with their display names."""
        return {
            variant: RAGServiceFactory.get_variant_display_name(variant)
            for variant in RAGVariant
        }