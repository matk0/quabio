from fastapi import APIRouter, HTTPException, Depends
from app.models.types import ChatRequest, ChatResponse, HealthResponse
from app.rag.vector_store import MitoVectorStore
from app.rag.chain import MitoRAGChain
import os
from functools import lru_cache

router = APIRouter()

# Global variables for RAG system (initialized once)
vector_store = None
rag_chain = None

@lru_cache()
def get_vector_store():
    """Get or create vector store instance."""
    global vector_store
    if vector_store is None:
        vector_store = MitoVectorStore(persist_directory="./chroma_db")
    return vector_store

@lru_cache()
def get_rag_chain():
    """Get or create RAG chain instance."""
    global rag_chain
    if rag_chain is None:
        vs = get_vector_store()
        rag_chain = MitoRAGChain(vs)
    return rag_chain

@router.post("/chat", response_model=ChatResponse)
async def chat_endpoint(request: ChatRequest):
    """
    Chat endpoint pre MITO - slovenský zdravotný asistent.
    
    Prijíma otázky v slovenčine a odpoveda na základe databázy článkov
    o zdraví, epigenetike a kvantovej biológii.
    """
    try:
        if not request.message or len(request.message.strip()) < 2:
            raise HTTPException(
                status_code=400, 
                detail="Otázka musí obsahovať aspoň 2 znaky"
            )
        
        # Get RAG chain
        chain = get_rag_chain()
        
        # Process the chat message
        response = await chain.chat(
            message=request.message,
            session_id=request.session_id
        )
        
        return response
        
    except Exception as e:
        print(f"Error in chat endpoint: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Nastala chyba pri spracovaní: {str(e)}"
        )

@router.get("/health", response_model=HealthResponse)
async def health_check():
    """
    Health check endpoint pre monitoring.
    """
    try:
        # Check vector store status
        vs = get_vector_store()
        vs_stats = vs.get_stats()
        
        vs_status = "zdravý" if vs_stats.get('document_count', 0) > 0 else "prázdny"
        
        return HealthResponse(
            status="zdravý",
            model="gpt-4-turbo-preview",
            vector_store_status=vs_status
        )
        
    except Exception as e:
        return HealthResponse(
            status="chyba",
            model="gpt-4-turbo-preview", 
            vector_store_status=f"chyba: {str(e)}"
        )

@router.get("/stats")
async def get_stats():
    """
    Get statistics about the RAG system.
    """
    try:
        vs = get_vector_store()
        stats = vs.get_stats()
        
        return {
            "vector_store": stats,
            "api_status": "aktívne",
            "supported_language": "slovenčina"
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Chyba pri získavaní štatistík: {str(e)}"
        )