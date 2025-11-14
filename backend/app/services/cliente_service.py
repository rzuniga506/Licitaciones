"""
Cliente service for business logic.
"""
from typing import Optional, List
from sqlalchemy.orm import Session
from sqlalchemy import or_, func
from fastapi import HTTPException, status
from math import ceil

from app.models.cliente import Cliente
from app.schemas.cliente import ClienteCreate, ClienteUpdate, ClienteList


class ClienteService:
    """Service class for cliente operations."""

    @staticmethod
    def get_cliente_by_id(db: Session, cliente_id: int) -> Optional[Cliente]:
        """Get cliente by ID."""
        return db.query(Cliente).filter(
            Cliente.cliente_id == cliente_id,
            Cliente.is_deleted == False
        ).first()

    @staticmethod
    def get_cliente_by_identificacion(db: Session, identificacion: str) -> Optional[Cliente]:
        """Get cliente by identificacion."""
        return db.query(Cliente).filter(
            Cliente.identificacion == identificacion,
            Cliente.is_deleted == False
        ).first()

    @staticmethod
    def get_clientes(
        db: Session,
        skip: int = 0,
        limit: int = 100,
        tipo_cliente: Optional[str] = None,
        is_active: Optional[bool] = None,
        search: Optional[str] = None
    ) -> List[Cliente]:
        """Get list of clientes with optional filters."""
        query = db.query(Cliente).filter(Cliente.is_deleted == False)

        if tipo_cliente:
            query = query.filter(Cliente.tipo_cliente == tipo_cliente)

        if is_active is not None:
            query = query.filter(Cliente.is_active == is_active)

        if search:
            search_filter = or_(
                Cliente.nombre_cliente.ilike(f"%{search}%"),
                Cliente.identificacion.ilike(f"%{search}%"),
                Cliente.email.ilike(f"%{search}%"),
                Cliente.contacto_principal.ilike(f"%{search}%")
            )
            query = query.filter(search_filter)

        return query.order_by(Cliente.nombre_cliente).offset(skip).limit(limit).all()

    @staticmethod
    def get_clientes_paginated(
        db: Session,
        page: int = 1,
        page_size: int = 20,
        tipo_cliente: Optional[str] = None,
        is_active: Optional[bool] = None,
        search: Optional[str] = None
    ) -> ClienteList:
        """Get paginated list of clientes."""
        query = db.query(Cliente).filter(Cliente.is_deleted == False)

        if tipo_cliente:
            query = query.filter(Cliente.tipo_cliente == tipo_cliente)

        if is_active is not None:
            query = query.filter(Cliente.is_active == is_active)

        if search:
            search_filter = or_(
                Cliente.nombre_cliente.ilike(f"%{search}%"),
                Cliente.identificacion.ilike(f"%{search}%"),
                Cliente.email.ilike(f"%{search}%"),
                Cliente.contacto_principal.ilike(f"%{search}%")
            )
            query = query.filter(search_filter)

        # Get total count
        total = query.count()

        # Calculate pagination
        total_pages = ceil(total / page_size) if page_size > 0 else 0
        skip = (page - 1) * page_size

        # Get items
        items = query.order_by(Cliente.nombre_cliente).offset(skip).limit(page_size).all()

        return ClienteList(
            total=total,
            items=items,
            page=page,
            page_size=page_size,
            total_pages=total_pages
        )

    @staticmethod
    def create_cliente(db: Session, cliente_data: ClienteCreate, user_id: int) -> Cliente:
        """Create a new cliente."""
        # Check if identificacion already exists
        if cliente_data.identificacion:
            existing = ClienteService.get_cliente_by_identificacion(db, cliente_data.identificacion)
            if existing:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Identificación already registered"
                )

        # Create cliente
        db_cliente = Cliente(
            **cliente_data.model_dump(),
            created_by=user_id
        )

        db.add(db_cliente)
        db.commit()
        db.refresh(db_cliente)

        return db_cliente

    @staticmethod
    def update_cliente(db: Session, cliente_id: int, cliente_data: ClienteUpdate) -> Cliente:
        """Update cliente information."""
        db_cliente = ClienteService.get_cliente_by_id(db, cliente_id)

        if not db_cliente:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Cliente not found"
            )

        # Check identificacion uniqueness if being updated
        if cliente_data.identificacion and cliente_data.identificacion != db_cliente.identificacion:
            existing = ClienteService.get_cliente_by_identificacion(db, cliente_data.identificacion)
            if existing:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Identificación already registered"
                )

        # Update fields
        update_data = cliente_data.model_dump(exclude_unset=True)
        for field, value in update_data.items():
            setattr(db_cliente, field, value)

        db.commit()
        db.refresh(db_cliente)

        return db_cliente

    @staticmethod
    def delete_cliente(db: Session, cliente_id: int) -> bool:
        """Soft delete a cliente."""
        db_cliente = ClienteService.get_cliente_by_id(db, cliente_id)

        if not db_cliente:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Cliente not found"
            )

        # Check if cliente has active licitaciones
        from app.models.licitacion import Licitacion
        active_licitaciones = db.query(Licitacion).filter(
            Licitacion.cliente_id == cliente_id,
            Licitacion.is_deleted == False,
            Licitacion.is_active == True
        ).count()

        if active_licitaciones > 0:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Cannot delete cliente with {active_licitaciones} active licitaciones"
            )

        # Soft delete
        db_cliente.is_deleted = True
        db_cliente.is_active = False

        db.commit()

        return True

    @staticmethod
    def get_cliente_stats(db: Session, cliente_id: int) -> dict:
        """Get statistics for a cliente."""
        from app.models.licitacion import Licitacion

        cliente = ClienteService.get_cliente_by_id(db, cliente_id)
        if not cliente:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Cliente not found"
            )

        # Get licitaciones stats
        total_licitaciones = db.query(Licitacion).filter(
            Licitacion.cliente_id == cliente_id,
            Licitacion.is_deleted == False
        ).count()

        adjudicadas = db.query(Licitacion).filter(
            Licitacion.cliente_id == cliente_id,
            Licitacion.estado_licitacion == "adjudicada",
            Licitacion.is_deleted == False
        ).count()

        en_proceso = db.query(Licitacion).filter(
            Licitacion.cliente_id == cliente_id,
            Licitacion.estado_licitacion.in_(["en_preparacion", "presentada", "en_evaluacion"]),
            Licitacion.is_deleted == False
        ).count()

        # Calculate amounts
        from sqlalchemy import func
        monto_total = db.query(func.sum(Licitacion.monto_adjudicado)).filter(
            Licitacion.cliente_id == cliente_id,
            Licitacion.estado_licitacion == "adjudicada",
            Licitacion.is_deleted == False
        ).scalar() or 0

        return {
            "cliente_id": cliente_id,
            "nombre_cliente": cliente.nombre_cliente,
            "total_licitaciones": total_licitaciones,
            "licitaciones_adjudicadas": adjudicadas,
            "licitaciones_en_proceso": en_proceso,
            "monto_total_adjudicado": float(monto_total),
            "tasa_exito": (adjudicadas / total_licitaciones * 100) if total_licitaciones > 0 else 0
        }
