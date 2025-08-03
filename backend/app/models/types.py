from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime
from enum import Enum

class RAGVariant(str, Enum):
    FIXED_SIZE = "fixed"
    SEMANTIC = "semantic"

class ChatRequest(BaseModel):
    message: str
    session_id: Optional[str] = None

class Source(BaseModel):
    title: str
    excerpt: str
    url: str
    relevance_score: float
    chunk_text: Optional[str] = None  # Full chunk content for modal
    chunk_size: Optional[int] = None  # Size of the chunk
    document_id: Optional[str] = None  # Document identifier
    metadata: Optional[dict] = None  # Additional metadata from vector store

class ChatResponse(BaseModel):
    response: str
    sources: List[Source]
    session_id: str
    timestamp: datetime

class VariantResponse(BaseModel):
    variant_name: str
    response: str
    sources: List[Source]
    processing_time: float

class ComparisonResponse(BaseModel):
    responses: List[VariantResponse]
    session_id: str
    timestamp: datetime

class HealthResponse(BaseModel):
    status: str
    model: str
    vector_store_status: str