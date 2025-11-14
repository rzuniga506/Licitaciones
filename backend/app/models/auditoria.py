"""
Auditoria model for tracking system changes and user actions.
"""
from sqlalchemy import Column, Integer, String, Text, Boolean, DateTime, ForeignKey
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship

from app.db.base import Base


class Auditoria(Base):
    """Auditoria model for audit trail."""

    __tablename__ = "auditoria"

    auditoria_id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.user_id"), index=True)

    # Action information
    accion = Column(String(100), nullable=False, index=True)
    # Acciones: create, update, delete, login, logout, export, import, etc.

    tabla_afectada = Column(String(100), index=True)
    registro_id = Column(Integer)  # ID of the affected record

    # Change data
    datos_anteriores = Column(JSONB)  # Previous data
    datos_nuevos = Column(JSONB)  # New data

    # Request information
    ip_address = Column(String(50))
    user_agent = Column(Text)
    endpoint = Column(String(255))  # API endpoint called
    metodo_http = Column(String(10))  # GET, POST, PUT, DELETE

    # Result
    exitosa = Column(Boolean, default=True)
    codigo_respuesta = Column(Integer)  # HTTP response code
    mensaje_error = Column(Text)

    # Additional context
    descripcion = Column(Text)
    metadata = Column(JSONB)  # Additional metadata

    # Timestamp
    timestamp = Column(DateTime(timezone=True), server_default=func.now(), nullable=False, index=True)

    # Relationships
    usuario = relationship("User")

    def __repr__(self):
        return f"<Auditoria(auditoria_id={self.auditoria_id}, accion={self.accion})>"
