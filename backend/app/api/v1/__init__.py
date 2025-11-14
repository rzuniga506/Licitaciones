"""
API v1 router.
"""
from fastapi import APIRouter

from app.api.v1.endpoints import auth, users, clientes, licitaciones

# Create API router
api_router = APIRouter()

# Include endpoint routers
api_router.include_router(auth.router, prefix="/auth", tags=["Authentication"])
api_router.include_router(users.router, prefix="/users", tags=["Users"])
api_router.include_router(clientes.router, prefix="/clientes", tags=["Clientes"])
api_router.include_router(licitaciones.router, prefix="/licitaciones", tags=["Licitaciones"])
