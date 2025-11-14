"""
Pydantic schemas for Licitacion model validation.
"""
from pydantic import BaseModel, Field, field_validator
from typing import Optional
from datetime import datetime, date
from decimal import Decimal


class LicitacionBase(BaseModel):
    """Base licitacion schema with common fields."""

    numero_licitacion: str = Field(..., min_length=1, max_length=100)
    cliente_id: int = Field(..., gt=0)
    nombre_licitacion: str = Field(..., min_length=1, max_length=500)
    descripcion: Optional[str] = None
    objeto_contrato: Optional[str] = None

    # Amounts
    monto_ofertado: Optional[Decimal] = Field(None, ge=0)
    monto_adjudicado: Optional[Decimal] = Field(None, ge=0)
    moneda: str = Field(default="CRC", pattern="^(CRC|USD|EUR)$")

    # Status
    estado_licitacion: str = Field(default="en_preparacion")

    # Important dates
    fecha_publicacion: Optional[date] = None
    fecha_presentacion: Optional[date] = None
    fecha_apertura: Optional[date] = None
    fecha_adjudicacion: Optional[date] = None
    fecha_inicio_contrato: Optional[date] = None
    fecha_fin_contrato: Optional[date] = None

    # Additional information
    tipo_licitacion: Optional[str] = None
    categoria: Optional[str] = None
    prioridad: str = Field(default="media", pattern="^(alta|media|baja)$")

    # Links
    url_portal_compras: Optional[str] = None
    numero_expediente: Optional[str] = Field(None, max_length=100)

    # Guarantees
    monto_garantia_participacion: Optional[Decimal] = Field(None, ge=0)
    fecha_vence_garantia_participacion: Optional[date] = None
    monto_garantia_cumplimiento: Optional[Decimal] = Field(None, ge=0)
    fecha_vence_garantia_cumplimiento: Optional[date] = None

    # Observations
    observaciones: Optional[str] = None
    motivo_rechazo: Optional[str] = None

    @field_validator("estado_licitacion")
    @classmethod
    def validate_estado(cls, v):
        allowed_states = [
            "en_preparacion", "presentada", "en_evaluacion", "adjudicada",
            "en_ejecucion", "finalizada", "desierta", "rechazada"
        ]
        if v not in allowed_states:
            raise ValueError(f"Estado must be one of: {', '.join(allowed_states)}")
        return v

    @field_validator("tipo_licitacion")
    @classmethod
    def validate_tipo(cls, v):
        if v is not None:
            allowed_types = ["publica", "privada", "abreviada", "internacional"]
            if v not in allowed_types:
                raise ValueError(f"Tipo must be one of: {', '.join(allowed_types)}")
        return v

    @field_validator("categoria")
    @classmethod
    def validate_categoria(cls, v):
        if v is not None:
            allowed_categories = ["servicios", "obras", "bienes", "consultoria"]
            if v not in allowed_categories:
                raise ValueError(f"Categoria must be one of: {', '.join(allowed_categories)}")
        return v

    @field_validator("prioridad")
    @classmethod
    def validate_prioridad(cls, v):
        allowed_priorities = ["alta", "media", "baja"]
        if v not in allowed_priorities:
            raise ValueError(f"Prioridad must be one of: {', '.join(allowed_priorities)}")
        return v


class LicitacionCreate(LicitacionBase):
    """Schema for creating a new licitacion."""
    pass


class LicitacionUpdate(BaseModel):
    """Schema for updating a licitacion."""

    numero_licitacion: Optional[str] = Field(None, min_length=1, max_length=100)
    cliente_id: Optional[int] = Field(None, gt=0)
    nombre_licitacion: Optional[str] = Field(None, min_length=1, max_length=500)
    descripcion: Optional[str] = None
    objeto_contrato: Optional[str] = None

    # Amounts
    monto_ofertado: Optional[Decimal] = Field(None, ge=0)
    monto_adjudicado: Optional[Decimal] = Field(None, ge=0)
    moneda: Optional[str] = Field(None, pattern="^(CRC|USD|EUR)$")

    # Status
    estado_licitacion: Optional[str] = None

    # Important dates
    fecha_publicacion: Optional[date] = None
    fecha_presentacion: Optional[date] = None
    fecha_apertura: Optional[date] = None
    fecha_adjudicacion: Optional[date] = None
    fecha_inicio_contrato: Optional[date] = None
    fecha_fin_contrato: Optional[date] = None

    # Additional information
    tipo_licitacion: Optional[str] = None
    categoria: Optional[str] = None
    prioridad: Optional[str] = Field(None, pattern="^(alta|media|baja)$")

    # Links
    url_portal_compras: Optional[str] = None
    numero_expediente: Optional[str] = Field(None, max_length=100)

    # Guarantees
    monto_garantia_participacion: Optional[Decimal] = Field(None, ge=0)
    fecha_vence_garantia_participacion: Optional[date] = None
    monto_garantia_cumplimiento: Optional[Decimal] = Field(None, ge=0)
    fecha_vence_garantia_cumplimiento: Optional[date] = None

    # Observations
    observaciones: Optional[str] = None
    motivo_rechazo: Optional[str] = None
    is_active: Optional[bool] = None

    @field_validator("estado_licitacion")
    @classmethod
    def validate_estado(cls, v):
        if v is not None:
            allowed_states = [
                "en_preparacion", "presentada", "en_evaluacion", "adjudicada",
                "en_ejecucion", "finalizada", "desierta", "rechazada"
            ]
            if v not in allowed_states:
                raise ValueError(f"Estado must be one of: {', '.join(allowed_states)}")
        return v

    @field_validator("tipo_licitacion")
    @classmethod
    def validate_tipo(cls, v):
        if v is not None:
            allowed_types = ["publica", "privada", "abreviada", "internacional"]
            if v not in allowed_types:
                raise ValueError(f"Tipo must be one of: {', '.join(allowed_types)}")
        return v

    @field_validator("categoria")
    @classmethod
    def validate_categoria(cls, v):
        if v is not None:
            allowed_categories = ["servicios", "obras", "bienes", "consultoria"]
            if v not in allowed_categories:
                raise ValueError(f"Categoria must be one of: {', '.join(allowed_categories)}")
        return v


class LicitacionInDB(LicitacionBase):
    """Schema for licitacion in database."""

    licitacion_id: int
    is_active: bool
    is_deleted: bool
    created_at: datetime
    updated_at: Optional[datetime] = None
    created_by: Optional[int] = None
    updated_by: Optional[int] = None

    class Config:
        from_attributes = True


class LicitacionResponse(LicitacionInDB):
    """Schema for licitacion response with computed fields."""

    # Optional: include cliente info
    # cliente: Optional[ClienteResponse] = None


class LicitacionList(BaseModel):
    """Schema for paginated licitacion list."""

    total: int
    items: list[LicitacionResponse]
    page: int
    page_size: int
    total_pages: int


class LicitacionStats(BaseModel):
    """Schema for licitacion statistics."""

    total_licitaciones: int
    por_estado: dict[str, int]
    por_categoria: dict[str, int]
    monto_total_ofertado: Decimal
    monto_total_adjudicado: Decimal
    tasa_exito: float  # porcentaje de adjudicadas
