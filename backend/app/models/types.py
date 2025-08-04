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

class Chunk(BaseModel):
    id: str
    content: str
    excerpt: str
    chunk_size: int
    chunk_type: str
    relevance_score: float
    document_id: Optional[str] = None
    metadata: Optional[dict] = None

class Source(BaseModel):
    title: str
    excerpt: str
    url: str
    relevance_score: float  # Max relevance score from associated chunks
    chunks: List[Chunk] = []  # All chunks from this source
    # Legacy fields for backward compatibility
    chunk_text: Optional[str] = None  # Full chunk content for modal
    chunk_size: Optional[int] = None  # Size of the chunk
    document_id: Optional[str] = None  # Document identifier
    metadata: Optional[dict] = None  # Additional metadata from vector store

class UsageData(BaseModel):
    model: str
    prompt_tokens: int
    completion_tokens: int
    total_tokens: int
    response_time_ms: Optional[int] = None

class ChatResponse(BaseModel):
    response: str
    sources: List[Source]
    session_id: str
    timestamp: datetime
    usage: Optional[UsageData] = None

class VariantResponse(BaseModel):
    variant_name: str
    response: str
    sources: List[Source]
    processing_time: float
    usage: Optional[UsageData] = None

class ComparisonResponse(BaseModel):
    responses: List[VariantResponse]
    session_id: str
    timestamp: datetime

class HealthResponse(BaseModel):
    status: str
    model: str
    vector_store_status: str