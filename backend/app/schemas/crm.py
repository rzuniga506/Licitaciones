"""
Pydantic schemas for CRM models (Contacto, InteraccionCliente) validation.
"""
from pydantic import BaseModel, EmailStr, Field, field_validator
from typing import Optional, List
from datetime import datetime, date


class ContactoBase(BaseModel):
    """Base contacto schema with common fields."""

    cliente_id: int = Field(..., gt=0)
    nombre_contacto: str = Field(..., min_length=1, max_length=255)
    cargo: Optional[str] = Field(None, max_length=100)
    departamento: Optional[str] = Field(None, max_length=100)
    telefono: Optional[str] = Field(None, max_length=50)
    celular: Optional[str] = Field(None, max_length=50)
    email: Optional[EmailStr] = None
    extension: Optional[str] = Field(None, max_length=20)
    linkedin_url: Optional[str] = None
    es_contacto_principal: bool = False
    puede_firmar: bool = False
    nivel_decision: Optional[str] = None
    preferencia_contacto: Optional[str] = None
    mejor_horario_contacto: Optional[str] = Field(None, max_length=100)
    notas: Optional[str] = None

    @field_validator("nivel_decision")
    @classmethod
    def validate_nivel_decision(cls, v):
        if v is not None:
            allowed_levels = ["ejecutivo", "gerencial", "operativo", "tecnico"]
            if v not in allowed_levels:
                raise ValueError(f"Nivel decisión must be one of: {', '.join(allowed_levels)}")
        return v

    @field_validator("preferencia_contacto")
    @classmethod
    def validate_preferencia(cls, v):
        if v is not None:
            allowed_preferences = ["email", "telefono", "whatsapp", "presencial"]
            if v not in allowed_preferences:
                raise ValueError(f"Preferencia contacto must be one of: {', '.join(allowed_preferences)}")
        return v


class ContactoCreate(ContactoBase):
    """Schema for creating a new contacto."""
    pass


class ContactoUpdate(BaseModel):
    """Schema for updating a contacto."""

    nombre_contacto: Optional[str] = Field(None, min_length=1, max_length=255)
    cargo: Optional[str] = Field(None, max_length=100)
    departamento: Optional[str] = Field(None, max_length=100)
    telefono: Optional[str] = Field(None, max_length=50)
    celular: Optional[str] = Field(None, max_length=50)
    email: Optional[EmailStr] = None
    extension: Optional[str] = Field(None, max_length=20)
    linkedin_url: Optional[str] = None
    es_contacto_principal: Optional[bool] = None
    puede_firmar: Optional[bool] = None
    nivel_decision: Optional[str] = None
    preferencia_contacto: Optional[str] = None
    mejor_horario_contacto: Optional[str] = None
    notas: Optional[str] = None
    is_active: Optional[bool] = None


class ContactoInDB(ContactoBase):
    """Schema for contacto in database."""

    contacto_id: int
    is_active: bool
    is_deleted: bool
    created_at: datetime
    updated_at: Optional[datetime]
    created_by: Optional[int]

    class Config:
        from_attributes = True


class ContactoResponse(ContactoInDB):
    """Schema for contacto response."""
    pass


class ContactoList(BaseModel):
    """Schema for paginated contacto list."""

    total: int
    items: List[ContactoResponse]
    page: int
    page_size: int
    total_pages: int


# InteraccionCliente Schemas

class InteraccionClienteBase(BaseModel):
    """Base interaccion cliente schema with common fields."""

    cliente_id: int = Field(..., gt=0)
    contacto_id: Optional[int] = Field(None, gt=0)
    licitacion_id: Optional[int] = Field(None, gt=0)
    tipo_interaccion: str = Field(..., min_length=1, max_length=50)
    titulo: str = Field(..., min_length=1, max_length=255)
    descripcion: str = Field(..., min_length=1)
    fecha_interaccion: datetime
    duracion_minutos: Optional[int] = Field(None, ge=0)
    ubicacion: Optional[str] = Field(None, max_length=255)
    modalidad: Optional[str] = None
    resultado: Optional[str] = Field(None, max_length=100)
    nivel_interes: Optional[int] = Field(None, ge=1, le=5)
    requiere_seguimiento: bool = False
    fecha_proximo_seguimiento: Optional[date] = None
    accion_siguiente: Optional[str] = None
    responsable_seguimiento: Optional[int] = Field(None, gt=0)
    participantes: Optional[List[str]] = None
    asistentes_internos: Optional[List[str]] = None
    documentos_vinculados: Optional[List[int]] = None
    observaciones: Optional[str] = None
    puntos_clave: Optional[str] = None
    compromisos: Optional[str] = None

    @field_validator("tipo_interaccion")
    @classmethod
    def validate_tipo(cls, v):
        allowed_types = [
            "reunion", "llamada", "email", "visita", "presentacion",
            "cotizacion", "seguimiento", "otro"
        ]
        if v not in allowed_types:
            raise ValueError(f"Tipo interacción must be one of: {', '.join(allowed_types)}")
        return v

    @field_validator("modalidad")
    @classmethod
    def validate_modalidad(cls, v):
        if v is not None:
            allowed_modalities = ["presencial", "virtual", "telefonica", "hibrida"]
            if v not in allowed_modalities:
                raise ValueError(f"Modalidad must be one of: {', '.join(allowed_modalities)}")
        return v

    @field_validator("resultado")
    @classmethod
    def validate_resultado(cls, v):
        if v is not None:
            allowed_results = [
                "exitosa", "pendiente_seguimiento", "sin_interes",
                "requiere_propuesta", "cerrada", "otro"
            ]
            if v not in allowed_results:
                raise ValueError(f"Resultado must be one of: {', '.join(allowed_results)}")
        return v


class InteraccionClienteCreate(InteraccionClienteBase):
    """Schema for creating a new interaccion."""
    pass


class InteraccionClienteUpdate(BaseModel):
    """Schema for updating an interaccion."""

    contacto_id: Optional[int] = Field(None, gt=0)
    licitacion_id: Optional[int] = Field(None, gt=0)
    tipo_interaccion: Optional[str] = None
    titulo: Optional[str] = Field(None, min_length=1, max_length=255)
    descripcion: Optional[str] = None
    fecha_interaccion: Optional[datetime] = None
    duracion_minutos: Optional[int] = Field(None, ge=0)
    ubicacion: Optional[str] = None
    modalidad: Optional[str] = None
    resultado: Optional[str] = None
    nivel_interes: Optional[int] = Field(None, ge=1, le=5)
    requiere_seguimiento: Optional[bool] = None
    fecha_proximo_seguimiento: Optional[date] = None
    accion_siguiente: Optional[str] = None
    responsable_seguimiento: Optional[int] = None
    participantes: Optional[List[str]] = None
    asistentes_internos: Optional[List[str]] = None
    documentos_vinculados: Optional[List[int]] = None
    observaciones: Optional[str] = None
    puntos_clave: Optional[str] = None
    compromisos: Optional[str] = None


class InteraccionClienteInDB(InteraccionClienteBase):
    """Schema for interaccion in database."""

    interaccion_id: int
    is_active: bool
    is_deleted: bool
    created_at: datetime
    updated_at: Optional[datetime]
    created_by: Optional[int]

    class Config:
        from_attributes = True


class InteraccionClienteResponse(InteraccionClienteInDB):
    """Schema for interaccion response."""
    pass


class InteraccionClienteList(BaseModel):
    """Schema for paginated interaccion list."""

    total: int
    items: List[InteraccionClienteResponse]
    page: int
    page_size: int
    total_pages: int
