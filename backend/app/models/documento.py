"""
Documento model for managing document information.
"""
from sqlalchemy import Column, Integer, String, Text, BigInteger, Date, Boolean, DateTime, ForeignKey, ARRAY
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from datetime import date

from app.db.base import Base


class Documento(Base):
    """Documento model."""

    __tablename__ = "documentos"

    documento_id = Column(Integer, primary_key=True, index=True)
    licitacion_id = Column(Integer, ForeignKey("licitaciones.licitacion_id"), index=True)

    # File information
    nombre_documento = Column(String(255), nullable=False)
    nombre_archivo_original = Column(String(255), nullable=False)
    nombre_archivo_almacenado = Column(String(255), nullable=False, unique=True, index=True)
    ruta_archivo = Column(Text, nullable=False)
    extension = Column(String(10), nullable=False)
    tamanio_bytes = Column(BigInteger, nullable=False)
    mime_type = Column(String(100))

    # Categorization
    tipo_documento = Column(String(100), nullable=False, index=True)
    # Tipos: oferta_tecnica, oferta_economica, pliego, garantia, certificacion, contrato, adenda, otro
    categoria_documento = Column(String(100))
    # Categorías: ccss, hacienda, ins, municipal, bancario, legal, tecnico

    # Version control
    version = Column(Integer, default=1)
    documento_padre_id = Column(Integer, ForeignKey("documentos.documento_id"))
    is_ultima_version = Column(Boolean, default=True)

    # Dates
    fecha_emision = Column(Date)
    fecha_vencimiento = Column(Date, index=True)
    dias_alerta_vencimiento = Column(Integer, default=15)

    # Status
    estado_documento = Column(String(50), default="activo", index=True)
    # Estados: activo, vencido, reemplazado, eliminado

    # Metadata
    descripcion = Column(Text)
    tags = Column(ARRAY(String))
    hash_archivo = Column(String(64))  # SHA256

    # Audit fields
    is_active = Column(Boolean, default=True, nullable=False)
    is_deleted = Column(Boolean, default=False, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    uploaded_by = Column(Integer, ForeignKey("users.user_id"))

    # Relationships
    licitacion = relationship("Licitacion", back_populates="documentos")
    uploader = relationship("User", foreign_keys=[uploaded_by])
    versiones_hijas = relationship("Documento", foreign_keys=[documento_padre_id], remote_side=[documento_id])

    def __repr__(self):
        return f"<Documento(documento_id={self.documento_id}, nombre={self.nombre_documento})>"

    @property
    def is_vencido(self) -> bool:
        """Check if document is expired."""
        if self.fecha_vencimiento:
            return self.fecha_vencimiento < date.today()
        return False

    @property
    def dias_hasta_vencimiento(self) -> int:
        """Calculate days until expiration."""
        if self.fecha_vencimiento:
            delta = self.fecha_vencimiento - date.today()
            return delta.days
        return 0
