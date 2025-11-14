"""
Pydantic schemas for Alerta models validation.
"""
from pydantic import BaseModel, Field, field_validator
from typing import Optional, List, Dict
from datetime import datetime, time


class AlertaBase(BaseModel):
    """Base alerta schema with common fields."""

    tipo_alerta: str = Field(..., min_length=1, max_length=50)
    titulo: str = Field(..., min_length=1, max_length=255)
    mensaje: str = Field(..., min_length=1)
    nivel_prioridad: str = Field(default="media")
    licitacion_id: Optional[int] = Field(None, gt=0)
    documento_id: Optional[int] = Field(None, gt=0)
    ampliacion_id: Optional[int] = Field(None, gt=0)
    cliente_id: Optional[int] = Field(None, gt=0)
    user_id: Optional[int] = Field(None, gt=0)
    requiere_accion: bool = False
    url_accion: Optional[str] = None
    accion_sugerida: Optional[str] = Field(None, max_length=255)
    es_recurrente: bool = False
    frecuencia_dias: Optional[int] = Field(None, gt=0)

    @field_validator("tipo_alerta")
    @classmethod
    def validate_tipo(cls, v):
        allowed_types = [
            "documento_vencido", "documento_por_vencer", "contrato_proximo_fin",
            "garantia_vencida", "garantia_por_vencer", "seguimiento_pendiente",
            "licitacion_proxima", "ampliacion_pendiente", "interaccion_programada"
        ]
        if v not in allowed_types:
            raise ValueError(f"Tipo alerta must be one of: {', '.join(allowed_types)}")
        return v

    @field_validator("nivel_prioridad")
    @classmethod
    def validate_prioridad(cls, v):
        allowed_priorities = ["baja", "media", "alta", "critica"]
        if v not in allowed_priorities:
            raise ValueError(f"Nivel prioridad must be one of: {', '.join(allowed_priorities)}")
        return v


class AlertaCreate(AlertaBase):
    """Schema for creating a new alerta."""
    pass


class AlertaUpdate(BaseModel):
    """Schema for updating an alerta."""

    estado_alerta: Optional[str] = None
    notas_usuario: Optional[str] = None
    fecha_leida: Optional[datetime] = None
    fecha_resuelta: Optional[datetime] = None
    fecha_descartada: Optional[datetime] = None

    @field_validator("estado_alerta")
    @classmethod
    def validate_estado(cls, v):
        if v is not None:
            allowed_states = ["activa", "leida", "archivada", "resuelta", "descartada"]
            if v not in allowed_states:
                raise ValueError(f"Estado must be one of: {', '.join(allowed_states)}")
        return v


class AlertaInDB(AlertaBase):
    """Schema for alerta in database."""

    alerta_id: int
    estado_alerta: str
    fecha_alerta: datetime
    fecha_leida: Optional[datetime]
    fecha_resuelta: Optional[datetime]
    fecha_descartada: Optional[datetime]
    enviada_email: bool
    fecha_envio_email: Optional[datetime]
    email_destinatario: Optional[str]
    ultima_generacion: Optional[datetime]
    notas_usuario: Optional[str]
    is_active: bool
    is_deleted: bool
    created_at: datetime
    created_by: Optional[int]

    class Config:
        from_attributes = True


class AlertaResponse(AlertaInDB):
    """Schema for alerta response."""
    pass


class AlertaList(BaseModel):
    """Schema for paginated alerta list."""

    total: int
    items: List[AlertaResponse]
    page: int
    page_size: int
    total_pages: int


class AlertaStats(BaseModel):
    """Schema for alerta statistics."""

    total_alertas: int
    por_estado: Dict[str, int]
    por_tipo: Dict[str, int]
    por_prioridad: Dict[str, int]
    activas_criticas: int
    requieren_accion: int


# ConfiguracionAlertas Schemas

class ConfiguracionAlertasBase(BaseModel):
    """Base configuracion alertas schema."""

    alertas_documentos_vencidos: bool = True
    dias_alerta_documentos: int = Field(default=15, ge=1, le=90)
    alertas_contratos_proximos: bool = True
    dias_alerta_contratos: int = Field(default=30, ge=1, le=180)
    alertas_garantias: bool = True
    dias_alerta_garantias: int = Field(default=15, ge=1, le=90)
    alertas_seguimientos: bool = True
    dias_alerta_seguimientos: int = Field(default=1, ge=0, le=30)
    alertas_licitaciones: bool = True
    alertas_ampliaciones: bool = True
    notificar_email: bool = True
    notificar_push: bool = False
    notificar_sms: bool = False
    horario_inicio: Optional[time] = None
    horario_fin: Optional[time] = None
    notificar_fines_semana: bool = False
    enviar_resumen_diario: bool = True
    hora_resumen_diario: Optional[time] = None


class ConfiguracionAlertasCreate(ConfiguracionAlertasBase):
    """Schema for creating configuracion alertas."""
    user_id: int = Field(..., gt=0)


class ConfiguracionAlertasUpdate(ConfiguracionAlertasBase):
    """Schema for updating configuracion alertas."""
    pass


class ConfiguracionAlertasInDB(ConfiguracionAlertasBase):
    """Schema for configuracion alertas in database."""

    config_id: int
    user_id: int
    updated_at: Optional[datetime]

    class Config:
        from_attributes = True


class ConfiguracionAlertasResponse(ConfiguracionAlertasInDB):
    """Schema for configuracion alertas response."""
    pass
