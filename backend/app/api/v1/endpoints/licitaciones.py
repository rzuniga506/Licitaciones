"""
Licitacion management endpoints.
"""
from typing import Optional, List
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from datetime import date

from app.core.security import get_current_user, require_analyst, require_coordinator
from app.db.session import get_db
from app.models.user import User
from app.models.licitacion import Licitacion
from app.schemas.licitacion import (
    LicitacionCreate,
    LicitacionUpdate,
    LicitacionResponse,
    LicitacionList,
    LicitacionStats
)
from app.services.licitacion_service import LicitacionService

router = APIRouter()


@router.get("/", response_model=LicitacionList)
async def get_licitaciones(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    cliente_id: Optional[int] = None,
    estado: Optional[str] = None,
    categoria: Optional[str] = None,
    prioridad: Optional[str] = None,
    search: Optional[str] = None,
    fecha_desde: Optional[date] = None,
    fecha_hasta: Optional[date] = None,
    order_by: str = Query("fecha_presentacion", pattern="^(fecha_presentacion|fecha_creacion|nombre_licitacion|monto_ofertado)$"),
    order_desc: bool = True,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get list of licitaciones with pagination and filters.

    Args:
        page: Page number (default: 1)
        page_size: Items per page (default: 20, max: 100)
        cliente_id: Filter by cliente
        estado: Filter by estado
        categoria: Filter by categoria
        prioridad: Filter by prioridad
        search: Search in numero, nombre, descripcion, expediente
        fecha_desde: Filter from date (fecha_presentacion)
        fecha_hasta: Filter to date (fecha_presentacion)
        order_by: Sort field
        order_desc: Sort descending (default: True)
        db: Database session
        current_user: Current authenticated user

    Returns:
        Paginated list of licitaciones
    """
    licitaciones = LicitacionService.get_licitaciones_paginated(
        db,
        page=page,
        page_size=page_size,
        cliente_id=cliente_id,
        estado=estado,
        categoria=categoria,
        prioridad=prioridad,
        search=search,
        fecha_desde=fecha_desde,
        fecha_hasta=fecha_hasta,
        order_by=order_by,
        order_desc=order_desc
    )
    return licitaciones


@router.get("/stats", response_model=LicitacionStats)
async def get_licitaciones_stats(
    fecha_desde: Optional[date] = None,
    fecha_hasta: Optional[date] = None,
    cliente_id: Optional[int] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get licitaciones statistics.

    Args:
        fecha_desde: Filter from date
        fecha_hasta: Filter to date
        cliente_id: Filter by cliente
        db: Database session
        current_user: Current authenticated user

    Returns:
        Statistics data
    """
    stats = LicitacionService.get_licitaciones_stats(
        db,
        fecha_desde=fecha_desde,
        fecha_hasta=fecha_hasta,
        cliente_id=cliente_id
    )
    return stats


@router.get("/venciendo", response_model=List[LicitacionResponse])
async def get_licitaciones_venciendo(
    dias: int = Query(15, ge=1, le=90),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get licitaciones expiring in X days.

    Args:
        dias: Days until expiration (default: 15, max: 90)
        db: Database session
        current_user: Current authenticated user

    Returns:
        List of licitaciones expiring soon
    """
    licitaciones = LicitacionService.get_licitaciones_venciendo(db, dias)
    return licitaciones


@router.get("/{licitacion_id}", response_model=LicitacionResponse)
async def get_licitacion(
    licitacion_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get licitacion by ID.

    Args:
        licitacion_id: Licitacion ID
        db: Database session
        current_user: Current authenticated user

    Returns:
        Licitacion information

    Raises:
        HTTPException: If licitacion not found
    """
    licitacion = LicitacionService.get_licitacion_by_id(db, licitacion_id)

    if not licitacion:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Licitacion not found"
        )

    return licitacion


@router.post("/", response_model=LicitacionResponse, status_code=status.HTTP_201_CREATED)
async def create_licitacion(
    licitacion_data: LicitacionCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_analyst)
):
    """
    Create new licitacion (requires analyst role or higher).

    Args:
        licitacion_data: Licitacion creation data
        db: Database session
        current_user: Current authenticated user

    Returns:
        Created licitacion

    Raises:
        HTTPException: If numero already exists or cliente not found
    """
    licitacion = LicitacionService.create_licitacion(db, licitacion_data, current_user.user_id)
    return licitacion


@router.put("/{licitacion_id}", response_model=LicitacionResponse)
async def update_licitacion(
    licitacion_id: int,
    licitacion_data: LicitacionUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_analyst)
):
    """
    Update licitacion information (requires analyst role or higher).

    Args:
        licitacion_id: Licitacion ID to update
        licitacion_data: Update data
        db: Database session
        current_user: Current authenticated user

    Returns:
        Updated licitacion

    Raises:
        HTTPException: If licitacion not found or numero already exists
    """
    licitacion = LicitacionService.update_licitacion(
        db,
        licitacion_id,
        licitacion_data,
        current_user.user_id
    )
    return licitacion


@router.patch("/{licitacion_id}/estado")
async def change_estado(
    licitacion_id: int,
    nuevo_estado: str = Query(..., pattern="^(en_preparacion|presentada|en_evaluacion|adjudicada|en_ejecucion|finalizada|desierta|rechazada)$"),
    motivo_rechazo: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_analyst)
):
    """
    Change licitacion estado (requires analyst role or higher).

    Args:
        licitacion_id: Licitacion ID
        nuevo_estado: New estado
        motivo_rechazo: Rejection reason (required if estado=rechazada)
        db: Database session
        current_user: Current authenticated user

    Returns:
        Updated licitacion

    Raises:
        HTTPException: If licitacion not found or invalid estado
    """
    if nuevo_estado == "rechazada" and not motivo_rechazo:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="motivo_rechazo is required when estado=rechazada"
        )

    licitacion = LicitacionService.change_estado(
        db,
        licitacion_id,
        nuevo_estado,
        current_user.user_id,
        motivo_rechazo
    )
    return licitacion


@router.delete("/{licitacion_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_licitacion(
    licitacion_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_coordinator)
):
    """
    Delete licitacion (soft delete, requires coordinator role or higher).

    Only licitaciones in certain states can be deleted (en_preparacion, desierta, rechazada).

    Args:
        licitacion_id: Licitacion ID to delete
        db: Database session
        current_user: Current authenticated user

    Raises:
        HTTPException: If licitacion not found or cannot be deleted
    """
    LicitacionService.delete_licitacion(db, licitacion_id)
    return None
