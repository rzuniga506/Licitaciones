#!/bin/bash

# Database initialization script
# This script runs migrations and creates initial data

set -e

echo "🚀 Starting database initialization..."

# Wait for database to be ready
echo "⏳ Waiting for database to be ready..."
sleep 3

# Run migrations
echo "📦 Running database migrations..."
cd /app
alembic upgrade head

# Initialize database with default data
echo "👤 Creating default admin user..."
python -m app.utils.init_db

echo "✅ Database initialization completed successfully!"
