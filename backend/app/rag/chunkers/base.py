from abc import ABC, abstractmethod
from typing import List, Dict, Any
from langchain.schema import Document

class BaseChunker(ABC):
    """Base class for document chunking strategies."""
    
    def __init__(self):
        self.chunk_count = 0
    
    @abstractmethod
    def chunk_text(self, text: str, metadata: Dict[str, Any]) -> List[Document]:
        """
        Chunk the given text into Document objects.
        
        Args:
            text: The text content to chunk
            metadata: Metadata to attach to each chunk
            
        Returns:
            List of Document objects with chunked content
        """
        pass
    
    @abstractmethod
    def get_chunker_name(self) -> str:
        """Return the display name of this chunking strategy."""
        pass
    
    @abstractmethod
    def get_chunker_description(self) -> str:
        """Return a description of this chunking strategy."""
        pass
    
    def get_stats(self) -> Dict[str, Any]:
        """Return statistics about the chunking process."""
        return {
            "chunker_name": self.get_chunker_name(),
            "total_chunks_created": self.chunk_count
        }