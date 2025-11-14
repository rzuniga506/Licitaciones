"""
Ampliaciones and Prorrogas endpoints for contract modifications.
"""
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session

from app.core.security import get_current_user, check_permission
from app.db.session import get_db
from app.models.user import User
from app.schemas.ampliacion import (
    AmpliacionCreate,
    AmpliacionUpdate,
    AmpliacionResponse,
    AmpliacionList,
    ProrrogaCreate,
    ProrrogaUpdate,
    ProrrogaResponse,
    ProrrogaList
)
from app.services.ampliacion_service import AmpliacionService, ProrrogaService

router = APIRouter()


# ==================== AMPLIACIONES ====================

@router.get("/ampliaciones", response_model=AmpliacionList)
async def get_ampliaciones(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    licitacion_id: Optional[int] = Query(None, gt=0),
    tipo_ampliacion: Optional[str] = None,
    estado_ampliacion: Optional[str] = None,
    search: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get list of ampliaciones with filters and pagination.

    Filters:
    - licitacion_id: Filter by licitacion
    - tipo_ampliacion: Filter by tipo (plazo, monto, alcance)
    - estado_ampliacion: Filter by estado (pendiente, aprobada, rechazada, etc.)
    - search: Search in descripcion, justificacion, and observaciones

    Returns paginated list of ampliaciones.
    """
    return AmpliacionService.get_ampliaciones_paginated(
        db=db,
        page=page,
        page_size=page_size,
        licitacion_id=licitacion_id,
        tipo_ampliacion=tipo_ampliacion,
        estado_ampliacion=estado_ampliacion,
        search=search
    )


@router.get("/ampliaciones/{ampliacion_id}", response_model=AmpliacionResponse)
async def get_ampliacion(
    ampliacion_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get ampliacion by ID."""
    ampliacion = AmpliacionService.get_ampliacion_by_id(db, ampliacion_id)
    if not ampliacion:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Ampliacion not found"
        )
    return AmpliacionResponse.model_validate(ampliacion)


@router.post("/ampliaciones", response_model=AmpliacionResponse, status_code=status.HTTP_201_CREATED)
async def create_ampliacion(
    ampliacion: AmpliacionCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(check_permission(["admin", "coordinator", "analyst"]))
):
    """
    Create new ampliacion.

    An ampliacion represents a modification to a contract, such as:
    - Extension of deadline (plazo)
    - Increase in amount (monto)
    - Change in scope (alcance)

    Requires: analyst role or higher
    """
    db_ampliacion = AmpliacionService.create_ampliacion(
        db=db,
        ampliacion=ampliacion,
        user_id=current_user.user_id
    )
    return AmpliacionResponse.model_validate(db_ampliacion)


@router.put("/ampliaciones/{ampliacion_id}", response_model=AmpliacionResponse)
async def update_ampliacion(
    ampliacion_id: int,
    ampliacion_update: AmpliacionUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(check_permission(["admin", "coordinator", "analyst"]))
):
    """
    Update ampliacion.

    Requires: analyst role or higher
    """
    db_ampliacion = AmpliacionService.update_ampliacion(
        db=db,
        ampliacion_id=ampliacion_id,
        ampliacion_update=ampliacion_update,
        user_id=current_user.user_id
    )

    if not db_ampliacion:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Ampliacion not found"
        )

    return AmpliacionResponse.model_validate(db_ampliacion)


@router.patch("/ampliaciones/{ampliacion_id}/approve", response_model=AmpliacionResponse)
async def approve_ampliacion(
    ampliacion_id: int,
    aprobada_por: str = Query(..., min_length=1),
    observaciones_aprobacion: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(check_permission(["admin", "coordinator"]))
):
    """
    Approve an ampliacion.

    Changes estado to 'aprobada' and sets approval metadata.

    Requires: coordinator role or higher
    """
    db_ampliacion = AmpliacionService.approve_ampliacion(
        db=db,
        ampliacion_id=ampliacion_id,
        aprobada_por=aprobada_por,
        observaciones_aprobacion=observaciones_aprobacion,
        user_id=current_user.user_id
    )

    if not db_ampliacion:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Ampliacion not found"
        )

    return AmpliacionResponse.model_validate(db_ampliacion)


@router.patch("/ampliaciones/{ampliacion_id}/reject", response_model=AmpliacionResponse)
async def reject_ampliacion(
    ampliacion_id: int,
    observaciones_aprobacion: str = Query(..., min_length=1, description="Required rejection reason"),
    db: Session = Depends(get_db),
    current_user: User = Depends(check_permission(["admin", "coordinator"]))
):
    """
    Reject an ampliacion.

    Changes estado to 'rechazada' with rejection reason.

    Requires: coordinator role or higher
    """
    db_ampliacion = AmpliacionService.reject_ampliacion(
        db=db,
        ampliacion_id=ampliacion_id,
        observaciones_aprobacion=observaciones_aprobacion,
        user_id=current_user.user_id
    )

    if not db_ampliacion:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Ampliacion not found"
        )

    return AmpliacionResponse.model_validate(db_ampliacion)


