from fastapi import APIRouter, HTTPException, Depends
from app.models.types import ChatRequest, ChatResponse, HealthResponse, ComparisonResponse, VariantResponse, RAGVariant
from app.rag.vector_store import MitoVectorStore
from app.rag.chain import MitoRAGChain
from app.rag.rag_factory import RAGServiceFactory
import os
import time
import uuid
from datetime import datetime
from functools import lru_cache

router = APIRouter()

# Global variables for RAG system (initialized once)
vector_store = None
rag_chain = None
rag_chains = {}  # Cache for different variants

@lru_cache()
def get_vector_store():
    """Get or create vector store instance (backward compatibility)."""
    global vector_store
    if vector_store is None:
        vector_store = MitoVectorStore(persist_directory="./chroma_db", variant="fixed")
    return vector_store

@lru_cache()
def get_rag_chain():
    """Get or create RAG chain instance (backward compatibility)."""
    global rag_chain
    if rag_chain is None:
        vs = get_vector_store()
        rag_chain = MitoRAGChain(vs, RAGVariant.FIXED_SIZE)
    return rag_chain

def get_rag_chain_for_variant(variant: RAGVariant) -> MitoRAGChain:
    """Get or create RAG chain for specific variant."""
    global rag_chains
    
    if variant not in rag_chains:
        rag_chains[variant] = RAGServiceFactory.create_rag_chain(variant)
    
    return rag_chains[variant]

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

@router.post("/chat/compare", response_model=ComparisonResponse)
async def chat_compare_endpoint(request: ChatRequest):
    """
    Compare responses from different RAG variants.
    
    Returns responses from both fixed-size and semantic chunking variants.
    """
    try:
        if not request.message or len(request.message.strip()) < 2:
            raise HTTPException(
                status_code=400, 
                detail="Otázka musí obsahovať aspoň 2 znaky"
            )
        
        session_id = request.session_id or str(uuid.uuid4())
        responses = []
        
        # Get responses from both variants
        variants_to_compare = [RAGVariant.FIXED_SIZE, RAGVariant.SEMANTIC]
        
        for variant in variants_to_compare:
            try:
                start_time = time.time()
                
                # Get RAG chain for this variant
                chain = get_rag_chain_for_variant(variant)
                
                # Process the chat message
                response = await chain.chat(
                    message=request.message,
                    session_id=session_id
                )
                
                processing_time = time.time() - start_time
                
                # Create variant response
                variant_response = VariantResponse(
                    variant_name=RAGServiceFactory.get_variant_display_name(variant),
                    response=response.response,
                    sources=response.sources,
                    processing_time=processing_time
                )
                responses.append(variant_response)
                
            except Exception as e:
                print(f"Error processing variant {variant}: {e}")
                # Add error response for this variant
                error_response = VariantResponse(
                    variant_name=RAGServiceFactory.get_variant_display_name(variant),
                    response=f"Chyba pri spracovaní pomocou {RAGServiceFactory.get_variant_display_name(variant)}: {str(e)}",
                    sources=[],
                    processing_time=0.0
                )
                responses.append(error_response)
        
        return ComparisonResponse(
            responses=responses,
            session_id=session_id,
            timestamp=datetime.now()
        )
        
    except Exception as e:
        print(f"Error in chat compare endpoint: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Nastala chyba pri porovnaní: {str(e)}"
        )




