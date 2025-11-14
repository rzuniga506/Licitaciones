"""
Alertas and ConfiguracionAlertas endpoints for notification management.
"""
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session

from app.core.security import get_current_user, check_permission
from app.db.session import get_db
from app.models.user import User
from app.schemas.alerta import (
    AlertaCreate,
    AlertaUpdate,
    AlertaResponse,
    AlertaList,
    AlertaStats,
    ConfiguracionAlertasCreate,
    ConfiguracionAlertasUpdate,
    ConfiguracionAlertasResponse
)
from app.services.alerta_service import AlertaService, ConfiguracionAlertasService

router = APIRouter()


# ==================== ALERTAS ====================

@router.get("/", response_model=AlertaList)
async def get_alertas(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    user_id: Optional[int] = Query(None, gt=0),
    tipo_alerta: Optional[str] = None,
    estado_alerta: Optional[str] = None,
    nivel_prioridad: Optional[str] = None,
    requiere_accion: Optional[bool] = None,
    licitacion_id: Optional[int] = Query(None, gt=0),
    cliente_id: Optional[int] = Query(None, gt=0),
    search: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get list of alertas with filters and pagination.

    Filters:
    - user_id: Filter by user (defaults to current user if not admin)
    - tipo_alerta: Filter by tipo
    - estado_alerta: Filter by estado (activa, leida, resuelta, archivada, descartada)
    - nivel_prioridad: Filter by prioridad (critica, alta, media, baja)
    - requiere_accion: Filter by action requirement
    - licitacion_id: Filter by licitacion
    - cliente_id: Filter by cliente
    - search: Search in titulo, mensaje, accion_sugerida

    Returns paginated list of alertas ordered by priority and date.
    """
    # If not admin and no user_id specified, default to current user
    if current_user.role not in ["admin"] and not user_id:
        user_id = current_user.user_id

    return AlertaService.get_alertas_paginated(
        db=db,
        page=page,
        page_size=page_size,
        user_id=user_id,
        tipo_alerta=tipo_alerta,
        estado_alerta=estado_alerta,
        nivel_prioridad=nivel_prioridad,
        requiere_accion=requiere_accion,
        licitacion_id=licitacion_id,
        cliente_id=cliente_id,
        search=search
    )


@router.get("/stats", response_model=AlertaStats)
async def get_alertas_stats(
    user_id: Optional[int] = Query(None, gt=0),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get alertas statistics.

    Provides aggregated statistics including:
    - Total alertas
    - Distribution by estado, tipo, and prioridad
    - Count of critical active alerts
    - Count of alerts requiring action

    If user_id is provided, stats are filtered for that user.
    Non-admin users can only see their own stats.
    """
    # If not admin and no user_id specified, default to current user
    if current_user.role not in ["admin"] and not user_id:
        user_id = current_user.user_id
    elif current_user.role not in ["admin"] and user_id != current_user.user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Cannot access other users' stats"
        )

    return AlertaService.get_alertas_stats(db, user_id)


@router.get("/{alerta_id}", response_model=AlertaResponse)
async def get_alerta(
    alerta_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get alerta by ID."""
    alerta = AlertaService.get_alerta_by_id(db, alerta_id)
    if not alerta:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Alerta not found"
        )

    # Check permission: users can only see their own alerts unless admin
    if current_user.role not in ["admin"] and alerta.user_id != current_user.user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Cannot access other users' alerts"
        )

    return AlertaResponse.model_validate(alerta)


@router.post("/", response_model=AlertaResponse, status_code=status.HTTP_201_CREATED)
async def create_alerta(
    alerta: AlertaCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(check_permission(["admin", "coordinator", "analyst"]))
):
    """
    Create new alerta.

    Alertas can be created manually or automatically by the system.
    Supported tipos:
    - documento_vencido, documento_por_vencer
    - contrato_proximo_fin
    - garantia_vencida, garantia_por_vencer
    - seguimiento_pendiente
    - licitacion_proxima
    - ampliacion_pendiente
    - interaccion_programada

    Requires: analyst role or higher
    """
    db_alerta = AlertaService.create_alerta(
        db=db,
        alerta=alerta,
        user_id=current_user.user_id
    )
    return AlertaResponse.model_validate(db_alerta)


@router.put("/{alerta_id}", response_model=AlertaResponse)
async def update_alerta(
    alerta_id: int,
    alerta_update: AlertaUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Update alerta.

    Users can update their own alerts. Admins can update any alert.
    Estado transitions are automatically timestamped.
    """
    # Check if alerta exists and user has permission
    alerta = AlertaService.get_alerta_by_id(db, alerta_id)
    if not alerta:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Alerta not found"
        )

    if current_user.role not in ["admin"] and alerta.user_id != current_user.user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Cannot update other users' alerts"
        )

    db_alerta = AlertaService.update_alerta(
        db=db,
        alerta_id=alerta_id,
        alerta_update=alerta_update,
        user_id=current_user.user_id
    )

    return AlertaResponse.model_validate(db_alerta)


