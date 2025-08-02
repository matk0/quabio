from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
from app.api.chat import router as chat_router
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Create FastAPI app
app = FastAPI(
    title="MITO - Slovenský Zdravotný Asistent",
    description="RAG chatbot špecializovaný na zdravie, epigenetiku a kvantovú biológiu",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:3000",  # React development server
        "http://localhost:3001",
        "http://127.0.0.1:3000",  # Alternative localhost
        "https://*.vercel.app",   # Vercel deployments
        "https://*.digitalocean.app",  # DigitalOcean deployments
    ],
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allow_headers=["*"],
)

# Include API routers
app.include_router(chat_router, prefix="/api", tags=["chat"])

# Serve React app static files
static_dir = "/app/static"
if os.path.exists(static_dir):
    
    @app.get("/")
    async def serve_react_app():
        """Serve React app."""
        return FileResponse(os.path.join(static_dir, "index.html"))
    
    @app.get("/{full_path:path}")
    async def serve_react_routes(full_path: str):
        """Serve React app for all non-API routes (SPA routing)."""
        # Skip API routes and docs
        if full_path.startswith("api/") or full_path.startswith("docs") or full_path.startswith("redoc") or full_path == "ping":
            return {"error": "Not found"}
        
        # Check if it's a static file (JS, CSS, images, etc.) in the React build
        file_path = os.path.join(static_dir, full_path)
        if os.path.isfile(file_path):
            return FileResponse(file_path)
        
        # For all other routes, serve the React app (SPA routing)
        return FileResponse(os.path.join(static_dir, "index.html"))
else:
    @app.get("/")
    async def root():
        """Fallback root endpoint when React build not available."""
        return {
            "message": "Vitajte v MITO - vašom slovenskom zdravotnom asistentovi! 🧬",
            "description": "RAG chatbot pre otázky o zdraví, epigenetike a kvantovej biológiu",
            "endpoints": {
                "chat": "/api/chat",
                "health": "/api/health", 
                "stats": "/api/stats",
                "docs": "/docs"
            }
        }

@app.get("/ping")
async def ping():
    """Simple ping endpoint for monitoring."""
    return {"status": "ok", "message": "pong"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)