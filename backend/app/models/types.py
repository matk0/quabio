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