@router.patch("/{alerta_id}/marcar-leida", response_model=AlertaResponse)
async def marcar_alerta_leida(
    alerta_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Mark alerta as read.

    Changes estado to 'leida' and sets fecha_leida.
    """
    # Check permission
    alerta = AlertaService.get_alerta_by_id(db, alerta_id)
    if not alerta:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Alerta not found"
        )

    if current_user.role not in ["admin"] and alerta.user_id != current_user.user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Cannot update other users' alerts"
        )

    db_alerta = AlertaService.marcar_como_leida(
        db=db,
        alerta_id=alerta_id,
        user_id=current_user.user_id
    )

    if not db_alerta:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Alerta not found"
        )

    return AlertaResponse.model_validate(db_alerta)


@router.patch("/{alerta_id}/marcar-resuelta", response_model=AlertaResponse)
async def marcar_alerta_resuelta(
    alerta_id: int,
    notas: Optional[str] = Query(None, max_length=500),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Mark alerta as resolved.

    Changes estado to 'resuelta', sets fecha_resuelta, and optionally adds notes.
    """
    # Check permission
    alerta = AlertaService.get_alerta_by_id(db, alerta_id)
    if not alerta:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Alerta not found"
        )

    if current_user.role not in ["admin"] and alerta.user_id != current_user.user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Cannot update other users' alerts"
        )

    db_alerta = AlertaService.marcar_como_resuelta(
        db=db,
        alerta_id=alerta_id,
        user_id=current_user.user_id,
        notas=notas
    )

    if not db_alerta:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Alerta not found"
        )

    return AlertaResponse.model_validate(db_alerta)


@router.delete("/{alerta_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_alerta(
    alerta_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(check_permission(["admin", "coordinator"]))
):
    """
    Delete alerta (soft delete).

    Requires: coordinator role or higher
    """
    success = AlertaService.delete_alerta(
        db=db,
        alerta_id=alerta_id,
        user_id=current_user.user_id
    )

    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Alerta not found"
        )

    return None


# ==================== CONFIGURACION ALERTAS ====================

@router.get("/configuracion/me", response_model=ConfiguracionAlertasResponse)
async def get_mi_configuracion(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get current user's alertas configuration.

    If no configuration exists, creates one with default settings.
    """
    config = ConfiguracionAlertasService.get_or_create_configuracion(
        db=db,
        user_id=current_user.user_id
    )
    return ConfiguracionAlertasResponse.model_validate(config)


@router.get("/configuracion/{user_id}", response_model=ConfiguracionAlertasResponse)
async def get_configuracion_by_user(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(check_permission(["admin"]))
):
    """
    Get alertas configuration for a specific user.

    Requires: admin role
    """
    config = ConfiguracionAlertasService.get_configuracion_by_user(db, user_id)
    if not config:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Configuracion not found for this user"
        )
    return ConfiguracionAlertasResponse.model_validate(config)


@router.post("/configuracion", response_model=ConfiguracionAlertasResponse, status_code=status.HTTP_201_CREATED)
async def create_configuracion(
    configuracion: ConfiguracionAlertasCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(check_permission(["admin"]))
):
    """
    Create alertas configuration for a user.

    Requires: admin role

    Note: Most users will have configuration auto-created on first access.
    This endpoint is for admin control.
    """
    try:
        db_config = ConfiguracionAlertasService.create_configuracion(db, configuracion)
        return ConfiguracionAlertasResponse.model_validate(db_config)
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )


@router.put("/configuracion/me", response_model=ConfiguracionAlertasResponse)
async def update_mi_configuracion(
    configuracion_update: ConfiguracionAlertasUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Update current user's alertas configuration.

    Creates configuration with defaults if it doesn't exist.
    """
    # Get or create config first
    config = ConfiguracionAlertasService.get_or_create_configuracion(
        db=db,
        user_id=current_user.user_id
    )

    # Now update it
    db_config = ConfiguracionAlertasService.update_configuracion(
        db=db,
        user_id=current_user.user_id,
        configuracion_update=configuracion_update
    )

    if not db_config:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Error updating configuration"
        )

    return ConfiguracionAlertasResponse.model_validate(db_config)


@router.put("/configuracion/{user_id}", response_model=ConfiguracionAlertasResponse)
async def update_configuracion_by_user(
    user_id: int,
    configuracion_update: ConfiguracionAlertasUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(check_permission(["admin"]))
):
    """
    Update alertas configuration for a specific user.

    Requires: admin role
    """
    db_config = ConfiguracionAlertasService.update_configuracion(
        db=db,
        user_id=user_id,
        configuracion_update=configuracion_update
    )

    if not db_config:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Configuracion not found for this user"
        )

    return ConfiguracionAlertasResponse.model_validate(db_config)
