"""
CRM service for Contacto and InteraccionCliente business logic.
"""
from typing import Optional, List
from sqlalchemy.orm import Session
from sqlalchemy import or_, and_
from datetime import datetime, date
from math import ceil

from app.models.crm import Contacto, InteraccionCliente
from app.schemas.crm import (
    ContactoCreate,
    ContactoUpdate,
    ContactoList,
    ContactoResponse,
    InteraccionClienteCreate,
    InteraccionClienteUpdate,
    InteraccionClienteList,
    InteraccionClienteResponse
)


class ContactoService:
    """Service for contacto operations."""

    @staticmethod
    def get_contactos_paginated(
        db: Session,
        page: int = 1,
        page_size: int = 20,
        cliente_id: Optional[int] = None,
        is_active: Optional[bool] = None,
        es_contacto_principal: Optional[bool] = None,
        nivel_decision: Optional[str] = None,
        search: Optional[str] = None
    ) -> ContactoList:
        """Get paginated list of contactos with filters."""
        query = db.query(Contacto).filter(Contacto.is_deleted == False)

        # Apply filters
        if cliente_id:
            query = query.filter(Contacto.cliente_id == cliente_id)

        if is_active is not None:
            query = query.filter(Contacto.is_active == is_active)

        if es_contacto_principal is not None:
            query = query.filter(Contacto.es_contacto_principal == es_contacto_principal)

        if nivel_decision:
            query = query.filter(Contacto.nivel_decision == nivel_decision)

        if search:
            search_filter = f"%{search}%"
            query = query.filter(
                or_(
                    Contacto.nombre_contacto.ilike(search_filter),
                    Contacto.cargo.ilike(search_filter),
                    Contacto.email.ilike(search_filter),
                    Contacto.telefono.ilike(search_filter),
                    Contacto.departamento.ilike(search_filter)
                )
            )

        # Get total count
        total = query.count()

        # Calculate pagination
        total_pages = ceil(total / page_size) if total > 0 else 0
        offset = (page - 1) * page_size

        # Get paginated results ordered by nombre
        items = query.order_by(Contacto.nombre_contacto).offset(offset).limit(page_size).all()

        return ContactoList(
            total=total,
            items=[ContactoResponse.model_validate(item) for item in items],
            page=page,
            page_size=page_size,
            total_pages=total_pages
        )

    @staticmethod
    def get_contacto_by_id(db: Session, contacto_id: int) -> Optional[Contacto]:
        """Get contacto by ID."""
        return db.query(Contacto).filter(
            Contacto.contacto_id == contacto_id,
            Contacto.is_deleted == False
        ).first()

    @staticmethod
    def create_contacto(
        db: Session,
        contacto: ContactoCreate,
        user_id: int
    ) -> Contacto:
        """Create new contacto."""
        # If this is set as principal, unset other principal contacts for this cliente
        if contacto.es_contacto_principal:
            db.query(Contacto).filter(
                Contacto.cliente_id == contacto.cliente_id,
                Contacto.es_contacto_principal == True,
                Contacto.is_deleted == False
            ).update({Contacto.es_contacto_principal: False})

        db_contacto = Contacto(
            **contacto.model_dump(exclude_unset=True),
            created_by=user_id
        )

        db.add(db_contacto)
        db.commit()
        db.refresh(db_contacto)
        return db_contacto

    @staticmethod
    def update_contacto(
        db: Session,
        contacto_id: int,
        contacto_update: ContactoUpdate,
        user_id: int
    ) -> Optional[Contacto]:
        """Update contacto."""
        db_contacto = ContactoService.get_contacto_by_id(db, contacto_id)
        if not db_contacto:
            return None

        update_data = contacto_update.model_dump(exclude_unset=True)

        # If setting as principal, unset other principal contacts for this cliente
        if update_data.get('es_contacto_principal') == True:
            db.query(Contacto).filter(
                Contacto.cliente_id == db_contacto.cliente_id,
                Contacto.contacto_id != contacto_id,
                Contacto.es_contacto_principal == True,
                Contacto.is_deleted == False
            ).update({Contacto.es_contacto_principal: False})

        for field, value in update_data.items():
            setattr(db_contacto, field, value)

        db_contacto.updated_by = user_id
        db.commit()
        db.refresh(db_contacto)
        return db_contacto

    @staticmethod
    def delete_contacto(db: Session, contacto_id: int, user_id: int) -> bool:
        """Soft delete contacto."""
        db_contacto = ContactoService.get_contacto_by_id(db, contacto_id)
        if not db_contacto:
            return False

        db_contacto.is_deleted = True
        db_contacto.updated_by = user_id
        db.commit()
        return True


