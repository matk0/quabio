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

@router.get("/debug/rag")
async def debug_rag():
    """
    Debug endpoint to check RAG system status in production.
    """
    try:
        vs = get_vector_store()
        chain = get_rag_chain()
        
        # Get vector store stats
        vs_stats = vs.get_stats()
        
        # Test retrieval with a simple query
        test_query = "epigenetika"
        try:
            relevant_docs = vs.similarity_search(test_query, k=3)
            retrieval_test = {
                "query": test_query,
                "documents_found": len(relevant_docs),
                "sample_titles": [doc.metadata.get('title', 'No title') for doc in relevant_docs[:3]]
            }
        except Exception as e:
            retrieval_test = {"error": str(e)}
        
        # Check if articles directory exists and count files
        import os
        articles_path = "./data/articles"
        articles_info = {}
        if os.path.exists(articles_path):
            articles_files = [f for f in os.listdir(articles_path) if f.endswith('.json')]
            articles_info = {
                "articles_directory_exists": True,
                "articles_count": len(articles_files),
                "sample_files": articles_files[:5]
            }
        else:
            articles_info = {"articles_directory_exists": False}
        
        return {
            "vector_store_stats": vs_stats,
            "retrieval_test": retrieval_test,
            "articles_info": articles_info,
            "environment": os.getenv("ENVIRONMENT", "unknown"),
            "chroma_persist_dir": os.getenv("CHROMA_PERSIST_DIR", "./chroma_db")
        }
        
    except Exception as e:
        return {
            "error": str(e),
            "error_type": type(e).__name__
        }

@router.post("/debug/test-sources")
async def test_sources(request: ChatRequest):
    """
    Debug endpoint to test source extraction specifically.
    """
    try:
        vs = get_vector_store()
        
        # Get relevant documents
        relevant_docs = vs.similarity_search(request.message, k=6)
        
        # Extract sources manually to debug
        sources = []
        seen_titles = set()
        
        for doc in relevant_docs:
            title = doc.metadata.get('title', 'Bez názvu')
            if title in seen_titles:
                continue
            seen_titles.add(title)
            
            content = doc.page_content
            excerpt = content[:200] + "..." if len(content) > 200 else content
            
            sources.append({
                "title": title,
                "excerpt": excerpt,
                "url": doc.metadata.get('url', ''),
                "relevance_score": 0.9,
                "metadata": doc.metadata
            })
        
        return {
            "query": request.message,
            "documents_found": len(relevant_docs),
            "sources_extracted": len(sources),
            "sources": sources[:3],
            "all_doc_titles": [doc.metadata.get('title', 'No title') for doc in relevant_docs]
        }
        
    except Exception as e:
        return {
            "error": str(e),
            "error_type": type(e).__name__
        }