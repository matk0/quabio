from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
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
        "https://qua.bio",           # Rails production domain
        "https://www.qua.bio",       # Rails production www
        "http://localhost:3000",     # Rails development server
        "http://localhost:3001",     # Legacy React development
        "http://127.0.0.1:3000",     # Alternative localhost
        "https://*.vercel.app",      # Vercel deployments
        "https://*.digitalocean.app", # DigitalOcean deployments
    ],
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allow_headers=["*"],
)

# Include API routers
app.include_router(chat_router, prefix="/api", tags=["chat"])

@app.get("/ping")
async def ping():
    """Simple ping endpoint for monitoring."""
    return {"status": "ok", "message": "pong"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)