class InteraccionClienteService:
    """Service for interaccion cliente operations."""

    @staticmethod
    def get_interacciones_paginated(
        db: Session,
        page: int = 1,
        page_size: int = 20,
        cliente_id: Optional[int] = None,
        contacto_id: Optional[int] = None,
        tipo_interaccion: Optional[str] = None,
        requiere_seguimiento: Optional[bool] = None,
        fecha_desde: Optional[datetime] = None,
        fecha_hasta: Optional[datetime] = None,
        search: Optional[str] = None
    ) -> InteraccionClienteList:
        """Get paginated list of interacciones with filters."""
        query = db.query(InteraccionCliente).filter(InteraccionCliente.is_deleted == False)

        # Apply filters
        if cliente_id:
            query = query.filter(InteraccionCliente.cliente_id == cliente_id)

        if contacto_id:
            query = query.filter(InteraccionCliente.contacto_id == contacto_id)

        if tipo_interaccion:
            query = query.filter(InteraccionCliente.tipo_interaccion == tipo_interaccion)

        if requiere_seguimiento is not None:
            query = query.filter(InteraccionCliente.requiere_seguimiento == requiere_seguimiento)

        if fecha_desde:
            query = query.filter(InteraccionCliente.fecha_interaccion >= fecha_desde)

        if fecha_hasta:
            query = query.filter(InteraccionCliente.fecha_interaccion <= fecha_hasta)

        if search:
            search_filter = f"%{search}%"
            query = query.filter(
                or_(
                    InteraccionCliente.descripcion.ilike(search_filter),
                    InteraccionCliente.resultado.ilike(search_filter),
                    InteraccionCliente.proximos_pasos.ilike(search_filter),
                    InteraccionCliente.notas_adicionales.ilike(search_filter)
                )
            )

        # Get total count
        total = query.count()

        # Calculate pagination
        total_pages = ceil(total / page_size) if total > 0 else 0
        offset = (page - 1) * page_size

        # Get paginated results ordered by fecha_interaccion desc
        items = query.order_by(InteraccionCliente.fecha_interaccion.desc()).offset(offset).limit(page_size).all()

        return InteraccionClienteList(
            total=total,
            items=[InteraccionClienteResponse.model_validate(item) for item in items],
            page=page,
            page_size=page_size,
            total_pages=total_pages
        )

    @staticmethod
    def get_interaccion_by_id(db: Session, interaccion_id: int) -> Optional[InteraccionCliente]:
        """Get interaccion by ID."""
        return db.query(InteraccionCliente).filter(
            InteraccionCliente.interaccion_id == interaccion_id,
            InteraccionCliente.is_deleted == False
        ).first()

    @staticmethod
    def create_interaccion(
        db: Session,
        interaccion: InteraccionClienteCreate,
        user_id: int
    ) -> InteraccionCliente:
        """Create new interaccion."""
        db_interaccion = InteraccionCliente(
            **interaccion.model_dump(exclude_unset=True),
            created_by=user_id
        )

        db.add(db_interaccion)
        db.commit()
        db.refresh(db_interaccion)
        return db_interaccion

    @staticmethod
    def update_interaccion(
        db: Session,
        interaccion_id: int,
        interaccion_update: InteraccionClienteUpdate,
        user_id: int
    ) -> Optional[InteraccionCliente]:
        """Update interaccion."""
        db_interaccion = InteraccionClienteService.get_interaccion_by_id(db, interaccion_id)
        if not db_interaccion:
            return None

        update_data = interaccion_update.model_dump(exclude_unset=True)
        for field, value in update_data.items():
            setattr(db_interaccion, field, value)

        db_interaccion.updated_by = user_id
        db.commit()
        db.refresh(db_interaccion)
        return db_interaccion

    @staticmethod
    def delete_interaccion(db: Session, interaccion_id: int, user_id: int) -> bool:
        """Soft delete interaccion."""
        db_interaccion = InteraccionClienteService.get_interaccion_by_id(db, interaccion_id)
        if not db_interaccion:
            return False

        db_interaccion.is_deleted = True
        db_interaccion.updated_by = user_id
        db.commit()
        return True

    @staticmethod
    def get_interacciones_pendientes_seguimiento(
        db: Session,
        dias_vencimiento: int = 7
    ) -> List[InteraccionCliente]:
        """
        Get interacciones that require follow-up within X days.

        Args:
            db: Database session
            dias_vencimiento: Number of days to look ahead (default 7)

        Returns:
            List of interacciones requiring follow-up soon
        """
        from datetime import timedelta
        fecha_limite = date.today() + timedelta(days=dias_vencimiento)

        return db.query(InteraccionCliente).filter(
            InteraccionCliente.is_deleted == False,
            InteraccionCliente.requiere_seguimiento == True,
            InteraccionCliente.fecha_seguimiento.isnot(None),
            InteraccionCliente.fecha_seguimiento <= fecha_limite,
            InteraccionCliente.fecha_seguimiento >= date.today()
        ).order_by(InteraccionCliente.fecha_seguimiento).all()
