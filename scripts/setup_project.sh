#!/bin/bash

# Setup script for Sistema de Gestión de Licitaciones
# This script sets up the complete development environment

set -e

echo "🚀 Setting up Sistema de Gestión de Licitaciones..."
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if .env exists
if [ ! -f backend/.env ]; then
    echo -e "${YELLOW}⚠️  .env file not found. Creating from template...${NC}"
    cp backend/.env.example backend/.env
    echo -e "${GREEN}✅ .env file created${NC}"
    echo -e "${YELLOW}⚠️  Please update backend/.env with your configuration before continuing${NC}"
    echo ""
    read -p "Press enter to continue..."
fi

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${YELLOW}❌ Docker is not running. Please start Docker and try again.${NC}"
    exit 1
fi

echo -e "${BLUE}📦 Starting Docker services...${NC}"
docker-compose up -d db redis

echo -e "${BLUE}⏳ Waiting for database to be ready...${NC}"
sleep 5

# Check if database is ready
until docker-compose exec -T db pg_isready -U postgres > /dev/null 2>&1; do
    echo "Waiting for database..."
    sleep 2
done

echo -e "${GREEN}✅ Database is ready${NC}"

# Install Python dependencies
echo -e "${BLUE}📦 Installing Python dependencies...${NC}"
cd backend

if [ ! -d "venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv venv
fi

source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

echo -e "${GREEN}✅ Python dependencies installed${NC}"

# Run migrations
echo -e "${BLUE}🗄️  Running database migrations...${NC}"
alembic upgrade head || echo -e "${YELLOW}⚠️  No migrations found. You may need to create initial migration.${NC}"

# Initialize database with default data
echo -e "${BLUE}👤 Creating default admin user...${NC}"
python -m app.utils.init_db

cd ..

echo ""
echo -e "${GREEN}✅ Setup complete!${NC}"
echo ""
echo "=================================================="
echo "  Next steps:"
echo "=================================================="
echo ""
echo "  1. Start the backend server:"
echo "     cd backend"
echo "     source venv/bin/activate"
echo "     uvicorn app.main:app --reload"
echo ""
echo "  2. Access the API documentation:"
echo "     http://localhost:8000/api/v1/docs"
echo ""
echo "  3. Default credentials:"
echo "     Username: admin"
echo "     Password: admin123"
echo "     ⚠️  CHANGE THIS IN PRODUCTION!"
echo ""
echo "=================================================="
