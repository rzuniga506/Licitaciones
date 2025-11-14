"""
Pydantic schemas for Documento model validation.
"""
from pydantic import BaseModel, Field, field_validator
from typing import Optional, List
from datetime import datetime, date


class DocumentoBase(BaseModel):
    """Base documento schema with common fields."""

    licitacion_id: int = Field(..., gt=0)
    nombre_documento: str = Field(..., min_length=1, max_length=255)
    tipo_documento: str = Field(..., min_length=1, max_length=100)
    categoria_documento: Optional[str] = Field(None, max_length=100)
    descripcion: Optional[str] = None
    fecha_emision: Optional[date] = None
    fecha_vencimiento: Optional[date] = None
    dias_alerta_vencimiento: int = Field(default=15, ge=1, le=90)
    tags: Optional[List[str]] = None

    @field_validator("tipo_documento")
    @classmethod
    def validate_tipo_documento(cls, v):
        allowed_types = [
            "oferta_tecnica", "oferta_economica", "pliego", "garantia",
            "certificacion", "contrato", "adenda", "otro"
        ]
        if v not in allowed_types:
            raise ValueError(f"Tipo de documento must be one of: {', '.join(allowed_types)}")
        return v


class DocumentoCreate(DocumentoBase):
    """Schema for creating a new documento (without file info)."""
    pass


class DocumentoUpdate(BaseModel):
    """Schema for updating a documento."""

    nombre_documento: Optional[str] = Field(None, min_length=1, max_length=255)
    tipo_documento: Optional[str] = Field(None, min_length=1, max_length=100)
    categoria_documento: Optional[str] = Field(None, max_length=100)
    descripcion: Optional[str] = None
    fecha_emision: Optional[date] = None
    fecha_vencimiento: Optional[date] = None
    dias_alerta_vencimiento: Optional[int] = Field(None, ge=1, le=90)
    tags: Optional[List[str]] = None
    estado_documento: Optional[str] = None

    @field_validator("tipo_documento")
    @classmethod
    def validate_tipo_documento(cls, v):
        if v is not None:
            allowed_types = [
                "oferta_tecnica", "oferta_economica", "pliego", "garantia",
                "certificacion", "contrato", "adenda", "otro"
            ]
            if v not in allowed_types:
                raise ValueError(f"Tipo de documento must be one of: {', '.join(allowed_types)}")
        return v

    @field_validator("estado_documento")
    @classmethod
    def validate_estado(cls, v):
        if v is not None:
            allowed_states = ["activo", "vencido", "reemplazado", "eliminado"]
            if v not in allowed_states:
                raise ValueError(f"Estado must be one of: {', '.join(allowed_states)}")
        return v


class DocumentoInDB(DocumentoBase):
    """Schema for documento in database."""

    documento_id: int
    nombre_archivo_original: str
    nombre_archivo_almacenado: str
    ruta_archivo: str
    extension: str
    tamanio_bytes: int
    mime_type: Optional[str]
    version: int
    documento_padre_id: Optional[int]
    is_ultima_version: bool
    estado_documento: str
    hash_archivo: Optional[str]
    is_active: bool
    is_deleted: bool
    created_at: datetime
    updated_at: Optional[datetime]
    uploaded_by: Optional[int]

    class Config:
        from_attributes = True


class DocumentoResponse(DocumentoInDB):
    """Schema for documento response."""

    # Computed fields
    is_vencido: Optional[bool] = None
    dias_hasta_vencimiento: Optional[int] = None


class DocumentoList(BaseModel):
    """Schema for paginated documento list."""

    total: int
    items: List[DocumentoResponse]
    page: int
    page_size: int
    total_pages: int


class DocumentoUpload(BaseModel):
    """Schema for documento upload metadata."""

    licitacion_id: int = Field(..., gt=0)
    nombre_documento: str = Field(..., min_length=1, max_length=255)
    tipo_documento: str
    categoria_documento: Optional[str] = None
    descripcion: Optional[str] = None
    fecha_emision: Optional[date] = None
    fecha_vencimiento: Optional[date] = None
    tags: Optional[List[str]] = None
