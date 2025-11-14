"""
Ampliacion and Prorroga models for managing contract modifications.
"""
from sqlalchemy import Column, Integer, String, Text, Numeric, Date, Boolean, DateTime, ForeignKey
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship

from app.db.base import Base


class Ampliacion(Base):
    """Ampliacion model for contract extensions and modifications."""

    __tablename__ = "ampliaciones"

    ampliacion_id = Column(Integer, primary_key=True, index=True)
    licitacion_id = Column(Integer, ForeignKey("licitaciones.licitacion_id"), nullable=False, index=True)

    # Type of modification
    tipo_ampliacion = Column(String(50), nullable=False, index=True)
    # Tipos: ampliacion_plazo, ampliacion_monto, adenda, suspension, reanudacion, modificacion_alcance

    # General information
    numero_ampliacion = Column(String(50))
    titulo = Column(String(255), nullable=False)
    descripcion = Column(Text, nullable=False)
    justificacion = Column(Text)

    # Time changes
    fecha_anterior_fin = Column(Date)
    fecha_nueva_fin = Column(Date)
    dias_ampliados = Column(Integer)

    # Amount changes
    monto_anterior = Column(Numeric(15, 2))
    monto_nuevo = Column(Numeric(15, 2))
    monto_ampliado = Column(Numeric(15, 2))
    porcentaje_ampliacion = Column(Numeric(5, 2))

    # Process dates
    fecha_solicitud = Column(Date, nullable=False, index=True)
    fecha_aprobacion = Column(Date)
    fecha_inicio_vigencia = Column(Date)
    fecha_fin_vigencia = Column(Date)

    # Process status
    estado_ampliacion = Column(String(50), default="pendiente", index=True)
    # Estados: pendiente, en_revision, aprobada, rechazada, aplicada, anulada

    # Legal references
    numero_adenda = Column(String(100))
    numero_resolucion = Column(String(100))
    numero_oficio = Column(String(100))

    # Responsible parties
    solicitante_nombre = Column(String(255))
    solicitante_cargo = Column(String(100))
    aprobador_nombre = Column(String(255))
    aprobador_cargo = Column(String(100))

    # Observations
    observaciones = Column(Text)
    motivo_rechazo = Column(Text)

    # Impact
    impacto_cronograma = Column(Boolean, default=False)
    impacto_presupuesto = Column(Boolean, default=False)
    impacto_alcance = Column(Boolean, default=False)

    # Audit fields
    is_active = Column(Boolean, default=True, nullable=False)
    is_deleted = Column(Boolean, default=False, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    created_by = Column(Integer, ForeignKey("users.user_id"))
    updated_by = Column(Integer, ForeignKey("users.user_id"))

    # Relationships
    licitacion = relationship("Licitacion", back_populates="ampliaciones")
    creator = relationship("User", foreign_keys=[created_by])
    updater = relationship("User", foreign_keys=[updated_by])

    def __repr__(self):
        return f"<Ampliacion(ampliacion_id={self.ampliacion_id}, tipo={self.tipo_ampliacion})>"


class Prorroga(Base):
    """Prorroga model for contract time extensions."""

    __tablename__ = "prorrogas"

    prorroga_id = Column(Integer, primary_key=True, index=True)
    licitacion_id = Column(Integer, ForeignKey("licitaciones.licitacion_id"), nullable=False, index=True)

    # Extension information
    numero_prorroga = Column(String(50))
    descripcion = Column(Text, nullable=False)

    # Dates
    fecha_fin_anterior = Column(Date, nullable=False)
    fecha_fin_nueva = Column(Date, nullable=False)
    meses_prorrogados = Column(Integer)
    dias_prorrogados = Column(Integer)

    # Process information
    fecha_solicitud = Column(Date, nullable=False)
    fecha_aprobacion = Column(Date)
    fecha_inicio_vigencia = Column(Date)

    # Status
    estado_prorroga = Column(String(50), default="pendiente", index=True)
    # Estados: pendiente, aprobada, rechazada, aplicada

    # Legal references
    numero_resolucion = Column(String(100))
    numero_oficio = Column(String(100))

    # Additional info
    justificacion = Column(Text)
    observaciones = Column(Text)
    motivo_rechazo = Column(Text)

    # Audit fields
    is_active = Column(Boolean, default=True, nullable=False)
    is_deleted = Column(Boolean, default=False, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    created_by = Column(Integer, ForeignKey("users.user_id"))
    updated_by = Column(Integer, ForeignKey("users.user_id"))

    # Relationships
    licitacion = relationship("Licitacion", back_populates="prorrogas")
    creator = relationship("User", foreign_keys=[created_by])
    updater = relationship("User", foreign_keys=[updated_by])

    def __repr__(self):
        return f"<Prorroga(prorroga_id={self.prorroga_id}, dias={self.dias_prorrogados})>"
