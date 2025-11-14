"""
API v1 router.
"""
from fastapi import APIRouter

from app.api.v1.endpoints import (
    auth,
    users,
    clientes,
    licitaciones,
    dashboard,
    documentos,
    ampliaciones,
    crm,
    alertas
)

# Create API router
api_router = APIRouter()

# Include endpoint routers
api_router.include_router(auth.router, prefix="/auth", tags=["Authentication"])
api_router.include_router(users.router, prefix="/users", tags=["Users"])
api_router.include_router(clientes.router, prefix="/clientes", tags=["Clientes"])
api_router.include_router(licitaciones.router, prefix="/licitaciones", tags=["Licitaciones"])
api_router.include_router(documentos.router, prefix="/documentos", tags=["Documentos"])
api_router.include_router(ampliaciones.router, prefix="/modificaciones", tags=["Ampliaciones y Prórrogas"])
api_router.include_router(crm.router, prefix="/crm", tags=["CRM"])
api_router.include_router(alertas.router, prefix="/alertas", tags=["Alertas"])
api_router.include_router(dashboard.router, prefix="/dashboard", tags=["Dashboard"])
