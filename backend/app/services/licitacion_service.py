"""
Licitacion service for business logic.
"""
from typing import Optional, List
from sqlalchemy.orm import Session
from sqlalchemy import or_, func, and_
from fastapi import HTTPException, status
from datetime import date, datetime
from math import ceil
from decimal import Decimal

from app.models.licitacion import Licitacion
from app.models.cliente import Cliente
from app.schemas.licitacion import LicitacionCreate, LicitacionUpdate, LicitacionList, LicitacionStats


class LicitacionService:
    """Service class for licitacion operations."""

    @staticmethod
    def get_licitacion_by_id(db: Session, licitacion_id: int) -> Optional[Licitacion]:
        """Get licitacion by ID."""
        return db.query(Licitacion).filter(
            Licitacion.licitacion_id == licitacion_id,
            Licitacion.is_deleted == False
        ).first()

    @staticmethod
    def get_licitacion_by_numero(db: Session, numero_licitacion: str) -> Optional[Licitacion]:
        """Get licitacion by numero."""
        return db.query(Licitacion).filter(
            Licitacion.numero_licitacion == numero_licitacion,
            Licitacion.is_deleted == False
        ).first()

    @staticmethod
    def get_licitaciones(
        db: Session,
        skip: int = 0,
        limit: int = 100,
        cliente_id: Optional[int] = None,
        estado: Optional[str] = None,
        categoria: Optional[str] = None,
        prioridad: Optional[str] = None,
        search: Optional[str] = None,
        fecha_desde: Optional[date] = None,
        fecha_hasta: Optional[date] = None
    ) -> List[Licitacion]:
        """Get list of licitaciones with optional filters."""
        query = db.query(Licitacion).filter(Licitacion.is_deleted == False)

        if cliente_id:
            query = query.filter(Licitacion.cliente_id == cliente_id)

        if estado:
            query = query.filter(Licitacion.estado_licitacion == estado)

        if categoria:
            query = query.filter(Licitacion.categoria == categoria)

        if prioridad:
            query = query.filter(Licitacion.prioridad == prioridad)

        if search:
            search_filter = or_(
                Licitacion.numero_licitacion.ilike(f"%{search}%"),
                Licitacion.nombre_licitacion.ilike(f"%{search}%"),
                Licitacion.descripcion.ilike(f"%{search}%"),
                Licitacion.numero_expediente.ilike(f"%{search}%")
            )
            query = query.filter(search_filter)

        if fecha_desde:
            query = query.filter(Licitacion.fecha_presentacion >= fecha_desde)

        if fecha_hasta:
            query = query.filter(Licitacion.fecha_presentacion <= fecha_hasta)

        return query.order_by(Licitacion.fecha_presentacion.desc()).offset(skip).limit(limit).all()

    @staticmethod
    def get_licitaciones_paginated(
        db: Session,
        page: int = 1,
        page_size: int = 20,
        cliente_id: Optional[int] = None,
        estado: Optional[str] = None,
        categoria: Optional[str] = None,
        prioridad: Optional[str] = None,
        search: Optional[str] = None,
        fecha_desde: Optional[date] = None,
        fecha_hasta: Optional[date] = None,
        order_by: str = "fecha_presentacion",
        order_desc: bool = True
    ) -> LicitacionList:
        """Get paginated list of licitaciones."""
        query = db.query(Licitacion).filter(Licitacion.is_deleted == False)

        # Apply filters
        if cliente_id:
            query = query.filter(Licitacion.cliente_id == cliente_id)

        if estado:
            query = query.filter(Licitacion.estado_licitacion == estado)

        if categoria:
            query = query.filter(Licitacion.categoria == categoria)

        if prioridad:
            query = query.filter(Licitacion.prioridad == prioridad)

        if search:
            search_filter = or_(
                Licitacion.numero_licitacion.ilike(f"%{search}%"),
                Licitacion.nombre_licitacion.ilike(f"%{search}%"),
                Licitacion.descripcion.ilike(f"%{search}%"),
                Licitacion.numero_expediente.ilike(f"%{search}%")
            )
            query = query.filter(search_filter)

        if fecha_desde:
            query = query.filter(Licitacion.fecha_presentacion >= fecha_desde)

        if fecha_hasta:
            query = query.filter(Licitacion.fecha_presentacion <= fecha_hasta)

        # Get total count
        total = query.count()

        # Apply ordering
        order_column = getattr(Licitacion, order_by, Licitacion.fecha_presentacion)
        if order_desc:
            query = query.order_by(order_column.desc())
        else:
            query = query.order_by(order_column.asc())

        # Calculate pagination
        total_pages = ceil(total / page_size) if page_size > 0 else 0
        skip = (page - 1) * page_size

        # Get items
        items = query.offset(skip).limit(page_size).all()

        return LicitacionList(
            total=total,
            items=items,
            page=page,
            page_size=page_size,
            total_pages=total_pages
        )

    @staticmethod
    def create_licitacion(db: Session, licitacion_data: LicitacionCreate, user_id: int) -> Licitacion:
        """Create a new licitacion."""
        # Check if numero already exists
        existing = LicitacionService.get_licitacion_by_numero(db, licitacion_data.numero_licitacion)
        if existing:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Número de licitación already exists"
            )

        # Verify cliente exists
        cliente = db.query(Cliente).filter(
            Cliente.cliente_id == licitacion_data.cliente_id,
            Cliente.is_deleted == False
        ).first()

        if not cliente:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Cliente not found"
            )

        # Create licitacion
        db_licitacion = Licitacion(
            **licitacion_data.model_dump(),
            created_by=user_id,
            updated_by=user_id
        )

        db.add(db_licitacion)
        db.commit()
        db.refresh(db_licitacion)

        return db_licitacion

    @staticmethod
    def update_licitacion(
        db: Session,
        licitacion_id: int,
        licitacion_data: LicitacionUpdate,
        user_id: int
    ) -> Licitacion:
        """Update licitacion information."""
        db_licitacion = LicitacionService.get_licitacion_by_id(db, licitacion_id)

        if not db_licitacion:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Licitacion not found"
            )

        # Check numero uniqueness if being updated
        if licitacion_data.numero_licitacion and licitacion_data.numero_licitacion != db_licitacion.numero_licitacion:
            existing = LicitacionService.get_licitacion_by_numero(db, licitacion_data.numero_licitacion)
            if existing:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Número de licitación already exists"
                )

        # Verify cliente exists if being updated
        if licitacion_data.cliente_id and licitacion_data.cliente_id != db_licitacion.cliente_id:
            cliente = db.query(Cliente).filter(
                Cliente.cliente_id == licitacion_data.cliente_id,
                Cliente.is_deleted == False
            ).first()

            if not cliente:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Cliente not found"
                )

        # Update fields
        update_data = licitacion_data.model_dump(exclude_unset=True)
        for field, value in update_data.items():
            setattr(db_licitacion, field, value)

        db_licitacion.updated_by = user_id

        db.commit()
        db.refresh(db_licitacion)

        return db_licitacion

    @staticmethod
    def change_estado(
        db: Session,
        licitacion_id: int,
        nuevo_estado: str,
        user_id: int,
        motivo_rechazo: Optional[str] = None
    ) -> Licitacion:
        """Change licitacion estado."""
        db_licitacion = LicitacionService.get_licitacion_by_id(db, licitacion_id)

        if not db_licitacion:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Licitacion not found"
            )

        # Validate estado transition (you can add more complex validation here)
        allowed_states = [
            "en_preparacion", "presentada", "en_evaluacion", "adjudicada",
            "en_ejecucion", "finalizada", "desierta", "rechazada"
        ]

        if nuevo_estado not in allowed_states:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Invalid estado: {nuevo_estado}"
            )

        db_licitacion.estado_licitacion = nuevo_estado
        db_licitacion.updated_by = user_id

        if nuevo_estado == "rechazada" and motivo_rechazo:
            db_licitacion.motivo_rechazo = motivo_rechazo

        # Update relevant dates
        if nuevo_estado == "adjudicada" and not db_licitacion.fecha_adjudicacion:
            db_licitacion.fecha_adjudicacion = date.today()

        db.commit()
        db.refresh(db_licitacion)

        return db_licitacion

    @staticmethod
    def delete_licitacion(db: Session, licitacion_id: int) -> bool:
        """Soft delete a licitacion."""
        db_licitacion = LicitacionService.get_licitacion_by_id(db, licitacion_id)

        if not db_licitacion:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Licitacion not found"
            )

        # Only allow deletion of licitaciones in certain states
        deletable_states = ["en_preparacion", "desierta", "rechazada"]
        if db_licitacion.estado_licitacion not in deletable_states:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Cannot delete licitacion in estado: {db_licitacion.estado_licitacion}"
            )

        # Soft delete
        db_licitacion.is_deleted = True
        db_licitacion.is_active = False

        db.commit()

        return True

    @staticmethod
    def get_licitaciones_stats(
        db: Session,
        fecha_desde: Optional[date] = None,
        fecha_hasta: Optional[date] = None,
        cliente_id: Optional[int] = None
    ) -> LicitacionStats:
        """Get licitaciones statistics."""
        query = db.query(Licitacion).filter(Licitacion.is_deleted == False)

        if fecha_desde:
            query = query.filter(Licitacion.created_at >= fecha_desde)

        if fecha_hasta:
            query = query.filter(Licitacion.created_at <= fecha_hasta)

        if cliente_id:
            query = query.filter(Licitacion.cliente_id == cliente_id)

        # Total licitaciones
        total = query.count()

        # By estado
        por_estado = {}
        estados = db.query(
            Licitacion.estado_licitacion,
            func.count(Licitacion.licitacion_id)
        ).filter(
            Licitacion.is_deleted == False
        ).group_by(Licitacion.estado_licitacion).all()

        for estado, count in estados:
            por_estado[estado] = count

        # By categoria
        por_categoria = {}
        categorias = db.query(
            Licitacion.categoria,
            func.count(Licitacion.licitacion_id)
        ).filter(
            Licitacion.is_deleted == False,
            Licitacion.categoria.isnot(None)
        ).group_by(Licitacion.categoria).all()

        for categoria, count in categorias:
            por_categoria[categoria] = count

        # Amounts
        monto_ofertado = db.query(
            func.sum(Licitacion.monto_ofertado)
        ).filter(
            Licitacion.is_deleted == False,
            Licitacion.monto_ofertado.isnot(None)
        ).scalar() or Decimal(0)

        monto_adjudicado = db.query(
            func.sum(Licitacion.monto_adjudicado)
        ).filter(
            Licitacion.is_deleted == False,
            Licitacion.estado_licitacion == "adjudicada",
            Licitacion.monto_adjudicado.isnot(None)
        ).scalar() or Decimal(0)

        # Success rate
        adjudicadas = por_estado.get("adjudicada", 0)
        tasa_exito = (adjudicadas / total * 100) if total > 0 else 0

        return LicitacionStats(
            total_licitaciones=total,
            por_estado=por_estado,
            por_categoria=por_categoria,
            monto_total_ofertado=monto_ofertado,
            monto_total_adjudicado=monto_adjudicado,
            tasa_exito=round(tasa_exito, 2)
        )

    @staticmethod
    def get_licitaciones_venciendo(db: Session, dias: int = 15) -> List[Licitacion]:
        """Get licitaciones expiring in X days."""
        from datetime import timedelta
        fecha_limite = date.today() + timedelta(days=dias)

        return db.query(Licitacion).filter(
            Licitacion.is_deleted == False,
            Licitacion.is_active == True,
            Licitacion.estado_licitacion.in_(["en_preparacion", "presentada"]),
            Licitacion.fecha_presentacion.isnot(None),
            Licitacion.fecha_presentacion <= fecha_limite,
            Licitacion.fecha_presentacion >= date.today()
        ).order_by(Licitacion.fecha_presentacion).all()
