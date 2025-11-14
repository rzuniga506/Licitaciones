"""
Cliente model for managing client/institution information.
"""
from sqlalchemy import Column, Integer, String, Text, Boolean, DateTime, ForeignKey
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship

from app.db.base import Base


class Cliente(Base):
    """Cliente/Institution model."""

    __tablename__ = "clientes"

    cliente_id = Column(Integer, primary_key=True, index=True)
    nombre_cliente = Column(String(255), nullable=False, index=True)
    tipo_cliente = Column(String(50), nullable=False)  # publico, privado
    identificacion = Column(String(50), unique=True, index=True)
    telefono = Column(String(50))
    email = Column(String(255))
    direccion = Column(Text)
    contacto_principal = Column(String(255))
    notas = Column(Text)

    # Status
    is_active = Column(Boolean, default=True, nullable=False)
    is_deleted = Column(Boolean, default=False, nullable=False)

    # Audit fields
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    created_by = Column(Integer, ForeignKey("users.user_id"))

    # Relationships
    licitaciones = relationship("Licitacion", back_populates="cliente", lazy="dynamic")
    creator = relationship("User", foreign_keys=[created_by])
    contactos = relationship("Contacto", back_populates="cliente", lazy="dynamic")
    interacciones = relationship("InteraccionCliente", back_populates="cliente", lazy="dynamic")

    def __repr__(self):
        return f"<Cliente(cliente_id={self.cliente_id}, nombre={self.nombre_cliente})>"
