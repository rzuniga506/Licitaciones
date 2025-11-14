"""
Pydantic schemas for Ampliacion and Prorroga model validation.
"""
from pydantic import BaseModel, Field, field_validator
from typing import Optional
from datetime import datetime, date
from decimal import Decimal


class AmpliacionBase(BaseModel):
    """Base ampliacion schema with common fields."""

    licitacion_id: int = Field(..., gt=0)
    tipo_ampliacion: str = Field(..., min_length=1, max_length=50)
    titulo: str = Field(..., min_length=1, max_length=255)
    descripcion: str = Field(..., min_length=1)
    justificacion: Optional[str] = None

    # Time changes
    fecha_anterior_fin: Optional[date] = None
    fecha_nueva_fin: Optional[date] = None
    dias_ampliados: Optional[int] = None

    # Amount changes
    monto_anterior: Optional[Decimal] = Field(None, ge=0)
    monto_nuevo: Optional[Decimal] = Field(None, ge=0)
    monto_ampliado: Optional[Decimal] = Field(None, ge=0)
    porcentaje_ampliacion: Optional[Decimal] = None

    # Process dates
    fecha_solicitud: date
    fecha_aprobacion: Optional[date] = None
    fecha_inicio_vigencia: Optional[date] = None
    fecha_fin_vigencia: Optional[date] = None

    # Legal references
    numero_ampliacion: Optional[str] = Field(None, max_length=50)
    numero_adenda: Optional[str] = Field(None, max_length=100)
    numero_resolucion: Optional[str] = Field(None, max_length=100)
    numero_oficio: Optional[str] = Field(None, max_length=100)

    # Responsible parties
    solicitante_nombre: Optional[str] = Field(None, max_length=255)
    solicitante_cargo: Optional[str] = Field(None, max_length=100)
    aprobador_nombre: Optional[str] = Field(None, max_length=255)
    aprobador_cargo: Optional[str] = Field(None, max_length=100)

    # Observations
    observaciones: Optional[str] = None
    motivo_rechazo: Optional[str] = None

    # Impact
    impacto_cronograma: bool = False
    impacto_presupuesto: bool = False
    impacto_alcance: bool = False

    @field_validator("tipo_ampliacion")
    @classmethod
    def validate_tipo(cls, v):
        allowed_types = [
            "ampliacion_plazo", "ampliacion_monto", "adenda",
            "suspension", "reanudacion", "modificacion_alcance"
        ]
        if v not in allowed_types:
            raise ValueError(f"Tipo must be one of: {', '.join(allowed_types)}")
        return v


class AmpliacionCreate(AmpliacionBase):
    """Schema for creating a new ampliacion."""
    pass


class AmpliacionUpdate(BaseModel):
    """Schema for updating an ampliacion."""

    titulo: Optional[str] = Field(None, min_length=1, max_length=255)
    descripcion: Optional[str] = None
    justificacion: Optional[str] = None
    fecha_nueva_fin: Optional[date] = None
    dias_ampliados: Optional[int] = None
    monto_nuevo: Optional[Decimal] = Field(None, ge=0)
    monto_ampliado: Optional[Decimal] = Field(None, ge=0)
    porcentaje_ampliacion: Optional[Decimal] = None
    fecha_aprobacion: Optional[date] = None
    fecha_inicio_vigencia: Optional[date] = None
    fecha_fin_vigencia: Optional[date] = None
    estado_ampliacion: Optional[str] = None
    numero_adenda: Optional[str] = None
    numero_resolucion: Optional[str] = None
    numero_oficio: Optional[str] = None
    observaciones: Optional[str] = None
    motivo_rechazo: Optional[str] = None

    @field_validator("estado_ampliacion")
    @classmethod
    def validate_estado(cls, v):
        if v is not None:
            allowed_states = [
                "pendiente", "en_revision", "aprobada", "rechazada", "aplicada", "anulada"
            ]
            if v not in allowed_states:
                raise ValueError(f"Estado must be one of: {', '.join(allowed_states)}")
        return v


class AmpliacionInDB(AmpliacionBase):
    """Schema for ampliacion in database."""

    ampliacion_id: int
    estado_ampliacion: str
    is_active: bool
    is_deleted: bool
    created_at: datetime
    updated_at: Optional[datetime]
    created_by: Optional[int]
    updated_by: Optional[int]

    class Config:
        from_attributes = True


class AmpliacionResponse(AmpliacionInDB):
    """Schema for ampliacion response."""
    pass


class AmpliacionList(BaseModel):
    """Schema for paginated ampliacion list."""

    total: int
    items: List[AmpliacionResponse]
    page: int
    page_size: int
    total_pages: int


# Prorroga Schemas

class ProrrogaBase(BaseModel):
    """Base prorroga schema with common fields."""

    licitacion_id: int = Field(..., gt=0)
    descripcion: str = Field(..., min_length=1)
    fecha_fin_anterior: date
    fecha_fin_nueva: date
    meses_prorrogados: Optional[int] = None
    dias_prorrogados: Optional[int] = None
    fecha_solicitud: date
    fecha_aprobacion: Optional[date] = None
    fecha_inicio_vigencia: Optional[date] = None
    numero_prorroga: Optional[str] = Field(None, max_length=50)
    numero_resolucion: Optional[str] = Field(None, max_length=100)
    numero_oficio: Optional[str] = Field(None, max_length=100)
    justificacion: Optional[str] = None
    observaciones: Optional[str] = None
    motivo_rechazo: Optional[str] = None


class ProrrogaCreate(ProrrogaBase):
    """Schema for creating a new prorroga."""
    pass


class ProrrogaUpdate(BaseModel):
    """Schema for updating a prorroga."""

    descripcion: Optional[str] = None
    fecha_fin_nueva: Optional[date] = None
    meses_prorrogados: Optional[int] = None
    dias_prorrogados: Optional[int] = None
    fecha_aprobacion: Optional[date] = None
    fecha_inicio_vigencia: Optional[date] = None
    estado_prorroga: Optional[str] = None
    numero_resolucion: Optional[str] = None
    numero_oficio: Optional[str] = None
    justificacion: Optional[str] = None
    observaciones: Optional[str] = None
    motivo_rechazo: Optional[str] = None

    @field_validator("estado_prorroga")
    @classmethod
    def validate_estado(cls, v):
        if v is not None:
            allowed_states = ["pendiente", "aprobada", "rechazada", "aplicada"]
            if v not in allowed_states:
                raise ValueError(f"Estado must be one of: {', '.join(allowed_states)}")
        return v


class ProrrogaInDB(ProrrogaBase):
    """Schema for prorroga in database."""

    prorroga_id: int
    estado_prorroga: str
    is_active: bool
    is_deleted: bool
    created_at: datetime
    updated_at: Optional[datetime]
    created_by: Optional[int]
    updated_by: Optional[int]

    class Config:
        from_attributes = True


class ProrrogaResponse(ProrrogaInDB):
    """Schema for prorroga response."""
    pass


class ProrrogaList(BaseModel):
    """Schema for paginated prorroga list."""

    total: int
    items: List[ProrrogaResponse]
    page: int
    page_size: int
    total_pages: int
