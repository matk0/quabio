#!/bin/bash

# MITO Setup Script
echo "🧬 Setting up MITO - Slovak Health Assistant"
echo "============================================"

# Check if conda is installed
if ! command -v conda &> /dev/null; then
    echo "❌ Conda is not installed. Please install Miniconda or Anaconda first."
    exit 1
fi

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed. Please install Node.js 18+ first."
    exit 1
fi

# Create and activate conda environment for backend
echo "📦 Creating conda environment..."
conda create -n mito-backend python=3.11 -y
source $(conda info --base)/etc/profile.d/conda.sh
conda activate mito-backend

# Install backend dependencies
echo "📦 Installing backend dependencies..."
cd backend
pip install -r requirements.txt

# Check for .env file
if [ ! -f .env ]; then
    echo "⚠️  Creating .env file from template..."
    cp .env.example .env
    echo "🔑 Please edit backend/.env and add your OpenAI API key"
    read -p "Press Enter to continue after adding your API key..."
fi

# Setup RAG system
echo "🗄️  Setting up RAG system..."
python setup_rag.py

if [ $? -eq 0 ]; then
    echo "✅ Backend setup complete!"
else
    echo "❌ Backend setup failed. Check your OpenAI API key."
    exit 1
fi

# Setup frontend
echo "📦 Setting up frontend..."
cd ../frontend

# Install frontend dependencies
npm install

# Create frontend .env file
if [ ! -f .env ]; then
    cp .env.example .env
fi

echo "✅ Frontend setup complete!"

echo ""
echo "🎉 MITO setup complete!"
echo ""
echo "To start the application:"
echo "1. Backend: cd backend && uvicorn app.main:app --reload"
echo "2. Frontend: cd frontend && npm start"
echo ""
echo "Or use Docker: docker-compose up --build"