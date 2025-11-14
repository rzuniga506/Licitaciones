#!/bin/bash

# Development startup script

set -e

echo "🚀 Starting development environment..."

# Check if .env exists
if [ ! -f backend/.env ]; then
    echo "⚠️  .env file not found. Copying from .env.example..."
    cp backend/.env.example backend/.env
    echo "✅ .env file created. Please update with your settings."
fi

# Start Docker services
echo "🐳 Starting Docker services..."
docker-compose up -d db redis

# Wait for database
echo "⏳ Waiting for database to be ready..."
sleep 5

# Run migrations
echo "📦 Running migrations..."
cd backend
alembic upgrade head

# Initialize database
echo "👤 Initializing database..."
python -m app.utils.init_db

# Start backend
echo "🔧 Starting backend server..."
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

echo "✅ Development environment ready!"
echo "📚 API Docs: http://localhost:8000/api/v1/docs"
