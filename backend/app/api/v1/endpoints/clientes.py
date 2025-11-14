"""
Cliente management endpoints.
"""
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session

from app.core.security import get_current_user, require_analyst
from app.db.session import get_db
from app.models.user import User
from app.schemas.cliente import ClienteCreate, ClienteUpdate, ClienteResponse, ClienteList
from app.services.cliente_service import ClienteService

router = APIRouter()


@router.get("/", response_model=ClienteList)
async def get_clientes(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    tipo_cliente: Optional[str] = Query(None, pattern="^(publico|privado)$"),
    is_active: Optional[bool] = None,
    search: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get list of clientes with pagination and filters.

    Args:
        page: Page number (default: 1)
        page_size: Items per page (default: 20, max: 100)
        tipo_cliente: Filter by tipo (publico/privado)
        is_active: Filter by active status
        search: Search in nombre, identificacion, email, contacto
        db: Database session
        current_user: Current authenticated user

    Returns:
        Paginated list of clientes
    """
    clientes = ClienteService.get_clientes_paginated(
        db,
        page=page,
        page_size=page_size,
        tipo_cliente=tipo_cliente,
        is_active=is_active,
        search=search
    )
    return clientes


@router.get("/{cliente_id}", response_model=ClienteResponse)
async def get_cliente(
    cliente_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get cliente by ID.

    Args:
        cliente_id: Cliente ID
        db: Database session
        current_user: Current authenticated user

    Returns:
        Cliente information

    Raises:
        HTTPException: If cliente not found
    """
    cliente = ClienteService.get_cliente_by_id(db, cliente_id)

    if not cliente:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Cliente not found"
        )

    return cliente


@router.post("/", response_model=ClienteResponse, status_code=status.HTTP_201_CREATED)
async def create_cliente(
    cliente_data: ClienteCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_analyst)
):
    """
    Create new cliente (requires analyst role or higher).

    Args:
        cliente_data: Cliente creation data
        db: Database session
        current_user: Current authenticated user

    Returns:
        Created cliente

    Raises:
        HTTPException: If identificacion already exists
    """
    cliente = ClienteService.create_cliente(db, cliente_data, current_user.user_id)
    return cliente


@router.put("/{cliente_id}", response_model=ClienteResponse)
async def update_cliente(
    cliente_id: int,
    cliente_data: ClienteUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_analyst)
):
    """
    Update cliente information (requires analyst role or higher).

    Args:
        cliente_id: Cliente ID to update
        cliente_data: Update data
        db: Database session
        current_user: Current authenticated user

    Returns:
        Updated cliente

    Raises:
        HTTPException: If cliente not found or identificacion already exists
    """
    cliente = ClienteService.update_cliente(db, cliente_id, cliente_data)
    return cliente


@router.delete("/{cliente_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_cliente(
    cliente_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_analyst)
):
    """
    Delete cliente (soft delete, requires analyst role or higher).

    Args:
        cliente_id: Cliente ID to delete
        db: Database session
        current_user: Current authenticated user

    Raises:
        HTTPException: If cliente not found or has active licitaciones
    """
    ClienteService.delete_cliente(db, cliente_id)
    return None


@router.get("/{cliente_id}/stats")
async def get_cliente_stats(
    cliente_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get statistics for a cliente.

    Args:
        cliente_id: Cliente ID
        db: Database session
        current_user: Current authenticated user

    Returns:
        Cliente statistics

    Raises:
        HTTPException: If cliente not found
    """
    stats = ClienteService.get_cliente_stats(db, cliente_id)
    return stats
