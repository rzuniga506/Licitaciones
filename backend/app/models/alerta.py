"""
Alerta models for managing alerts and notifications.
"""
from sqlalchemy import Column, Integer, String, Text, Boolean, DateTime, Time, ForeignKey
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship

from app.db.base import Base


class Alerta(Base):
    """Alerta model for system alerts and notifications."""

    __tablename__ = "alertas"

    alerta_id = Column(Integer, primary_key=True, index=True)

    # Alert type
    tipo_alerta = Column(String(50), nullable=False, index=True)
    # Tipos: documento_vencido, documento_por_vencer, contrato_proximo_fin,
    #        garantia_vencida, garantia_por_vencer, seguimiento_pendiente,
    #        licitacion_proxima, ampliacion_pendiente, interaccion_programada

    # References (can be NULL depending on type)
    licitacion_id = Column(Integer, ForeignKey("licitaciones.licitacion_id"))
    documento_id = Column(Integer, ForeignKey("documentos.documento_id"))
    ampliacion_id = Column(Integer, ForeignKey("ampliaciones.ampliacion_id"))
    cliente_id = Column(Integer, ForeignKey("clientes.cliente_id"))
    user_id = Column(Integer, ForeignKey("users.user_id"))  # Recipient (NULL = all)

    # Alert content
    titulo = Column(String(255), nullable=False)
    mensaje = Column(Text, nullable=False)

    # Priority
    nivel_prioridad = Column(String(20), default="media", index=True)
    # Niveles: baja, media, alta, critica

    # Status
    estado_alerta = Column(String(50), default="activa", index=True)
    # Estados: activa, leida, archivada, resuelta, descartada

    # Dates
    fecha_alerta = Column(DateTime(timezone=True), nullable=False, index=True)
    fecha_leida = Column(DateTime(timezone=True))
    fecha_resuelta = Column(DateTime(timezone=True))
    fecha_descartada = Column(DateTime(timezone=True))

    # Actions
    requiere_accion = Column(Boolean, default=False)
    url_accion = Column(Text)
    accion_sugerida = Column(String(255))

    # Notifications
    enviada_email = Column(Boolean, default=False)
    fecha_envio_email = Column(DateTime(timezone=True))
    email_destinatario = Column(String(255))

    # Recurrence
    es_recurrente = Column(Boolean, default=False)
    frecuencia_dias = Column(Integer)
    ultima_generacion = Column(DateTime(timezone=True))

    # User notes
    notas_usuario = Column(Text)

    # Audit fields
    is_active = Column(Boolean, default=True, nullable=False)
    is_deleted = Column(Boolean, default=False, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    created_by = Column(Integer, ForeignKey("users.user_id"))

    # Relationships
    usuario = relationship("User", foreign_keys=[user_id])
    creator = relationship("User", foreign_keys=[created_by])

    def __repr__(self):
        return f"<Alerta(alerta_id={self.alerta_id}, tipo={self.tipo_alerta})>"


class ConfiguracionAlertas(Base):
    """ConfiguracionAlertas model for user alert preferences."""

    __tablename__ = "configuracion_alertas"

    config_id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.user_id"), nullable=False, unique=True)

    # Alert activation by type
    alertas_documentos_vencidos = Column(Boolean, default=True)
    dias_alerta_documentos = Column(Integer, default=15)

    alertas_contratos_proximos = Column(Boolean, default=True)
    dias_alerta_contratos = Column(Integer, default=30)

    alertas_garantias = Column(Boolean, default=True)
    dias_alerta_garantias = Column(Integer, default=15)

    alertas_seguimientos = Column(Boolean, default=True)
    dias_alerta_seguimientos = Column(Integer, default=1)

    alertas_licitaciones = Column(Boolean, default=True)
    alertas_ampliaciones = Column(Boolean, default=True)

    # Notification channels
    notificar_email = Column(Boolean, default=True)
    notificar_push = Column(Boolean, default=False)
    notificar_sms = Column(Boolean, default=False)

    # Schedules (to avoid notifications outside business hours)
    horario_inicio = Column(Time, default="08:00:00")
    horario_fin = Column(Time, default="18:00:00")
    notificar_fines_semana = Column(Boolean, default=False)

    # Summary frequency
    enviar_resumen_diario = Column(Boolean, default=True)
    hora_resumen_diario = Column(Time, default="08:00:00")

    # Audit fields
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    # Relationships
    usuario = relationship("User")

    def __repr__(self):
        return f"<ConfiguracionAlertas(config_id={self.config_id}, user_id={self.user_id})>"
