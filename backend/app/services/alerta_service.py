"""
Alerta and ConfiguracionAlertas service for business logic.
"""
from typing import Optional, Dict
from sqlalchemy.orm import Session
from sqlalchemy import or_, func
from datetime import datetime
from math import ceil

from app.models.alerta import Alerta, ConfiguracionAlertas
from app.schemas.alerta import (
    AlertaCreate,
    AlertaUpdate,
    AlertaList,
    AlertaResponse,
    AlertaStats,
    ConfiguracionAlertasCreate,
    ConfiguracionAlertasUpdate,
    ConfiguracionAlertasResponse
)


class AlertaService:
    """Service for alerta operations."""

    @staticmethod
    def get_alertas_paginated(
        db: Session,
        page: int = 1,
        page_size: int = 20,
        user_id: Optional[int] = None,
        tipo_alerta: Optional[str] = None,
        estado_alerta: Optional[str] = None,
        nivel_prioridad: Optional[str] = None,
        requiere_accion: Optional[bool] = None,
        licitacion_id: Optional[int] = None,
        cliente_id: Optional[int] = None,
        search: Optional[str] = None
    ) -> AlertaList:
        """Get paginated list of alertas with filters."""
        query = db.query(Alerta).filter(Alerta.is_deleted == False)

        # Apply filters
        if user_id:
            query = query.filter(Alerta.user_id == user_id)

        if tipo_alerta:
            query = query.filter(Alerta.tipo_alerta == tipo_alerta)

        if estado_alerta:
            query = query.filter(Alerta.estado_alerta == estado_alerta)

        if nivel_prioridad:
            query = query.filter(Alerta.nivel_prioridad == nivel_prioridad)

        if requiere_accion is not None:
            query = query.filter(Alerta.requiere_accion == requiere_accion)

        if licitacion_id:
            query = query.filter(Alerta.licitacion_id == licitacion_id)

        if cliente_id:
            query = query.filter(Alerta.cliente_id == cliente_id)

        if search:
            search_filter = f"%{search}%"
            query = query.filter(
                or_(
                    Alerta.titulo.ilike(search_filter),
                    Alerta.mensaje.ilike(search_filter),
                    Alerta.accion_sugerida.ilike(search_filter)
                )
            )

        # Get total count
        total = query.count()

        # Calculate pagination
        total_pages = ceil(total / page_size) if total > 0 else 0
        offset = (page - 1) * page_size

        # Get paginated results ordered by prioridad and fecha
        # Order by: critical first, then by date (newest first)
        priority_order = {
            'critica': 1,
            'alta': 2,
            'media': 3,
            'baja': 4
        }

        items = query.order_by(
            Alerta.fecha_alerta.desc()
        ).offset(offset).limit(page_size).all()

        # Sort by priority in Python (since we can't use CASE in SQLAlchemy easily here)
        items.sort(key=lambda x: (priority_order.get(x.nivel_prioridad, 5), -x.fecha_alerta.timestamp()))

        return AlertaList(
            total=total,
            items=[AlertaResponse.model_validate(item) for item in items[:page_size]],
            page=page,
            page_size=page_size,
            total_pages=total_pages
        )

    @staticmethod
    def get_alerta_by_id(db: Session, alerta_id: int) -> Optional[Alerta]:
        """Get alerta by ID."""
        return db.query(Alerta).filter(
            Alerta.alerta_id == alerta_id,
            Alerta.is_deleted == False
        ).first()

    @staticmethod
    def create_alerta(
        db: Session,
        alerta: AlertaCreate,
        user_id: int
    ) -> Alerta:
        """Create new alerta."""
        db_alerta = Alerta(
            **alerta.model_dump(exclude_unset=True),
            created_by=user_id
        )

        db.add(db_alerta)
        db.commit()
        db.refresh(db_alerta)
        return db_alerta

    @staticmethod
    def update_alerta(
        db: Session,
        alerta_id: int,
        alerta_update: AlertaUpdate,
        user_id: int
    ) -> Optional[Alerta]:
        """Update alerta."""
        db_alerta = AlertaService.get_alerta_by_id(db, alerta_id)
        if not db_alerta:
            return None

        update_data = alerta_update.model_dump(exclude_unset=True)

        # Set timestamps based on estado changes
        if 'estado_alerta' in update_data:
            if update_data['estado_alerta'] == 'leida' and not db_alerta.fecha_leida:
                update_data['fecha_leida'] = datetime.now()
            elif update_data['estado_alerta'] == 'resuelta' and not db_alerta.fecha_resuelta:
                update_data['fecha_resuelta'] = datetime.now()
            elif update_data['estado_alerta'] == 'descartada' and not db_alerta.fecha_descartada:
                update_data['fecha_descartada'] = datetime.now()

        for field, value in update_data.items():
            setattr(db_alerta, field, value)

        db_alerta.updated_by = user_id
        db.commit()
        db.refresh(db_alerta)
        return db_alerta

    @staticmethod
    def delete_alerta(db: Session, alerta_id: int, user_id: int) -> bool:
        """Soft delete alerta."""
        db_alerta = AlertaService.get_alerta_by_id(db, alerta_id)
        if not db_alerta:
            return False

        db_alerta.is_deleted = True
        db_alerta.updated_by = user_id
        db.commit()
        return True

    @staticmethod
    def marcar_como_leida(db: Session, alerta_id: int, user_id: int) -> Optional[Alerta]:
        """Mark alerta as read."""
        db_alerta = AlertaService.get_alerta_by_id(db, alerta_id)
        if not db_alerta:
            return None

        db_alerta.estado_alerta = "leida"
        if not db_alerta.fecha_leida:
            db_alerta.fecha_leida = datetime.now()
        db_alerta.updated_by = user_id

        db.commit()
        db.refresh(db_alerta)
        return db_alerta

    @staticmethod
    def marcar_como_resuelta(
        db: Session,
        alerta_id: int,
        user_id: int,
        notas: Optional[str] = None
    ) -> Optional[Alerta]:
        """Mark alerta as resolved."""
        db_alerta = AlertaService.get_alerta_by_id(db, alerta_id)
        if not db_alerta:
            return None

        db_alerta.estado_alerta = "resuelta"
        if not db_alerta.fecha_resuelta:
            db_alerta.fecha_resuelta = datetime.now()
        if notas:
            db_alerta.notas_usuario = notas
        db_alerta.updated_by = user_id

        db.commit()
        db.refresh(db_alerta)
        return db_alerta

    @staticmethod
    def get_alertas_stats(db: Session, user_id: Optional[int] = None) -> AlertaStats:
        """Get alertas statistics."""
        query = db.query(Alerta).filter(Alerta.is_deleted == False)

        if user_id:
            query = query.filter(Alerta.user_id == user_id)

        # Total alertas
        total_alertas = query.count()

        # Por estado
        por_estado: Dict[str, int] = {}
        estados = query.with_entities(
            Alerta.estado_alerta,
            func.count(Alerta.alerta_id)
        ).group_by(Alerta.estado_alerta).all()

        for estado, count in estados:
            por_estado[estado] = count

        # Por tipo
        por_tipo: Dict[str, int] = {}
        tipos = query.with_entities(
            Alerta.tipo_alerta,
            func.count(Alerta.alerta_id)
        ).group_by(Alerta.tipo_alerta).all()

        for tipo, count in tipos:
            por_tipo[tipo] = count

        # Por prioridad
        por_prioridad: Dict[str, int] = {}
        prioridades = query.with_entities(
            Alerta.nivel_prioridad,
            func.count(Alerta.alerta_id)
        ).group_by(Alerta.nivel_prioridad).all()

        for prioridad, count in prioridades:
            por_prioridad[prioridad] = count

        # Activas criticas
        activas_criticas = query.filter(
            Alerta.estado_alerta == "activa",
            Alerta.nivel_prioridad == "critica"
        ).count()

        # Requieren acción
        requieren_accion = query.filter(
            Alerta.estado_alerta == "activa",
            Alerta.requiere_accion == True
        ).count()

        return AlertaStats(
            total_alertas=total_alertas,
            por_estado=por_estado,
            por_tipo=por_tipo,
            por_prioridad=por_prioridad,
            activas_criticas=activas_criticas,
            requieren_accion=requieren_accion
        )


