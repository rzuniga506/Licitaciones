"""
CRM models for managing contacts and client interactions.
"""
from sqlalchemy import Column, Integer, String, Text, Boolean, DateTime, Date, ForeignKey, ARRAY
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship

from app.db.base import Base


class Contacto(Base):
    """Contacto model for client contacts."""

    __tablename__ = "contactos"

    contacto_id = Column(Integer, primary_key=True, index=True)
    cliente_id = Column(Integer, ForeignKey("clientes.cliente_id"), nullable=False, index=True)

    # Personal information
    nombre_contacto = Column(String(255), nullable=False)
    cargo = Column(String(100))
    departamento = Column(String(100))

    # Contact information
    telefono = Column(String(50))
    celular = Column(String(50))
    email = Column(String(255))
    extension = Column(String(20))

    # Social networks
    linkedin_url = Column(Text)

    # Status
    es_contacto_principal = Column(Boolean, default=False)
    puede_firmar = Column(Boolean, default=False)
    nivel_decision = Column(String(50))  # ejecutivo, gerencial, operativo, tecnico

    # Preferences
    preferencia_contacto = Column(String(50))  # email, telefono, whatsapp, presencial
    mejor_horario_contacto = Column(String(100))

    # Notes
    notas = Column(Text)

    # Audit fields
    is_active = Column(Boolean, default=True, nullable=False)
    is_deleted = Column(Boolean, default=False, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    created_by = Column(Integer, ForeignKey("users.user_id"))

    # Relationships
    cliente = relationship("Cliente", back_populates="contactos")
    creator = relationship("User", foreign_keys=[created_by])
    interacciones = relationship("InteraccionCliente", back_populates="contacto", lazy="dynamic")

    def __repr__(self):
        return f"<Contacto(contacto_id={self.contacto_id}, nombre={self.nombre_contacto})>"


class InteraccionCliente(Base):
    """InteraccionCliente model for tracking client interactions."""

    __tablename__ = "interacciones_cliente"

    interaccion_id = Column(Integer, primary_key=True, index=True)
    cliente_id = Column(Integer, ForeignKey("clientes.cliente_id"), nullable=False, index=True)
    contacto_id = Column(Integer, ForeignKey("contactos.contacto_id"))
    licitacion_id = Column(Integer, ForeignKey("licitaciones.licitacion_id"))

    # Type of interaction
    tipo_interaccion = Column(String(50), nullable=False, index=True)
    # Tipos: reunion, llamada, email, visita, presentacion, cotizacion, seguimiento, otro

    # Details
    titulo = Column(String(255), nullable=False)
    descripcion = Column(Text, nullable=False)

    # Date and duration
    fecha_interaccion = Column(DateTime(timezone=True), nullable=False, index=True)
    duracion_minutos = Column(Integer)

    # Location (if applicable)
    ubicacion = Column(String(255))
    modalidad = Column(String(50))  # presencial, virtual, telefonica, hibrida

    # Result
    resultado = Column(String(100))
    # Resultados: exitosa, pendiente_seguimiento, sin_interes, requiere_propuesta, cerrada, otro
    nivel_interes = Column(Integer)  # 1-5

    # Follow-up
    requiere_seguimiento = Column(Boolean, default=False)
    fecha_proximo_seguimiento = Column(Date)
    accion_siguiente = Column(Text)
    responsable_seguimiento = Column(Integer, ForeignKey("users.user_id"))

    # Participants
    participantes = Column(ARRAY(String))  # Array of participant names
    asistentes_internos = Column(ARRAY(String))

    # Related documents
    documentos_vinculados = Column(ARRAY(Integer))

    # Observations
    observaciones = Column(Text)
    puntos_clave = Column(Text)
    compromisos = Column(Text)

    # Audit fields
    is_active = Column(Boolean, default=True, nullable=False)
    is_deleted = Column(Boolean, default=False, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    created_by = Column(Integer, ForeignKey("users.user_id"))

    # Relationships
    cliente = relationship("Cliente", back_populates="interacciones")
    contacto = relationship("Contacto", back_populates="interacciones")
    licitacion = relationship("Licitacion")
    creator = relationship("User", foreign_keys=[created_by])
    responsable = relationship("User", foreign_keys=[responsable_seguimiento])

    def __repr__(self):
        return f"<InteraccionCliente(interaccion_id={self.interaccion_id}, tipo={self.tipo_interaccion})>"
