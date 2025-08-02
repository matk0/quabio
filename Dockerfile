# Multi-stage build for complete full-stack app
# Stage 1: Build React frontend
FROM node:18-alpine AS frontend-build

WORKDIR /app/frontend

# Copy package files
COPY frontend/package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy frontend source
COPY frontend/ ./

# Build React app for production
RUN npm run build

# Stage 2: Python backend with React frontend
FROM python:3.11

WORKDIR /app

# Copy backend requirements and install Python dependencies
COPY backend/requirements.txt ./requirements.txt
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copy backend application code
COPY backend/ ./

# Copy React build from frontend stage
COPY --from=frontend-build /app/frontend/build ./static

# Create directory for ChromaDB
RUN mkdir -p /app/chroma_db

# Copy and make startup script executable
COPY start_production.sh ./
RUN chmod +x start_production.sh

# Expose port
EXPOSE 8000

# Run with startup script that handles RAG initialization
CMD ["./start_production.sh"]