class ConfiguracionAlertasService:
    """Service for configuracion alertas operations."""

    @staticmethod
    def get_configuracion_by_user(db: Session, user_id: int) -> Optional[ConfiguracionAlertas]:
        """Get configuracion alertas for a user."""
        return db.query(ConfiguracionAlertas).filter(
            ConfiguracionAlertas.user_id == user_id
        ).first()

    @staticmethod
    def create_configuracion(
        db: Session,
        configuracion: ConfiguracionAlertasCreate
    ) -> ConfiguracionAlertas:
        """Create configuracion alertas for a user."""
        # Check if configuracion already exists
        existing = ConfiguracionAlertasService.get_configuracion_by_user(db, configuracion.user_id)
        if existing:
            raise ValueError("Configuracion already exists for this user")

        db_config = ConfiguracionAlertas(
            **configuracion.model_dump(exclude_unset=True)
        )

        db.add(db_config)
        db.commit()
        db.refresh(db_config)
        return db_config

    @staticmethod
    def update_configuracion(
        db: Session,
        user_id: int,
        configuracion_update: ConfiguracionAlertasUpdate
    ) -> Optional[ConfiguracionAlertas]:
        """Update configuracion alertas for a user."""
        db_config = ConfiguracionAlertasService.get_configuracion_by_user(db, user_id)
        if not db_config:
            return None

        update_data = configuracion_update.model_dump(exclude_unset=True)
        for field, value in update_data.items():
            setattr(db_config, field, value)

        db_config.updated_at = datetime.now()
        db.commit()
        db.refresh(db_config)
        return db_config

    @staticmethod
    def get_or_create_configuracion(
        db: Session,
        user_id: int
    ) -> ConfiguracionAlertas:
        """Get or create default configuracion for a user."""
        config = ConfiguracionAlertasService.get_configuracion_by_user(db, user_id)

        if not config:
            # Create with defaults
            config_create = ConfiguracionAlertasCreate(user_id=user_id)
            config = ConfiguracionAlertasService.create_configuracion(db, config_create)

        return config
