from typing import List, Dict, Any
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain.schema import Document
from .base import BaseChunker

class FixedSizeChunker(BaseChunker):
    """Fixed-size chunking strategy using RecursiveCharacterTextSplitter."""
    
    def __init__(self, chunk_size: int = 800, chunk_overlap: int = 200):
        super().__init__()
        self.chunk_size = chunk_size
        self.chunk_overlap = chunk_overlap
        
        # Optimized for Slovak text processing
        self.text_splitter = RecursiveCharacterTextSplitter(
            chunk_size=chunk_size,
            chunk_overlap=chunk_overlap,
            separators=["\n\n", "\n", ". ", "! ", "? ", " ", ""],
            keep_separator=True
        )
    
    def chunk_text(self, text: str, metadata: Dict[str, Any]) -> List[Document]:
        """Chunk text using fixed-size strategy."""
        # Split the content into chunks
        chunks = self.text_splitter.split_text(text)
        documents = []
        
        for i, chunk in enumerate(chunks):
            # Create metadata for each chunk
            chunk_metadata = metadata.copy()
            chunk_metadata.update({
                'chunk_id': i,
                'total_chunks': len(chunks),
                'chunking_strategy': 'fixed_size',
                'chunk_size': self.chunk_size,
                'chunk_overlap': self.chunk_overlap
            })
            
            # Create Document object
            doc = Document(
                page_content=chunk,
                metadata=chunk_metadata
            )
            documents.append(doc)
        
        self.chunk_count += len(documents)
        return documents
    
    def get_chunker_name(self) -> str:
        return "Fixed Size"
    
    def get_chunker_description(self) -> str:
        return f"Fixed-size chunking with {self.chunk_size} characters and {self.chunk_overlap} overlap"