@router.delete("/ampliaciones/{ampliacion_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_ampliacion(
    ampliacion_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(check_permission(["admin", "coordinator"]))
):
    """
    Delete ampliacion (soft delete).

    Requires: coordinator role or higher
    """
    success = AmpliacionService.delete_ampliacion(
        db=db,
        ampliacion_id=ampliacion_id,
        user_id=current_user.user_id
    )

    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Ampliacion not found"
        )

    return None


# ==================== PRORROGAS ====================

@router.get("/prorrogas", response_model=ProrrogaList)
async def get_prorrogas(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    licitacion_id: Optional[int] = Query(None, gt=0),
    estado_prorroga: Optional[str] = None,
    search: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get list of prorrogas with filters and pagination.

    Filters:
    - licitacion_id: Filter by licitacion
    - estado_prorroga: Filter by estado (pendiente, aprobada, rechazada, etc.)
    - search: Search in descripcion, justificacion, and observaciones

    Returns paginated list of prorrogas.
    """
    return ProrrogaService.get_prorrogas_paginated(
        db=db,
        page=page,
        page_size=page_size,
        licitacion_id=licitacion_id,
        estado_prorroga=estado_prorroga,
        search=search
    )


@router.get("/prorrogas/{prorroga_id}", response_model=ProrrogaResponse)
async def get_prorroga(
    prorroga_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get prorroga by ID."""
    prorroga = ProrrogaService.get_prorroga_by_id(db, prorroga_id)
    if not prorroga:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Prorroga not found"
        )
    return ProrrogaResponse.model_validate(prorroga)


@router.post("/prorrogas", response_model=ProrrogaResponse, status_code=status.HTTP_201_CREATED)
async def create_prorroga(
    prorroga: ProrrogaCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(check_permission(["admin", "coordinator", "analyst"]))
):
    """
    Create new prorroga.

    A prorroga represents a time extension for a contract.
    The system automatically calculates dias_prorrogados from the date difference.

    Requires: analyst role or higher
    """
    db_prorroga = ProrrogaService.create_prorroga(
        db=db,
        prorroga=prorroga,
        user_id=current_user.user_id
    )
    return ProrrogaResponse.model_validate(db_prorroga)


@router.put("/prorrogas/{prorroga_id}", response_model=ProrrogaResponse)
async def update_prorroga(
    prorroga_id: int,
    prorroga_update: ProrrogaUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(check_permission(["admin", "coordinator", "analyst"]))
):
    """
    Update prorroga.

    If dates are updated, dias_prorrogados will be recalculated automatically.

    Requires: analyst role or higher
    """
    db_prorroga = ProrrogaService.update_prorroga(
        db=db,
        prorroga_id=prorroga_id,
        prorroga_update=prorroga_update,
        user_id=current_user.user_id
    )

    if not db_prorroga:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Prorroga not found"
        )

    return ProrrogaResponse.model_validate(db_prorroga)


@router.patch("/prorrogas/{prorroga_id}/approve", response_model=ProrrogaResponse)
async def approve_prorroga(
    prorroga_id: int,
    aprobada_por: str = Query(..., min_length=1),
    observaciones_aprobacion: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(check_permission(["admin", "coordinator"]))
):
    """
    Approve a prorroga.

    Changes estado to 'aprobada' and sets approval metadata.

    Requires: coordinator role or higher
    """
    db_prorroga = ProrrogaService.approve_prorroga(
        db=db,
        prorroga_id=prorroga_id,
        aprobada_por=aprobada_por,
        observaciones_aprobacion=observaciones_aprobacion,
        user_id=current_user.user_id
    )

    if not db_prorroga:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Prorroga not found"
        )

    return ProrrogaResponse.model_validate(db_prorroga)


@router.patch("/prorrogas/{prorroga_id}/reject", response_model=ProrrogaResponse)
async def reject_prorroga(
    prorroga_id: int,
    observaciones_aprobacion: str = Query(..., min_length=1, description="Required rejection reason"),
    db: Session = Depends(get_db),
    current_user: User = Depends(check_permission(["admin", "coordinator"]))
):
    """
    Reject a prorroga.

    Changes estado to 'rechazada' with rejection reason.

    Requires: coordinator role or higher
    """
    db_prorroga = ProrrogaService.reject_prorroga(
        db=db,
        prorroga_id=prorroga_id,
        observaciones_aprobacion=observaciones_aprobacion,
        user_id=current_user.user_id
    )

    if not db_prorroga:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Prorroga not found"
        )

    return ProrrogaResponse.model_validate(db_prorroga)


@router.delete("/prorrogas/{prorroga_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_prorroga(
    prorroga_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(check_permission(["admin", "coordinator"]))
):
    """
    Delete prorroga (soft delete).

    Requires: coordinator role or higher
    """
    success = ProrrogaService.delete_prorroga(
        db=db,
        prorroga_id=prorroga_id,
        user_id=current_user.user_id
    )

    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Prorroga not found"
        )

    return None
