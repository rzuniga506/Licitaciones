"""
Licitacion model for managing tender/bidding information.
"""
from sqlalchemy import Column, Integer, String, Text, Numeric, Date, DateTime, Boolean, ForeignKey
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from decimal import Decimal

from app.db.base import Base


class Licitacion(Base):
    """Licitacion/Tender model."""

    __tablename__ = "licitaciones"

    licitacion_id = Column(Integer, primary_key=True, index=True)
    numero_licitacion = Column(String(100), unique=True, nullable=False, index=True)

    # Relationships
    cliente_id = Column(Integer, ForeignKey("clientes.cliente_id"), nullable=False)

    # Basic information
    nombre_licitacion = Column(String(500), nullable=False)
    descripcion = Column(Text)
    objeto_contrato = Column(Text)

    # Amounts
    monto_ofertado = Column(Numeric(15, 2))
    monto_adjudicado = Column(Numeric(15, 2))
    moneda = Column(String(10), default="CRC")  # CRC, USD, EUR

    # Status
    estado_licitacion = Column(String(50), nullable=False, default="en_preparacion", index=True)
    # Estados: en_preparacion, presentada, en_evaluacion, adjudicada,
    #          en_ejecucion, finalizada, desierta, rechazada

    # Important dates
    fecha_publicacion = Column(Date)
    fecha_presentacion = Column(Date, index=True)
    fecha_apertura = Column(Date)
    fecha_adjudicacion = Column(Date)
    fecha_inicio_contrato = Column(Date)
    fecha_fin_contrato = Column(Date, index=True)

    # Additional information
    tipo_licitacion = Column(String(50))  # publica, privada, abreviada, internacional
    categoria = Column(String(100), index=True)  # servicios, obras, bienes, consultoria
    prioridad = Column(String(20), default="media")  # alta, media, baja

    # Links
    url_portal_compras = Column(Text)
    numero_expediente = Column(String(100))

    # Guarantees
    monto_garantia_participacion = Column(Numeric(15, 2))
    fecha_vence_garantia_participacion = Column(Date)
    monto_garantia_cumplimiento = Column(Numeric(15, 2))
    fecha_vence_garantia_cumplimiento = Column(Date)

    # Observations
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
    cliente = relationship("Cliente", back_populates="licitaciones")
    creator = relationship("User", foreign_keys=[created_by])
    updater = relationship("User", foreign_keys=[updated_by])
    documentos = relationship("Documento", back_populates="licitacion", lazy="dynamic")
    ampliaciones = relationship("Ampliacion", back_populates="licitacion", lazy="dynamic")
    prorrogas = relationship("Prorroga", back_populates="licitacion", lazy="dynamic")

    def __repr__(self):
        return f"<Licitacion(licitacion_id={self.licitacion_id}, numero={self.numero_licitacion})>"

    @property
    def is_vencida(self) -> bool:
        """Check if tender submission deadline has passed."""
        if self.fecha_presentacion:
            from datetime import date
            return self.fecha_presentacion < date.today()
        return False

    @property
    def dias_hasta_presentacion(self) -> int:
        """Calculate days until submission deadline."""
        if self.fecha_presentacion:
            from datetime import date
            delta = self.fecha_presentacion - date.today()
            return delta.days
        return 0
