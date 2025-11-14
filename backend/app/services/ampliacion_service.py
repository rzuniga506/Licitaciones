"""
Ampliacion and Prorroga service for business logic.
"""
from typing import Optional, List
from sqlalchemy.orm import Session
from sqlalchemy import or_
from datetime import date
from math import ceil

from app.models.ampliacion import Ampliacion, Prorroga
from app.schemas.ampliacion import (
    AmpliacionCreate,
    AmpliacionUpdate,
    AmpliacionList,
    AmpliacionResponse,
    ProrrogaCreate,
    ProrrogaUpdate,
    ProrrogaList,
    ProrrogaResponse
)


class AmpliacionService:
    """Service for ampliacion operations."""

    @staticmethod
    def get_ampliaciones_paginated(
        db: Session,
        page: int = 1,
        page_size: int = 20,
        licitacion_id: Optional[int] = None,
        tipo_ampliacion: Optional[str] = None,
        estado_ampliacion: Optional[str] = None,
        search: Optional[str] = None
    ) -> AmpliacionList:
        """Get paginated list of ampliaciones with filters."""
        query = db.query(Ampliacion).filter(Ampliacion.is_deleted == False)

        # Apply filters
        if licitacion_id:
            query = query.filter(Ampliacion.licitacion_id == licitacion_id)

        if tipo_ampliacion:
            query = query.filter(Ampliacion.tipo_ampliacion == tipo_ampliacion)

        if estado_ampliacion:
            query = query.filter(Ampliacion.estado_ampliacion == estado_ampliacion)

        if search:
            search_filter = f"%{search}%"
            query = query.filter(
                or_(
                    Ampliacion.descripcion.ilike(search_filter),
                    Ampliacion.justificacion.ilike(search_filter),
                    Ampliacion.observaciones.ilike(search_filter)
                )
            )

        # Get total count
        total = query.count()

        # Calculate pagination
        total_pages = ceil(total / page_size) if total > 0 else 0
        offset = (page - 1) * page_size

        # Get paginated results ordered by creation date
        items = query.order_by(Ampliacion.created_at.desc()).offset(offset).limit(page_size).all()

        return AmpliacionList(
            total=total,
            items=[AmpliacionResponse.model_validate(item) for item in items],
            page=page,
            page_size=page_size,
            total_pages=total_pages
        )

    @staticmethod
    def get_ampliacion_by_id(db: Session, ampliacion_id: int) -> Optional[Ampliacion]:
        """Get ampliacion by ID."""
        return db.query(Ampliacion).filter(
            Ampliacion.ampliacion_id == ampliacion_id,
            Ampliacion.is_deleted == False
        ).first()

    @staticmethod
    def create_ampliacion(
        db: Session,
        ampliacion: AmpliacionCreate,
        user_id: int
    ) -> Ampliacion:
        """Create new ampliacion."""
        db_ampliacion = Ampliacion(
            **ampliacion.model_dump(exclude_unset=True),
            created_by=user_id
        )

        db.add(db_ampliacion)
        db.commit()
        db.refresh(db_ampliacion)
        return db_ampliacion

    @staticmethod
    def update_ampliacion(
        db: Session,
        ampliacion_id: int,
        ampliacion_update: AmpliacionUpdate,
        user_id: int
    ) -> Optional[Ampliacion]:
        """Update ampliacion."""
        db_ampliacion = AmpliacionService.get_ampliacion_by_id(db, ampliacion_id)
        if not db_ampliacion:
            return None

        update_data = ampliacion_update.model_dump(exclude_unset=True)
        for field, value in update_data.items():
            setattr(db_ampliacion, field, value)

        db_ampliacion.updated_by = user_id
        db.commit()
        db.refresh(db_ampliacion)
        return db_ampliacion

    @staticmethod
    def delete_ampliacion(db: Session, ampliacion_id: int, user_id: int) -> bool:
        """Soft delete ampliacion."""
        db_ampliacion = AmpliacionService.get_ampliacion_by_id(db, ampliacion_id)
        if not db_ampliacion:
            return False

        db_ampliacion.is_deleted = True
        db_ampliacion.updated_by = user_id
        db.commit()
        return True

    @staticmethod
    def approve_ampliacion(
        db: Session,
        ampliacion_id: int,
        aprobada_por: str,
        observaciones_aprobacion: Optional[str],
        user_id: int
    ) -> Optional[Ampliacion]:
        """Approve an ampliacion."""
        db_ampliacion = AmpliacionService.get_ampliacion_by_id(db, ampliacion_id)
        if not db_ampliacion:
            return None

        db_ampliacion.estado_ampliacion = "aprobada"
        db_ampliacion.fecha_aprobacion = date.today()
        db_ampliacion.aprobada_por = aprobada_por
        db_ampliacion.observaciones_aprobacion = observaciones_aprobacion
        db_ampliacion.updated_by = user_id

        db.commit()
        db.refresh(db_ampliacion)
        return db_ampliacion

    @staticmethod
    def reject_ampliacion(
        db: Session,
        ampliacion_id: int,
        observaciones_aprobacion: str,
        user_id: int
    ) -> Optional[Ampliacion]:
        """Reject an ampliacion."""
        db_ampliacion = AmpliacionService.get_ampliacion_by_id(db, ampliacion_id)
        if not db_ampliacion:
            return None

        db_ampliacion.estado_ampliacion = "rechazada"
        db_ampliacion.observaciones_aprobacion = observaciones_aprobacion
        db_ampliacion.updated_by = user_id

        db.commit()
        db.refresh(db_ampliacion)
        return db_ampliacion


