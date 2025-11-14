"""
Pydantic schemas for Cliente model validation.
"""
from pydantic import BaseModel, EmailStr, Field, field_validator
from typing import Optional
from datetime import datetime


class ClienteBase(BaseModel):
    """Base cliente schema with common fields."""

    nombre_cliente: str = Field(..., min_length=1, max_length=255)
    tipo_cliente: str = Field(..., pattern="^(publico|privado)$")
    identificacion: Optional[str] = Field(None, max_length=50)
    telefono: Optional[str] = Field(None, max_length=50)
    email: Optional[EmailStr] = None
    direccion: Optional[str] = None
    contacto_principal: Optional[str] = Field(None, max_length=255)
    notas: Optional[str] = None

    @field_validator("tipo_cliente")
    @classmethod
    def validate_tipo_cliente(cls, v):
        allowed_types = ["publico", "privado"]
        if v not in allowed_types:
            raise ValueError(f"Tipo de cliente must be one of: {', '.join(allowed_types)}")
        return v


class ClienteCreate(ClienteBase):
    """Schema for creating a new cliente."""
    pass


class ClienteUpdate(BaseModel):
    """Schema for updating a cliente."""

    nombre_cliente: Optional[str] = Field(None, min_length=1, max_length=255)
    tipo_cliente: Optional[str] = Field(None, pattern="^(publico|privado)$")
    identificacion: Optional[str] = Field(None, max_length=50)
    telefono: Optional[str] = Field(None, max_length=50)
    email: Optional[EmailStr] = None
    direccion: Optional[str] = None
    contacto_principal: Optional[str] = Field(None, max_length=255)
    notas: Optional[str] = None
    is_active: Optional[bool] = None

    @field_validator("tipo_cliente")
    @classmethod
    def validate_tipo_cliente(cls, v):
        if v is not None:
            allowed_types = ["publico", "privado"]
            if v not in allowed_types:
                raise ValueError(f"Tipo de cliente must be one of: {', '.join(allowed_types)}")
        return v


class ClienteInDB(ClienteBase):
    """Schema for cliente in database."""

    cliente_id: int
    is_active: bool
    is_deleted: bool
    created_at: datetime
    updated_at: Optional[datetime] = None
    created_by: Optional[int] = None

    class Config:
        from_attributes = True


class ClienteResponse(ClienteInDB):
    """Schema for cliente response."""
    pass


class ClienteList(BaseModel):
    """Schema for paginated cliente list."""

    total: int
    items: list[ClienteResponse]
    page: int
    page_size: int
    total_pages: int
