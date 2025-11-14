"""
CRM endpoints for Contactos and InteraccionesCliente.
"""
from typing import Optional, List
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from datetime import datetime

from app.core.security import get_current_user, check_permission
from app.db.session import get_db
from app.models.user import User
from app.schemas.crm import (
    ContactoCreate,
    ContactoUpdate,
    ContactoResponse,
    ContactoList,
    InteraccionClienteCreate,
    InteraccionClienteUpdate,
    InteraccionClienteResponse,
    InteraccionClienteList
)
from app.services.crm_service import ContactoService, InteraccionClienteService

router = APIRouter()


# ==================== CONTACTOS ====================

@router.get("/contactos", response_model=ContactoList)
async def get_contactos(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    cliente_id: Optional[int] = Query(None, gt=0),
    is_active: Optional[bool] = None,
    es_contacto_principal: Optional[bool] = None,
    nivel_decision: Optional[str] = None,
    search: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get list of contactos with filters and pagination.

    Filters:
    - cliente_id: Filter by cliente
    - is_active: Filter by active status
    - es_contacto_principal: Filter principal contacts
    - nivel_decision: Filter by decision level (alto, medio, bajo)
    - search: Search in nombre, cargo, email, telefono, departamento

    Returns paginated list of contactos.
    """
    return ContactoService.get_contactos_paginated(
        db=db,
        page=page,
        page_size=page_size,
        cliente_id=cliente_id,
        is_active=is_active,
        es_contacto_principal=es_contacto_principal,
        nivel_decision=nivel_decision,
        search=search
    )


@router.get("/contactos/{contacto_id}", response_model=ContactoResponse)
async def get_contacto(
    contacto_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get contacto by ID."""
    contacto = ContactoService.get_contacto_by_id(db, contacto_id)
    if not contacto:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Contacto not found"
        )
    return ContactoResponse.model_validate(contacto)


@router.post("/contactos", response_model=ContactoResponse, status_code=status.HTTP_201_CREATED)
async def create_contacto(
    contacto: ContactoCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(check_permission(["admin", "coordinator", "analyst"]))
):
    """
    Create new contacto.

    If es_contacto_principal=true, other principal contacts for this cliente
    will be automatically set to false.

    Requires: analyst role or higher
    """
    db_contacto = ContactoService.create_contacto(
        db=db,
        contacto=contacto,
        user_id=current_user.user_id
    )
    return ContactoResponse.model_validate(db_contacto)


@router.put("/contactos/{contacto_id}", response_model=ContactoResponse)
async def update_contacto(
    contacto_id: int,
    contacto_update: ContactoUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(check_permission(["admin", "coordinator", "analyst"]))
):
    """
    Update contacto.

    If setting es_contacto_principal=true, other principal contacts for this cliente
    will be automatically set to false.

    Requires: analyst role or higher
    """
    db_contacto = ContactoService.update_contacto(
        db=db,
        contacto_id=contacto_id,
        contacto_update=contacto_update,
        user_id=current_user.user_id
    )

    if not db_contacto:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Contacto not found"
        )

    return ContactoResponse.model_validate(db_contacto)


@router.delete("/contactos/{contacto_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_contacto(
    contacto_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(check_permission(["admin", "coordinator"]))
):
    """
    Delete contacto (soft delete).

    Requires: coordinator role or higher
    """
    success = ContactoService.delete_contacto(
        db=db,
        contacto_id=contacto_id,
        user_id=current_user.user_id
    )

    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Contacto not found"
        )

    return None


# ==================== INTERACCIONES CLIENTE ====================

@router.get("/interacciones", response_model=InteraccionClienteList)
async def get_interacciones(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    cliente_id: Optional[int] = Query(None, gt=0),
    contacto_id: Optional[int] = Query(None, gt=0),
    tipo_interaccion: Optional[str] = None,
    requiere_seguimiento: Optional[bool] = None,
    fecha_desde: Optional[datetime] = None,
    fecha_hasta: Optional[datetime] = None,
    search: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get list of interacciones with filters and pagination.

    Filters:
    - cliente_id: Filter by cliente
    - contacto_id: Filter by contacto
    - tipo_interaccion: Filter by tipo (llamada, reunion, email, visita, etc.)
    - requiere_seguimiento: Filter by follow-up requirement
    - fecha_desde/hasta: Filter by interaction date range
    - search: Search in descripcion, resultado, proximos_pasos, notas

    Returns paginated list of interacciones ordered by date (most recent first).
    """
    return InteraccionClienteService.get_interacciones_paginated(
        db=db,
        page=page,
        page_size=page_size,
        cliente_id=cliente_id,
        contacto_id=contacto_id,
        tipo_interaccion=tipo_interaccion,
        requiere_seguimiento=requiere_seguimiento,
        fecha_desde=fecha_desde,
        fecha_hasta=fecha_hasta,
        search=search
    )


@router.get("/interacciones/seguimientos-pendientes", response_model=List[InteraccionClienteResponse])
async def get_seguimientos_pendientes(
    dias: int = Query(7, ge=1, le=30, description="Days to look ahead"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get interacciones that require follow-up in the next X days.

    Args:
        dias: Number of days to look ahead (default: 7, max: 30)

    Returns:
        List of interacciones requiring follow-up soon, ordered by fecha_seguimiento
    """
    interacciones = InteraccionClienteService.get_interacciones_pendientes_seguimiento(db, dias)
    return [InteraccionClienteResponse.model_validate(i) for i in interacciones]


@router.get("/interacciones/{interaccion_id}", response_model=InteraccionClienteResponse)
async def get_interaccion(
    interaccion_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get interaccion by ID."""
    interaccion = InteraccionClienteService.get_interaccion_by_id(db, interaccion_id)
    if not interaccion:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Interaccion not found"
        )
    return InteraccionClienteResponse.model_validate(interaccion)


@router.post("/interacciones", response_model=InteraccionClienteResponse, status_code=status.HTTP_201_CREATED)
async def create_interaccion(
    interaccion: InteraccionClienteCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(check_permission(["admin", "coordinator", "analyst"]))
):
    """
    Create new interaccion.

    Records an interaction with a client, such as:
    - Phone call (llamada)
    - Meeting (reunion)
    - Email (email)
    - Site visit (visita)
    - Presentation (presentacion)

    Can optionally set follow-up date and requirements.

    Requires: analyst role or higher
    """
    db_interaccion = InteraccionClienteService.create_interaccion(
        db=db,
        interaccion=interaccion,
        user_id=current_user.user_id
    )
    return InteraccionClienteResponse.model_validate(db_interaccion)


@router.put("/interacciones/{interaccion_id}", response_model=InteraccionClienteResponse)
async def update_interaccion(
    interaccion_id: int,
    interaccion_update: InteraccionClienteUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(check_permission(["admin", "coordinator", "analyst"]))
):
    """
    Update interaccion.

    Requires: analyst role or higher
    """
    db_interaccion = InteraccionClienteService.update_interaccion(
        db=db,
        interaccion_id=interaccion_id,
        interaccion_update=interaccion_update,
        user_id=current_user.user_id
    )

    if not db_interaccion:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Interaccion not found"
        )

    return InteraccionClienteResponse.model_validate(db_interaccion)


@router.delete("/interacciones/{interaccion_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_interaccion(
    interaccion_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(check_permission(["admin", "coordinator"]))
):
    """
    Delete interaccion (soft delete).

    Requires: coordinator role or higher
    """
    success = InteraccionClienteService.delete_interaccion(
        db=db,
        interaccion_id=interaccion_id,
        user_id=current_user.user_id
    )

    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Interaccion not found"
        )

    return None