class ProrrogaService:
    """Service for prorroga operations."""

    @staticmethod
    def get_prorrogas_paginated(
        db: Session,
        page: int = 1,
        page_size: int = 20,
        licitacion_id: Optional[int] = None,
        estado_prorroga: Optional[str] = None,
        search: Optional[str] = None
    ) -> ProrrogaList:
        """Get paginated list of prorrogas with filters."""
        query = db.query(Prorroga).filter(Prorroga.is_deleted == False)

        # Apply filters
        if licitacion_id:
            query = query.filter(Prorroga.licitacion_id == licitacion_id)

        if estado_prorroga:
            query = query.filter(Prorroga.estado_prorroga == estado_prorroga)

        if search:
            search_filter = f"%{search}%"
            query = query.filter(
                or_(
                    Prorroga.descripcion.ilike(search_filter),
                    Prorroga.justificacion.ilike(search_filter),
                    Prorroga.observaciones.ilike(search_filter)
                )
            )

        # Get total count
        total = query.count()

        # Calculate pagination
        total_pages = ceil(total / page_size) if total > 0 else 0
        offset = (page - 1) * page_size

        # Get paginated results ordered by creation date
        items = query.order_by(Prorroga.created_at.desc()).offset(offset).limit(page_size).all()

        return ProrrogaList(
            total=total,
            items=[ProrrogaResponse.model_validate(item) for item in items],
            page=page,
            page_size=page_size,
            total_pages=total_pages
        )

    @staticmethod
    def get_prorroga_by_id(db: Session, prorroga_id: int) -> Optional[Prorroga]:
        """Get prorroga by ID."""
        return db.query(Prorroga).filter(
            Prorroga.prorroga_id == prorroga_id,
            Prorroga.is_deleted == False
        ).first()

    @staticmethod
    def create_prorroga(
        db: Session,
        prorroga: ProrrogaCreate,
        user_id: int
    ) -> Prorroga:
        """Create new prorroga."""
        # Calculate dias_prorrogados if both dates provided
        prorroga_data = prorroga.model_dump(exclude_unset=True)

        if prorroga.fecha_fin_anterior and prorroga.fecha_fin_nueva:
            dias = (prorroga.fecha_fin_nueva - prorroga.fecha_fin_anterior).days
            prorroga_data['dias_prorrogados'] = dias

        db_prorroga = Prorroga(
            **prorroga_data,
            created_by=user_id
        )

        db.add(db_prorroga)
        db.commit()
        db.refresh(db_prorroga)
        return db_prorroga

    @staticmethod
    def update_prorroga(
        db: Session,
        prorroga_id: int,
        prorroga_update: ProrrogaUpdate,
        user_id: int
    ) -> Optional[Prorroga]:
        """Update prorroga."""
        db_prorroga = ProrrogaService.get_prorroga_by_id(db, prorroga_id)
        if not db_prorroga:
            return None

        update_data = prorroga_update.model_dump(exclude_unset=True)

        # Recalculate dias_prorrogados if dates are updated
        if 'fecha_fin_anterior' in update_data or 'fecha_fin_nueva' in update_data:
            fecha_anterior = update_data.get('fecha_fin_anterior', db_prorroga.fecha_fin_anterior)
            fecha_nueva = update_data.get('fecha_fin_nueva', db_prorroga.fecha_fin_nueva)

            if fecha_anterior and fecha_nueva:
                update_data['dias_prorrogados'] = (fecha_nueva - fecha_anterior).days

        for field, value in update_data.items():
            setattr(db_prorroga, field, value)

        db_prorroga.updated_by = user_id
        db.commit()
        db.refresh(db_prorroga)
        return db_prorroga

    @staticmethod
    def delete_prorroga(db: Session, prorroga_id: int, user_id: int) -> bool:
        """Soft delete prorroga."""
        db_prorroga = ProrrogaService.get_prorroga_by_id(db, prorroga_id)
        if not db_prorroga:
            return False

        db_prorroga.is_deleted = True
        db_prorroga.updated_by = user_id
        db.commit()
        return True

    @staticmethod
    def approve_prorroga(
        db: Session,
        prorroga_id: int,
        aprobada_por: str,
        observaciones_aprobacion: Optional[str],
        user_id: int
    ) -> Optional[Prorroga]:
        """Approve a prorroga."""
        db_prorroga = ProrrogaService.get_prorroga_by_id(db, prorroga_id)
        if not db_prorroga:
            return None

        db_prorroga.estado_prorroga = "aprobada"
        db_prorroga.fecha_aprobacion = date.today()
        db_prorroga.aprobada_por = aprobada_por
        db_prorroga.observaciones_aprobacion = observaciones_aprobacion
        db_prorroga.updated_by = user_id

        db.commit()
        db.refresh(db_prorroga)
        return db_prorroga

    @staticmethod
    def reject_prorroga(
        db: Session,
        prorroga_id: int,
        observaciones_aprobacion: str,
        user_id: int
    ) -> Optional[Prorroga]:
        """Reject a prorroga."""
        db_prorroga = ProrrogaService.get_prorroga_by_id(db, prorroga_id)
        if not db_prorroga:
            return None

        db_prorroga.estado_prorroga = "rechazada"
        db_prorroga.observaciones_aprobacion = observaciones_aprobacion
        db_prorroga.updated_by = user_id

        db.commit()
        db.refresh(db_prorroga)
        return db_prorroga
